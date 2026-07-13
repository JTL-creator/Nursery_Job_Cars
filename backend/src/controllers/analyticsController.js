const pool = require('../config/database');

async function resumo(req, res, next) {
  try {
    const q = (sql, p = []) => pool.query(sql, p).then(r => r.rows[0]);
    const today = `(NOW()::date)`;

    const [ativos, reservas, chk, users] = await Promise.all([
      q(`SELECT
           COUNT(*)::int AS total,
           COUNT(*) FILTER (WHERE status='DISPONIVEL')::int AS disponiveis,
           COUNT(*) FILTER (WHERE status='RESERVADO')::int AS reservados,
           COUNT(*) FILTER (WHERE status='MANUTENCAO')::int AS manutencao,
           COUNT(*) FILTER (WHERE status='INDISPONIVEL')::int AS indisponiveis
         FROM ativos`),
      q(`SELECT
           COUNT(*)::int AS total,
           COUNT(*) FILTER (WHERE status IN ('CONFIRMADA','EM_USO'))::int AS ativas,
           COUNT(*) FILTER (WHERE criado_em::date = ${today})::int AS hoje
         FROM reservas`),
      q(`SELECT
           COUNT(*)::int AS total,
           COUNT(*) FILTER (WHERE data_hora_evento::date = ${today})::int AS hoje
         FROM checklists`),
      q(`SELECT COUNT(*)::int AS total_ativos FROM usuarios WHERE status='ATIVO'`),
    ]);

    res.json({
      data: { ativos, reservas, checklists: chk, usuarios: users },
    });
  } catch (e) { next(e); }
}

async function usoPorAtivo(req, res, next) {
  try {
    const { rows } = await pool.query(
      `SELECT a.id, a.codigo_interno, a.descricao, a.tipo_ativo,
              COUNT(r.id)::int AS total_reservas,
              COUNT(r.id) FILTER (WHERE r.status='CONCLUIDA')::int AS concluidas
         FROM ativos a
         LEFT JOIN reservas r ON r.ativo_id = a.id
        GROUP BY a.id
        ORDER BY total_reservas DESC
        LIMIT 10`
    );
    res.json({ data: rows });
  } catch (e) { next(e); }
}

async function ocorrencias(req, res, next) {
  try {
    res.json({ data: [], message: 'Modulo de ocorrencias planejado para Sprint 5' });
  } catch (e) { next(e); }
}

module.exports = { resumo, usoPorAtivo, ocorrencias };
