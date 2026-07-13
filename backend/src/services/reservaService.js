const pool = require('../config/database');

const STATUS_BLOQUEANTES = ['PENDENTE', 'CONFIRMADA', 'EM_USO'];

async function listarDisponibilidade({ inicio, fim, tipo_ativo, categoria, unidade }) {
  const params = [inicio, fim];
  const where = [`a.status = 'DISPONIVEL'`];
  if (categoria === 'veiculos') {
    where.push(`a.tipo_ativo = 'VEICULO'`);
  } else if (categoria === 'maquinas') {
    where.push(`a.tipo_ativo IN ('MAQUINA_AGRICOLA','IMPLEMENTO')`);
  } else if (tipo_ativo) {
    params.push(tipo_ativo);
    where.push(`a.tipo_ativo = $${params.length}`);
  }
  if (unidade) {
    params.push(unidade);
    where.push(`a.unidade = $${params.length}`);
  }

  const sql = `
    SELECT a.*,
      EXISTS (
        SELECT 1 FROM reservas r
         WHERE r.ativo_id = a.id
           AND r.status = ANY($${params.length + 1})
           AND tstzrange(r.data_hora_inicio, r.data_hora_fim) &&
               tstzrange($1::timestamptz, $2::timestamptz)
      ) AS conflito
    FROM ativos a
    WHERE ${where.join(' AND ')}
    ORDER BY a.codigo_interno ASC
  `;
  const { rows } = await pool.query(sql, [...params, STATUS_BLOQUEANTES]);
  return rows.map((r) => ({ ...r, disponivel: !r.conflito }));
}

async function criarReservaTransacional({
  usuario_id, ativo_id, data_hora_inicio, data_hora_fim, motivo, observacoes,
}) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Bloqueia o ativo e recupera o responsavel
    const ativoRes = await client.query(
      `SELECT id, responsavel_id FROM ativos WHERE id = $1 FOR UPDATE`,
      [ativo_id]
    );
    if (ativoRes.rowCount === 0) {
      const e = new Error('Ativo nao encontrado'); e.code = 'VAL_001'; throw e;
    }
    const responsavelId = ativoRes.rows[0].responsavel_id;

    await client.query(
      `SELECT 1 FROM reservas
        WHERE ativo_id = $1
          AND status = ANY($2)
        FOR UPDATE`,
      [ativo_id, STATUS_BLOQUEANTES]
    );

    const overlap = await client.query(
      `SELECT id, data_hora_inicio, data_hora_fim, status
         FROM reservas
        WHERE ativo_id = $1
          AND status = ANY($2)
          AND tstzrange(data_hora_inicio, data_hora_fim) &&
              tstzrange($3::timestamptz, $4::timestamptz)`,
      [ativo_id, STATUS_BLOQUEANTES, data_hora_inicio, data_hora_fim]
    );

    if (overlap.rowCount > 0) {
      const e = new Error('Conflito de reserva');
      e.code = 'RES_001';
      e.details = overlap.rows;
      throw e;
    }

    // Se o ativo tem responsavel, a reserva fica PENDENTE (aguardando aprovacao).
    // Caso contrario, confirma direto (comportamento antigo).
    const statusInicial = responsavelId ? 'PENDENTE' : 'CONFIRMADA';
    const confirmadoExpr = responsavelId ? 'NULL' : 'NOW()';

    const ins = await client.query(
      `INSERT INTO reservas
         (usuario_id, ativo_id, data_hora_inicio, data_hora_fim,
          status, motivo, observacoes, confirmado_em)
       VALUES ($1, $2, $3, $4, $5, $6, $7, ${confirmadoExpr})
       RETURNING *`,
      [usuario_id, ativo_id, data_hora_inicio, data_hora_fim,
        statusInicial, motivo || null, observacoes || null]
    );

    await client.query('COMMIT');
    return { reserva: ins.rows[0], responsavel_id: responsavelId };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function obterReserva(id) {
  const { rows } = await pool.query(
    `SELECT r.*,
            a.codigo_interno, a.descricao AS ativo_descricao,
            a.tipo_ativo, a.placa, a.unidade, a.responsavel_id,
            u.nome_completo AS usuario_nome, u.email AS usuario_email
       FROM reservas r
       JOIN ativos a ON a.id = r.ativo_id
       JOIN usuarios u ON u.id = r.usuario_id
      WHERE r.id = $1`,
    [id]
  );
  return rows[0] || null;
}

async function listarReservas({ usuario_id, status, limit, offset }) {
  const params = [];
  const where = [];
  if (usuario_id) { params.push(usuario_id); where.push(`r.usuario_id = $${params.length}`); }
  if (status) { params.push(status); where.push(`r.status = $${params.length}`); }

  const lim = Math.min(Number(limit) || 50, 200);
  const off = Math.max(Number(offset) || 0, 0);

  const sql = `
    SELECT r.*,
           a.codigo_interno, a.descricao AS ativo_descricao,
           a.tipo_ativo, a.placa, a.responsavel_id,
           u.nome_completo AS usuario_nome
      FROM reservas r
      JOIN ativos a ON a.id = r.ativo_id
      JOIN usuarios u ON u.id = r.usuario_id
     ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
     ORDER BY r.data_hora_inicio DESC
     LIMIT ${lim} OFFSET ${off}
  `;
  const { rows } = await pool.query(sql, params);
  return rows;
}

/**
 * Lista reservas PENDENTES aguardando aprovacao.
 * - responsavel_id definido: apenas reservas de ativos sob responsabilidade do usuario.
 * - todos = true (admin/gerente): todas as reservas pendentes com responsavel.
 */
async function listarAprovacoesPendentes({ responsavel_id, todos }) {
  const params = [];
  const where = [`r.status = 'PENDENTE'`];
  if (todos) {
    where.push(`a.responsavel_id IS NOT NULL`);
  } else {
    params.push(responsavel_id);
    where.push(`a.responsavel_id = $${params.length}`);
  }

  const sql = `
    SELECT r.*,
           a.codigo_interno, a.descricao AS ativo_descricao,
           a.tipo_ativo, a.placa, a.unidade, a.responsavel_id,
           u.nome_completo AS usuario_nome, u.email AS usuario_email
      FROM reservas r
      JOIN ativos a ON a.id = r.ativo_id
      JOIN usuarios u ON u.id = r.usuario_id
     WHERE ${where.join(' AND ')}
     ORDER BY r.criado_em DESC
  `;
  const { rows } = await pool.query(sql, params);
  return rows;
}

async function atualizarStatus(id, novoStatus, camposExtras = {}) {
  const sets = [`status = $1`, `atualizado_em = NOW()`];
  const params = [novoStatus];
  if (camposExtras.confirmado_em) { params.push(camposExtras.confirmado_em); sets.push(`confirmado_em = $${params.length}`); }
  if (camposExtras.cancelado_em) { params.push(camposExtras.cancelado_em); sets.push(`cancelado_em = $${params.length}`); }
  params.push(id);
  const { rows } = await pool.query(
    `UPDATE reservas SET ${sets.join(', ')} WHERE id = $${params.length} RETURNING *`,
    params
  );
  return rows[0];
}

async function aprovarReserva(id, aprovadorId) {
  const { rows } = await pool.query(
    `UPDATE reservas
        SET status = 'CONFIRMADA', aprovado_por = $2, aprovado_em = NOW(),
            confirmado_em = NOW(), atualizado_em = NOW()
      WHERE id = $1
      RETURNING *`,
    [id, aprovadorId]
  );
  return rows[0];
}

async function rejeitarReserva(id, aprovadorId, motivo) {
  const { rows } = await pool.query(
    `UPDATE reservas
        SET status = 'REJEITADA', rejeitado_por = $2, rejeitado_em = NOW(),
            motivo_rejeicao = $3, atualizado_em = NOW()
      WHERE id = $1
      RETURNING *`,
    [id, aprovadorId, motivo || null]
  );
  return rows[0];
}

module.exports = {
  listarDisponibilidade,
  criarReservaTransacional,
  obterReserva,
  listarReservas,
  listarAprovacoesPendentes,
  atualizarStatus,
  aprovarReserva,
  rejeitarReserva,
  STATUS_BLOQUEANTES,
};
