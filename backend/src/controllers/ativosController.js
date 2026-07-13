const ativoService = require('../services/ativoService');
const { registrarEvento } = require('../middlewares/auditMiddleware');

async function listar(req, res, next) {
  try {
    const dados = await ativoService.listar(req.query);
    res.json({ data: dados.rows, meta: { total: dados.total } });
  } catch (e) { next(e); }
}

async function obter(req, res, next) {
  try {
    const ativo = await ativoService.obter(req.params.id);
    if (!ativo) {
      const err = new Error('Ativo nao encontrado'); err.code = 'VAL_001';
      return next(err);
    }
    res.json({ data: ativo });
  } catch (e) { next(e); }
}

async function criar(req, res, next) {
  try {
    const ativo = await ativoService.criar(req.body);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'ativos', entidade_id: ativo.id,
      acao: 'CRIAR_ATIVO', depois: ativo,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.status(201).json({ data: ativo, message: 'Ativo criado' });
  } catch (e) { next(e); }
}

async function atualizar(req, res, next) {
  try {
    const antes = await ativoService.obter(req.params.id);
    const ativo = await ativoService.atualizar(req.params.id, req.body);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'ativos', entidade_id: req.params.id,
      acao: 'ATUALIZAR_ATIVO', antes, depois: ativo,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.json({ data: ativo, message: 'Ativo atualizado' });
  } catch (e) { next(e); }
}

async function atualizarStatus(req, res, next) {
  try {
    const ativo = await ativoService.atualizarStatus(req.params.id, req.body.status);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'ativos', entidade_id: req.params.id,
      acao: 'ATUALIZAR_STATUS_ATIVO',
      depois: { status: req.body.status },
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.json({ data: ativo, message: 'Status atualizado' });
  } catch (e) { next(e); }
}

async function excluir(req, res, next) {
  try {
    await ativoService.atualizarStatus(req.params.id, 'INDISPONIVEL');
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'ativos', entidade_id: req.params.id,
      acao: 'EXCLUIR_LOGICO_ATIVO',
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.json({ data: null, message: 'Ativo desativado' });
  } catch (e) { next(e); }
}

async function uploadFoto(req, res, next) {
  try {
    if (!req.file) {
      const err = new Error('Nenhum arquivo enviado'); err.code = 'VAL_003';
      return next(err);
    }
    const url = `/uploads/ativos/${req.file.filename}`;
    res.status(201).json({ data: { url }, message: 'Foto enviada' });
  } catch (e) { next(e); }
}

module.exports = { listar, obter, criar, atualizar, atualizarStatus, excluir, uploadFoto };
