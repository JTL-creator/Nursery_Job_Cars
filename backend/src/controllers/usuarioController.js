const pool = require('../config/database');
const reservaService = require('../services/reservaService');
const checklistService = require('../services/checklistService');
const usuarioService = require('../services/usuarioService');
const { registrarEvento } = require('../middlewares/auditMiddleware');

async function me(req, res, next) {
  try {
    const { rows } = await pool.query(
      `SELECT u.id, u.nome_completo, u.matricula, u.email, u.telefone,
              u.unidade_lotacao, u.status, u.ultimo_login_em, p.nome AS perfil
         FROM usuarios u
         JOIN perfis p ON p.id = u.perfil_id
        WHERE u.id = $1`,
      [req.user.sub]
    );
    res.json({ data: rows[0] || null });
  } catch (e) { next(e); }
}

async function minhasReservas(req, res, next) {
  try {
    const list = await reservaService.listarReservas({
      usuario_id: req.user.sub,
      status: req.query.status,
      limit: req.query.limit,
      offset: req.query.offset,
    });
    res.json({ data: list, meta: { total: list.length } });
  } catch (e) { next(e); }
}

async function minhasChecklists(req, res, next) {
  try {
    const list = await checklistService.listarChecklistsDoUsuario(req.user.sub);
    res.json({ data: list, meta: { total: list.length } });
  } catch (e) { next(e); }
}

async function listar(req, res, next) {
  try {
    const { perfil, q, status } = req.query;
    const rows = await usuarioService.listar({ perfil, q, status });
    res.json({ data: rows, meta: { total: rows.length } });
  } catch (e) { next(e); }
}

async function obter(req, res, next) {
  try {
    const u = await usuarioService.obter(req.params.id);
    if (!u) { const err = new Error('Usuario nao encontrado'); err.code = 'VAL_001'; return next(err); }
    res.json({ data: u });
  } catch (e) { next(e); }
}

async function criar(req, res, next) {
  try {
    const u = await usuarioService.criar(req.body);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'usuarios', entidade_id: u.id,
      acao: 'CRIAR_USUARIO', depois: u,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.status(201).json({ data: u, message: 'Usuario criado' });
  } catch (e) { next(e); }
}

async function atualizar(req, res, next) {
  try {
    const antes = await usuarioService.obter(req.params.id);
    const u = await usuarioService.atualizar(req.params.id, req.body);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'usuarios', entidade_id: req.params.id,
      acao: 'ATUALIZAR_USUARIO', antes, depois: u,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.json({ data: u, message: 'Usuario atualizado' });
  } catch (e) { next(e); }
}

async function alterarStatus(req, res, next) {
  try {
    const u = await usuarioService.alterarStatus(req.params.id, req.body.status);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'usuarios', entidade_id: req.params.id,
      acao: 'ALTERAR_STATUS_USUARIO', depois: { status: req.body.status },
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.json({ data: u, message: 'Status atualizado' });
  } catch (e) { next(e); }
}

async function redefinirSenha(req, res, next) {
  try {
    await usuarioService.redefinirSenha(req.params.id, req.body.senha);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'usuarios', entidade_id: req.params.id,
      acao: 'REDEFINIR_SENHA_USUARIO',
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.json({ data: null, message: 'Senha redefinida' });
  } catch (e) { next(e); }
}

async function listarPerfis(req, res, next) {
  try {
    const rows = await usuarioService.listarPerfis();
    res.json({ data: rows, meta: { total: rows.length } });
  } catch (e) { next(e); }
}

module.exports = {
  me, minhasReservas, minhasChecklists, listar, obter, criar,
  atualizar, alterarStatus, redefinirSenha, listarPerfis,
};
