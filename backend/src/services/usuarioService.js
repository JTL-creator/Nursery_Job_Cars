const bcrypt = require('bcryptjs');
const pool = require('../config/database');

const PERFIS_VALIDOS = ['USUARIO', 'ADMINISTRADOR', 'GERENTE', 'RESPONSAVEL', 'VIGILANTE'];
const STATUS_VALIDOS = ['ATIVO', 'INATIVO', 'BLOQUEADO'];

async function listar(filtros = {}) {
    const params = [];
    const where = [];
    if (filtros.perfil) {
        params.push(filtros.perfil);
        where.push(`p.nome = $${params.length}`);
    }
    if (filtros.status) {
        params.push(filtros.status);
        where.push(`u.status = $${params.length}`);
    }
    if (filtros.q) {
        params.push(`%${filtros.q}%`);
        where.push(`(u.nome_completo ILIKE $${params.length} OR u.email ILIKE $${params.length} OR u.matricula ILIKE $${params.length})`);
    }
    const sql = `
    SELECT u.id, u.nome_completo, u.matricula, u.email,
           u.telefone, u.unidade_lotacao, u.status, u.ultimo_login_em,
           p.nome AS perfil
      FROM usuarios u
      JOIN perfis p ON p.id = u.perfil_id
     ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
     ORDER BY u.nome_completo ASC
     LIMIT 500`;
    const { rows } = await pool.query(sql, params);
    return rows;
}

async function obter(id) {
    const { rows } = await pool.query(
        `SELECT u.id, u.nome_completo, u.matricula, u.email, u.telefone,
            u.unidade_lotacao, u.status, u.ultimo_login_em, p.nome AS perfil
       FROM usuarios u
       JOIN perfis p ON p.id = u.perfil_id
      WHERE u.id = $1`,
        [id]
    );
    return rows[0] || null;
}

async function perfilId(nome) {
    const { rows } = await pool.query('SELECT id FROM perfis WHERE nome = $1 LIMIT 1', [nome]);
    if (rows.length === 0) {
        const e = new Error('Perfil invalido'); e.code = 'VAL_001'; throw e;
    }
    return rows[0].id;
}

async function criar(p) {
    const perfil = p.perfil && PERFIS_VALIDOS.includes(p.perfil) ? p.perfil : 'USUARIO';
    const pid = await perfilId(perfil);
    // Senha inicial: informada ou a propria matricula
    const senha = p.senha && p.senha.length >= 6 ? p.senha : p.matricula;
    const senhaHash = await bcrypt.hash(senha, 10);
    try {
        const { rows } = await pool.query(
            `INSERT INTO usuarios
         (nome_completo, matricula, email, telefone, unidade_lotacao,
          senha_hash, perfil_id, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7, COALESCE($8,'ATIVO'))
       RETURNING id`,
            [p.nome_completo, p.matricula, p.email, p.telefone || null,
            p.unidade_lotacao || null, senhaHash, pid, p.status || null]
        );
        return obter(rows[0].id);
    } catch (e) {
        if (e.code === '23505') {
            const err = new Error('Matricula ou email ja cadastrado'); err.code = 'VAL_002'; throw err;
        }
        throw e;
    }
}

async function atualizar(id, p) {
    const sets = [];
    const params = [];
    const campos = ['nome_completo', 'matricula', 'email', 'telefone', 'unidade_lotacao'];
    for (const c of campos) {
        if (p[c] !== undefined) {
            params.push(p[c] === '' ? null : p[c]);
            sets.push(`${c} = $${params.length}`);
        }
    }
    if (p.perfil !== undefined) {
        const pid = await perfilId(p.perfil);
        params.push(pid);
        sets.push(`perfil_id = $${params.length}`);
    }
    if (sets.length === 0) return obter(id);
    params.push(id);
    try {
        await pool.query(
            `UPDATE usuarios SET ${sets.join(', ')}, atualizado_em=NOW() WHERE id = $${params.length}`,
            params
        );
    } catch (e) {
        if (e.code === '23505') {
            const err = new Error('Matricula ou email ja cadastrado'); err.code = 'VAL_002'; throw err;
        }
        throw e;
    }
    return obter(id);
}

async function alterarStatus(id, status) {
    if (!STATUS_VALIDOS.includes(status)) {
        const e = new Error('Status invalido'); e.code = 'VAL_001'; throw e;
    }
    await pool.query(
        'UPDATE usuarios SET status=$1, atualizado_em=NOW() WHERE id=$2',
        [status, id]
    );
    return obter(id);
}

async function redefinirSenha(id, novaSenha) {
    // Se nao informada, reseta para a matricula do usuario
    let senha = novaSenha;
    if (!senha || senha.length < 6) {
        const { rows } = await pool.query('SELECT matricula FROM usuarios WHERE id=$1', [id]);
        if (rows.length === 0) { const e = new Error('Usuario nao encontrado'); e.code = 'VAL_001'; throw e; }
        senha = rows[0].matricula;
    }
    const senhaHash = await bcrypt.hash(senha, 10);
    await pool.query(
        'UPDATE usuarios SET senha_hash=$1, atualizado_em=NOW() WHERE id=$2',
        [senhaHash, id]
    );
    return { ok: true };
}

async function listarPerfis() {
    const { rows } = await pool.query(
        'SELECT id, nome, descricao FROM perfis WHERE ativo = TRUE ORDER BY nome ASC'
    );
    return rows;
}

module.exports = {
    listar, obter, criar, atualizar, alterarStatus, redefinirSenha, listarPerfis,
};
