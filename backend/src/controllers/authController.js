const authService = require('../services/authService');
const { verifyRefreshToken, signAccessToken } = require('../config/jwt');
const { registrarEvento } = require('../middlewares/auditMiddleware');

async function login(req, res, next) {
  try {
    const { email, senha } = req.body;
    const data = await authService.autenticar(email, senha);

    await registrarEvento({
      usuario_id: data.usuario.id,
      entidade: 'usuarios', entidade_id: data.usuario.id,
      acao: 'LOGIN',
      ip: req.ip, user_agent: req.headers['user-agent'],
    });

    res.json({ data, message: 'Autenticado com sucesso' });
  } catch (e) { next(e); }
}

async function refresh(req, res, next) {
  try {
    const { refresh_token } = req.body;
    const payload = verifyRefreshToken(refresh_token);
    const access_token = signAccessToken({
      sub: payload.sub, email: payload.email, perfil: payload.perfil,
    });
    res.json({ data: { access_token }, message: 'Token renovado' });
  } catch (e) {
    const err = new Error('Token inválido'); err.code = 'AUTH_003'; next(err);
  }
}

async function logout(req, res, next) {
  try {
    await registrarEvento({
      usuario_id: req.user && req.user.sub,
      entidade: 'usuarios', entidade_id: req.user && req.user.sub,
      acao: 'LOGOUT', ip: req.ip, user_agent: req.headers['user-agent'],
    });
    res.json({ data: null, message: 'Logout efetuado' });
  } catch (e) { next(e); }
}

module.exports = { login, refresh, logout };
