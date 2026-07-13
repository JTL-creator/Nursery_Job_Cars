const pool = require('../config/database');

async function listar(filtros = {}) {
  const where = [];
  const params = [];

  if (filtros.categoria === 'veiculos') {
    where.push(`a.tipo_ativo = 'VEICULO'`);
  } else if (filtros.categoria === 'maquinas') {
    where.push(`a.tipo_ativo IN ('MAQUINA_AGRICOLA','IMPLEMENTO')`);
  } else if (filtros.tipo_ativo) {
    params.push(filtros.tipo_ativo);
    where.push(`a.tipo_ativo = $${params.length}`);
  }
  if (filtros.status) {
    params.push(filtros.status);
    where.push(`a.status = $${params.length}`);
  }
  if (filtros.unidade) {
    params.push(filtros.unidade);
    where.push(`a.unidade = $${params.length}`);
  }
  if (filtros.responsavel_id) {
    params.push(filtros.responsavel_id);
    where.push(`a.responsavel_id = $${params.length}`);
  }
  if (filtros.equipe) {
    params.push(filtros.equipe);
    where.push(`a.equipe = $${params.length}`);
  }
  if (filtros.q) {
    params.push(`%${filtros.q}%`);
    where.push(`(a.codigo_interno ILIKE $${params.length} OR a.descricao ILIKE $${params.length} OR a.placa ILIKE $${params.length})`);
  }

  const limit = Math.min(Number(filtros.limit) || 50, 200);
  const offset = Math.max(Number(filtros.offset) || 0, 0);

  const whereSql = where.length ? 'WHERE ' + where.join(' AND ') : '';
  const sqlCount = `SELECT COUNT(*)::int AS total FROM ativos a ${whereSql}`;
  const sqlData = `
    SELECT a.*, u.nome_completo AS responsavel_nome
    FROM ativos a
    LEFT JOIN usuarios u ON u.id = a.responsavel_id
    ${whereSql}
    ORDER BY a.codigo_interno ASC
    LIMIT ${limit} OFFSET ${offset}
  `;

  const [countR, dataR] = await Promise.all([
    pool.query(sqlCount, params),
    pool.query(sqlData, params),
  ]);

  return { rows: dataR.rows, total: countR.rows[0].total };
}

async function obter(id) {
  const { rows } = await pool.query(
    `SELECT a.*, u.nome_completo AS responsavel_nome
       FROM ativos a
       LEFT JOIN usuarios u ON u.id = a.responsavel_id
      WHERE a.id = $1`,
    [id]
  );
  return rows[0] || null;
}

async function criar(p) {
  const { rows } = await pool.query(
    `INSERT INTO ativos
       (codigo_interno, descricao, tipo_ativo, sub_tipo, placa,
        patrimonio, unidade, status, observacoes, responsavel_id, equipe, foto_url)
     VALUES ($1,$2,$3,$4,$5,$6,$7, COALESCE($8,'DISPONIVEL'), $9, $10, $11, $12)
     RETURNING *`,
    [
      p.codigo_interno, p.descricao, p.tipo_ativo, p.sub_tipo || null,
      p.placa || null, p.patrimonio || null, p.unidade || null,
      p.status || null, p.observacoes || null, p.responsavel_id || null,
      p.equipe || null, p.foto_url || null,
    ]
  );
  return rows[0];
}

async function atualizar(id, p) {
  const sets = [];
  const params = [];
  const campos = ['codigo_interno', 'descricao', 'tipo_ativo', 'sub_tipo',
    'placa', 'patrimonio', 'unidade', 'observacoes', 'responsavel_id',
    'equipe', 'foto_url'];
  for (const c of campos) {
    if (p[c] !== undefined) {
      params.push(p[c] === '' ? null : p[c]);
      sets.push(`${c} = $${params.length}`);
    }
  }
  if (sets.length === 0) {
    const { rows } = await pool.query('SELECT * FROM ativos WHERE id=$1', [id]);
    return rows[0];
  }
  params.push(id);
  const { rows } = await pool.query(
    `UPDATE ativos SET ${sets.join(', ')}, atualizado_em=NOW()
     WHERE id = $${params.length} RETURNING *`,
    params
  );
  return rows[0];
}

async function atualizarStatus(id, status) {
  const { rows } = await pool.query(
    `UPDATE ativos SET status=$1, atualizado_em=NOW() WHERE id=$2 RETURNING *`,
    [status, id]
  );
  return rows[0];
}

module.exports = { listar, obter, criar, atualizar, atualizarStatus };
