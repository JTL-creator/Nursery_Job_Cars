const cadastroService = require('../services/cadastroService');
const { registrarEvento } = require('../middlewares/auditMiddleware');

async function criarSolicitacao(req, res, next) {
  try {
    const sol = await cadastroService.criarSolicitacao(req.body);
    await registrarEvento({
      entidade: 'solicitacoes_cadastro', entidade_id: sol.id,
      acao: 'CRIAR_SOLICITACAO', depois: sol,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.status(201).json({ data: sol, message: 'Solicitação registrada' });
  } catch (e) { next(e); }
}

async function listarSolicitacoes(req, res, next) {
  try {
    const lista = await cadastroService.listarSolicitacoes(req.query);
    res.json({ data: lista, meta: { total: lista.length } });
  } catch (e) { next(e); }
}

async function aprovar(req, res, next) {
  try {
    const out = await cadastroService.aprovarSolicitacao(req.params.id, req.user.sub);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'solicitacoes_cadastro', entidade_id: req.params.id,
      acao: 'APROVAR_SOLICITACAO',
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.json({ data: out, message: 'Solicitação aprovada' });
  } catch (e) { next(e); }
}

async function rejeitar(req, res, next) {
  try {
    const out = await cadastroService.rejeitarSolicitacao(
      req.params.id, req.user.sub, req.body.observacao_rejeicao
    );
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'solicitacoes_cadastro', entidade_id: req.params.id,
      acao: 'REJEITAR_SOLICITACAO',
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.json({ data: out, message: 'Solicitação rejeitada' });
  } catch (e) { next(e); }
}

module.exports = { criarSolicitacao, listarSolicitacoes, aprovar, rejeitar };
