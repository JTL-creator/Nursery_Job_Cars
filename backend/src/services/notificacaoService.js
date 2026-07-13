const pool = require('../config/database');

/**
 * Cria uma notificacao in-app para um usuario.
 */
async function criar({ usuario_id, tipo, titulo, mensagem, entidade, entidade_id }) {
    const { rows } = await pool.query(
        `INSERT INTO notificacoes
       (usuario_id, tipo, titulo, mensagem, entidade, entidade_id)
     VALUES ($1,$2,$3,$4,$5,$6)
     RETURNING *`,
        [usuario_id, tipo, titulo, mensagem || null, entidade || null, entidade_id || null]
    );
    return rows[0];
}

/**
 * Lista as notificacoes de um usuario (mais recentes primeiro).
 */
async function listar({ usuario_id, apenasNaoLidas, limit, offset }) {
    const params = [usuario_id];
    const where = ['usuario_id = $1'];
    if (apenasNaoLidas) {
        where.push('lida = FALSE');
    }
    const lim = Math.min(Number(limit) || 50, 200);
    const off = Math.max(Number(offset) || 0, 0);

    const { rows } = await pool.query(
        `SELECT * FROM notificacoes
      WHERE ${where.join(' AND ')}
      ORDER BY criado_em DESC
      LIMIT ${lim} OFFSET ${off}`,
        params
    );
    return rows;
}

async function contarNaoLidas(usuario_id) {
    const { rows } = await pool.query(
        `SELECT COUNT(*)::int AS total
       FROM notificacoes
      WHERE usuario_id = $1 AND lida = FALSE`,
        [usuario_id]
    );
    return rows[0].total;
}

async function marcarLida(id, usuario_id) {
    const { rows } = await pool.query(
        `UPDATE notificacoes SET lida = TRUE
      WHERE id = $1 AND usuario_id = $2
      RETURNING *`,
        [id, usuario_id]
    );
    return rows[0] || null;
}

async function marcarTodasLidas(usuario_id) {
    await pool.query(
        `UPDATE notificacoes SET lida = TRUE
      WHERE usuario_id = $1 AND lida = FALSE`,
        [usuario_id]
    );
}

module.exports = {
    criar, listar, contarNaoLidas, marcarLida, marcarTodasLidas,
};
