const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const pool = require('../config/database');
const mailService = require('./mailService');
const emailTemplate = require('../utils/emailTemplate');

/**
 * Gera uma senha temporaria aleatoria e legivel (sem caracteres ambiguos).
 */
function gerarSenhaTemporaria(tamanho = 10) {
  const alfabeto = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  const bytes = crypto.randomBytes(tamanho);
  let senha = '';
  for (let i = 0; i < tamanho; i += 1) {
    senha += alfabeto[bytes[i] % alfabeto.length];
  }
  return senha;
}

async function criarSolicitacao(payload) {
  const { nome_completo, matricula, email, telefone, unidade_lotacao, justificativa } = payload;
  const { rows } = await pool.query(
    `INSERT INTO solicitacoes_cadastro
       (nome_completo, matricula, email, telefone, unidade_lotacao, justificativa)
     VALUES ($1,$2,$3,$4,$5,$6)
     RETURNING *`,
    [nome_completo, matricula, email, telefone, unidade_lotacao, justificativa]
  );
  return rows[0];
}

async function listarSolicitacoes(filtros = {}) {
  const where = [];
  const params = [];
  if (filtros.status) {
    params.push(filtros.status);
    where.push(`status = $${params.length}`);
  }
  const sql = `
    SELECT * FROM solicitacoes_cadastro
    ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
    ORDER BY criado_em DESC
    LIMIT 200
  `;
  const { rows } = await pool.query(sql, params);
  return rows;
}

async function aprovarSolicitacao(id, adminId) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows: sRows } = await client.query(
      'SELECT * FROM solicitacoes_cadastro WHERE id = $1 FOR UPDATE',
      [id]
    );
    if (sRows.length === 0) {
      const e = new Error('Solicitação não encontrada'); e.code = 'VAL_001'; throw e;
    }
    const s = sRows[0];
    if (s.status !== 'PENDENTE') {
      const e = new Error('Solicitação já analisada'); e.code = 'VAL_002'; throw e;
    }

    // Cria usuário com senha temporária aleatória (forte).
    const senhaPlana = gerarSenhaTemporaria();
    const senhaTemp = await bcrypt.hash(senhaPlana, 10);
    const { rows: pRows } = await client.query(
      "SELECT id FROM perfis WHERE nome = 'USUARIO' LIMIT 1"
    );
    const perfilId = pRows[0].id;

    await client.query(
      `INSERT INTO usuarios
         (nome_completo, matricula, email, telefone, unidade_lotacao,
          senha_hash, perfil_id, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,'ATIVO')`,
      [s.nome_completo, s.matricula, s.email, s.telefone,
      s.unidade_lotacao, senhaTemp, perfilId]
    );

    await client.query(
      `UPDATE solicitacoes_cadastro
          SET status='APROVADA', analisado_por=$1, analisado_em=NOW(), atualizado_em=NOW()
        WHERE id=$2`,
      [adminId, id]
    );

    await client.query('COMMIT');

    // Envia a senha temporária por e-mail (fora da transação; não bloqueia).
    let emailEnviado = false;
    try {
      const html = emailTemplate.email({
        titulo: 'Acesso liberado - GDM Job Cars',
        mensagem:
          `Olá, ${s.nome_completo}! Seu cadastro foi aprovado. ` +
          'Use a senha temporária abaixo para o primeiro acesso e altere-a em seguida.',
        detalhes: [
          ['E-mail', s.email],
          ['Senha temporária', senhaPlana],
        ],
        selo: 'Cadastro aprovado',
      });
      const r = await mailService.enviar({
        para: s.email,
        assunto: 'GDM Job Cars - Acesso liberado',
        texto:
          `Cadastro aprovado.\nE-mail: ${s.email}\n` +
          `Senha temporária: ${senhaPlana}\n` +
          'Altere sua senha após o primeiro acesso.',
        html,
      });
      emailEnviado = r.enviado === true;
    } catch (_) {
      emailEnviado = false;
    }

    return {
      ok: true,
      email_enviado: emailEnviado,
      // Retornada para o admin repassar caso o e-mail não seja enviado.
      senha_temporaria: senhaPlana,
    };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function rejeitarSolicitacao(id, adminId, observacao) {
  const { rowCount } = await pool.query(
    `UPDATE solicitacoes_cadastro
        SET status='REJEITADA',
            analisado_por=$1,
            analisado_em=NOW(),
            observacao_rejeicao=$2,
            atualizado_em=NOW()
      WHERE id=$3 AND status='PENDENTE'`,
    [adminId, observacao, id]
  );
  if (rowCount === 0) {
    const e = new Error('Solicitação inexistente ou já analisada'); e.code = 'VAL_002'; throw e;
  }
  return { ok: true };
}

module.exports = {
  criarSolicitacao,
  listarSolicitacoes,
  aprovarSolicitacao,
  rejeitarSolicitacao,
};
