const pool = require('../config/database');

async function obterTemplateAtivo(tipo_ativo, etapa) {
  const { rows } = await pool.query(
    `SELECT * FROM checklist_templates
      WHERE tipo_ativo = $1 AND etapa = $2 AND ativo = TRUE
      ORDER BY versao DESC
      LIMIT 1`,
    [tipo_ativo, etapa]
  );
  if (rows.length === 0) return null;
  const tpl = rows[0];

  const { rows: itens } = await pool.query(
    `SELECT * FROM checklist_template_itens
      WHERE template_id = $1
      ORDER BY ordem ASC, descricao ASC`,
    [tpl.id]
  );
  return { ...tpl, itens };
}

async function listarTemplates({ tipo_ativo, etapa }) {
  const params = [];
  const where = ['t.ativo = TRUE'];
  if (tipo_ativo) { params.push(tipo_ativo); where.push(`t.tipo_ativo = $${params.length}`); }
  if (etapa) { params.push(etapa); where.push(`t.etapa = $${params.length}`); }
  const { rows } = await pool.query(
    `SELECT t.*, COALESCE(
        (SELECT json_agg(i ORDER BY i.ordem, i.descricao)
           FROM checklist_template_itens i WHERE i.template_id = t.id), '[]'
      ) AS itens
       FROM checklist_templates t
      WHERE ${where.join(' AND ')}
      ORDER BY t.tipo_ativo, t.etapa, t.versao DESC`,
    params
  );
  return rows;
}

async function obterTemplatePorId(id) {
  const { rows } = await pool.query(
    'SELECT * FROM checklist_templates WHERE id = $1', [id]
  );
  if (rows.length === 0) return null;
  const tpl = rows[0];
  const { rows: itens } = await pool.query(
    `SELECT * FROM checklist_template_itens
      WHERE template_id = $1
      ORDER BY ordem ASC, descricao ASC`,
    [id]
  );
  return { ...tpl, itens };
}

function slugify(s) {
  return String(s || '')
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .toLowerCase().trim()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 70);
}

function normalizarItens(itens = []) {
  const usados = new Set();
  return itens.map((it, idx) => {
    let chave = (it.chave_item && String(it.chave_item).trim())
      || slugify(it.descricao) || `item_${idx + 1}`;
    const base = chave;
    let n = 2;
    while (usados.has(chave)) { chave = `${base}_${n++}`; }
    usados.add(chave);
    const opcoes = it.tipo_campo === 'selecao' && Array.isArray(it.opcoes)
      ? it.opcoes.map((o) => String(o).trim()).filter(Boolean)
      : null;
    return {
      chave_item: chave,
      descricao: it.descricao,
      tipo_campo: it.tipo_campo,
      obrigatorio: it.obrigatorio === true,
      ordem: it.ordem != null ? it.ordem : idx + 1,
      opcoes_json: opcoes && opcoes.length ? { opcoes } : null,
    };
  });
}

async function _inserirItens(client, templateId, itens) {
  for (const it of normalizarItens(itens)) {
    await client.query(
      `INSERT INTO checklist_template_itens
         (template_id, chave_item, descricao, tipo_campo, obrigatorio, ordem, opcoes_json)
       VALUES ($1,$2,$3,$4,$5,$6,$7)`,
      [templateId, it.chave_item, it.descricao, it.tipo_campo,
        it.obrigatorio, it.ordem, it.opcoes_json ? JSON.stringify(it.opcoes_json) : null]
    );
  }
}

async function criarTemplate({ tipo_ativo, etapa, nome, itens }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    // Mantem apenas um template ativo por tipo+etapa
    await client.query(
      `UPDATE checklist_templates SET ativo=FALSE, atualizado_em=NOW()
        WHERE tipo_ativo=$1 AND etapa=$2 AND ativo=TRUE`,
      [tipo_ativo, etapa]
    );
    const { rows: vRows } = await client.query(
      `SELECT COALESCE(MAX(versao),0)+1 AS v
         FROM checklist_templates WHERE tipo_ativo=$1 AND etapa=$2`,
      [tipo_ativo, etapa]
    );
    const { rows } = await client.query(
      `INSERT INTO checklist_templates (tipo_ativo, etapa, nome, ativo, versao)
       VALUES ($1,$2,$3,TRUE,$4) RETURNING *`,
      [tipo_ativo, etapa, nome, vRows[0].v]
    );
    await _inserirItens(client, rows[0].id, itens);
    await client.query('COMMIT');
    return obterTemplatePorId(rows[0].id);
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function atualizarTemplate(id, { nome, tipo_ativo, etapa, itens }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const sets = [];
    const params = [];
    if (nome !== undefined) { params.push(nome); sets.push(`nome=$${params.length}`); }
    if (tipo_ativo !== undefined) { params.push(tipo_ativo); sets.push(`tipo_ativo=$${params.length}`); }
    if (etapa !== undefined) { params.push(etapa); sets.push(`etapa=$${params.length}`); }
    if (sets.length) {
      params.push(id);
      await client.query(
        `UPDATE checklist_templates SET ${sets.join(', ')}, atualizado_em=NOW()
          WHERE id=$${params.length}`,
        params
      );
    }
    if (Array.isArray(itens)) {
      await client.query('DELETE FROM checklist_template_itens WHERE template_id=$1', [id]);
      await _inserirItens(client, id, itens);
    }
    await client.query('COMMIT');
    return obterTemplatePorId(id);
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function excluirTemplate(id) {
  await pool.query(
    'UPDATE checklist_templates SET ativo=FALSE, atualizado_em=NOW() WHERE id=$1',
    [id]
  );
  return { ok: true };
}

async function criarChecklistTransacional({
  reserva_id, ativo_id, usuario_id, tipo_checklist, etapa,
  local, responsavel, observacoes, itens,
}) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const insChk = await client.query(
      `INSERT INTO checklists
         (reserva_id, ativo_id, usuario_id, tipo_checklist, etapa,
          local, responsavel, observacoes)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING *`,
      [reserva_id, ativo_id, usuario_id, tipo_checklist, etapa,
        local || null, responsavel || null, observacoes || null]
    );
    const chk = insChk.rows[0];

    for (const it of itens || []) {
      await client.query(
        `INSERT INTO checklist_itens
           (checklist_id, chave_item, descricao_item,
            valor_texto, valor_numero, valor_booleano,
            obrigatorio, ordem)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
        [chk.id, it.chave_item, it.descricao_item || null,
        it.valor_texto || null,
        it.valor_numero !== undefined && it.valor_numero !== null ? it.valor_numero : null,
        it.valor_booleano !== undefined && it.valor_booleano !== null ? it.valor_booleano : null,
        it.obrigatorio === true,
        it.ordem || 0]
      );
    }

    if (etapa === 'RETIRADA') {
      await client.query(
        `UPDATE reservas SET status='EM_USO', atualizado_em=NOW()
          WHERE id=$1 AND status IN ('CONFIRMADA','PENDENTE')`,
        [reserva_id]
      );
    } else if (etapa === 'DEVOLUCAO') {
      await client.query(
        `UPDATE reservas SET status='CONCLUIDA', atualizado_em=NOW()
          WHERE id=$1 AND status='EM_USO'`,
        [reserva_id]
      );
    }

    await client.query('COMMIT');
    return chk;
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function obterChecklist(id) {
  const { rows } = await pool.query(
    `SELECT c.*, a.codigo_interno, a.descricao AS ativo_descricao,
            u.nome_completo AS usuario_nome
       FROM checklists c
       JOIN ativos a ON a.id = c.ativo_id
       JOIN usuarios u ON u.id = c.usuario_id
      WHERE c.id = $1`,
    [id]
  );
  if (rows.length === 0) return null;
  const chk = rows[0];
  const { rows: itens } = await pool.query(
    `SELECT * FROM checklist_itens WHERE checklist_id=$1 ORDER BY ordem ASC`,
    [id]
  );
  return { ...chk, itens };
}

async function listarChecklistsDoUsuario(usuario_id) {
  const { rows } = await pool.query(
    `SELECT c.*, a.codigo_interno, a.descricao AS ativo_descricao
       FROM checklists c
       JOIN ativos a ON a.id = c.ativo_id
      WHERE c.usuario_id = $1
      ORDER BY c.data_hora_evento DESC
      LIMIT 100`,
    [usuario_id]
  );
  return rows;
}

module.exports = {
  obterTemplateAtivo, listarTemplates,
  obterTemplatePorId, criarTemplate, atualizarTemplate, excluirTemplate,
  criarChecklistTransacional, obterChecklist,
  listarChecklistsDoUsuario,
};
