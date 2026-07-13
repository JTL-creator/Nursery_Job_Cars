/**
 * Auditoria — registra eventos relevantes.
 * Pode ser usado como middleware ou função direta.
 */
const pool = require('../config/database');
const logger = require('../utils/logger');

async function registrarEvento({
  usuario_id = null,
  entidade,
  entidade_id = null,
  acao,
  antes = null,
  depois = null,
  ip = null,
  user_agent = null,
}) {
  try {
    await pool.query(
      `INSERT INTO auditoria_eventos
        (usuario_id, entidade, entidade_id, acao, antes_json, depois_json, ip_origem, user_agent)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
      [usuario_id, entidade, entidade_id, acao,
       antes ? JSON.stringify(antes) : null,
       depois ? JSON.stringify(depois) : null,
       ip, user_agent]
    );
  } catch (e) {
    logger.warn('Falha ao gravar auditoria', { message: e.message });
  }
}

module.exports = { registrarEvento };
