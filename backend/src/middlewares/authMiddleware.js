/**
 * Verifica o JWT (access token) e anexa o usuário ao request.
 */
const { verifyAccessToken } = require('../config/jwt');

function authMiddleware(req, res, next) {
  try {
    const header = req.headers['authorization'] || '';
    const [, token] = header.split(' ');

    if (!token) {
      const err = new Error('Token ausente');
      err.code = 'AUTH_003';
      return next(err);
    }

    const payload = verifyAccessToken(token);
    req.user = payload; // { sub, email, perfil }
    next();
  } catch (e) {
    const err = new Error(e.message);
    err.code = 'AUTH_003';
    next(err);
  }
}

module.exports = authMiddleware;
