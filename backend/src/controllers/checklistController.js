const checklistService = require('../services/checklistService');
const reservaService = require('../services/reservaService');
const { registrarEvento } = require('../middlewares/auditMiddleware');

async function obterTemplate(req, res, next) {
  try {
    const { etapa } = req.query;
    if (!['RETIRADA', 'DEVOLUCAO'].includes(etapa)) {
      const e = new Error('etapa invalida'); e.code = 'VAL_002'; throw e;
    }
    const r = await reservaService.obterReserva(req.params.id);
    if (!r) { const e = new Error('Reserva nao encontrada'); e.code = 'RES_003'; throw e; }

    const tpl = await checklistService.obterTemplateAtivo(r.tipo_ativo, etapa);
    if (!tpl) { const e = new Error('Template nao encontrado'); e.code = 'CHK_002'; throw e; }

    res.json({ data: tpl });
  } catch (e) { next(e); }
}

async function criar(req, res, next) {
  try {
    const r = await reservaService.obterReserva(req.params.id);
    if (!r) { const e = new Error('Reserva nao encontrada'); e.code = 'CHK_001'; throw e; }

    const isAdmin = req.user.perfil === 'ADMINISTRADOR';
    if (!isAdmin && r.usuario_id !== req.user.sub) {
      const e = new Error('Acesso negado'); e.code = 'PERM_001'; throw e;
    }

    const { etapa, local, responsavel, observacoes, itens } = req.body;

    if (etapa === 'RETIRADA' && !['CONFIRMADA', 'PENDENTE'].includes(r.status)) {
      const e = new Error('Reserva nao esta apta para retirada'); e.code = 'CHK_001'; throw e;
    }
    if (etapa === 'DEVOLUCAO' && r.status !== 'EM_USO') {
      const e = new Error('Reserva nao esta apta para devolucao'); e.code = 'CHK_001'; throw e;
    }

    const chk = await checklistService.criarChecklistTransacional({
      reserva_id: req.params.id,
      ativo_id: r.ativo_id,
      usuario_id: req.user.sub,
      tipo_checklist: r.tipo_ativo,
      etapa, local, responsavel, observacoes, itens,
    });

    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'checklists', entidade_id: chk.id,
      acao: etapa === 'RETIRADA' ? 'CRIAR_CHECKLIST_RETIRADA' : 'CRIAR_CHECKLIST_DEVOLUCAO',
      depois: chk,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });

    res.status(201).json({ data: chk, message: 'Check-list registrado' });
  } catch (e) { next(e); }
}

async function obter(req, res, next) {
  try {
    const chk = await checklistService.obterChecklist(req.params.id);
    if (!chk) { const e = new Error('Check-list nao encontrado'); e.code = 'VAL_001'; throw e; }
    res.json({ data: chk });
  } catch (e) { next(e); }
}

async function minhas(req, res, next) {
  try {
    const list = await checklistService.listarChecklistsDoUsuario(req.user.sub);
    res.json({ data: list, meta: { total: list.length } });
  } catch (e) { next(e); }
}

async function listarTemplates(req, res, next) {
  try {
    const list = await checklistService.listarTemplates(req.query);
    res.json({ data: list, meta: { total: list.length } });
  } catch (e) { next(e); }
}

async function obterTemplatePorId(req, res, next) {
  try {
    const tpl = await checklistService.obterTemplatePorId(req.params.id);
    if (!tpl) { const e = new Error('Template nao encontrado'); e.code = 'CHK_002'; throw e; }
    res.json({ data: tpl });
  } catch (e) { next(e); }
}

async function criarTemplate(req, res, next) {
  try {
    const tpl = await checklistService.criarTemplate(req.body);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'checklist_templates', entidade_id: tpl.id,
      acao: 'CRIAR_TEMPLATE', depois: tpl,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.status(201).json({ data: tpl, message: 'Template criado' });
  } catch (e) { next(e); }
}

async function atualizarTemplate(req, res, next) {
  try {
    const antes = await checklistService.obterTemplatePorId(req.params.id);
    if (!antes) { const e = new Error('Template nao encontrado'); e.code = 'CHK_002'; throw e; }
    const tpl = await checklistService.atualizarTemplate(req.params.id, req.body);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'checklist_templates', entidade_id: req.params.id,
      acao: 'ATUALIZAR_TEMPLATE', antes, depois: tpl,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.json({ data: tpl, message: 'Template atualizado' });
  } catch (e) { next(e); }
}

async function excluirTemplate(req, res, next) {
  try {
    await checklistService.excluirTemplate(req.params.id);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'checklist_templates', entidade_id: req.params.id,
      acao: 'EXCLUIR_TEMPLATE',
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.json({ data: null, message: 'Template desativado' });
  } catch (e) { next(e); }
}

module.exports = {
  obterTemplate, criar, obter, minhas, listarTemplates,
  obterTemplatePorId, criarTemplate, atualizarTemplate, excluirTemplate,
};
