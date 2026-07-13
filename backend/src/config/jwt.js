/**
 * Helpers para emissao e verificacao de tokens JWT.
 * Valores hardcoded com fallback seguro de longa duracao.
 */
const jwt = require('jsonwebtoken');

const ACCESS_SECRET = process.env.JWT_SECRET || 'dev-access-secret-trocar-em-prod';
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret-trocar-em-prod';

// Default: 24h pra access (turno + folga), 60d pra refresh
const ACCESS_EXPIRES = process.env.JWT_EXPIRES_IN || '24h';
const REFRESH_EXPIRES = process.env.JWT_REFRESH_EXPIRES_IN || '60d';

console.log('[JWT] Config carregada:');
console.log(`[JWT]   Access token expira em:  ${ACCESS_EXPIRES}`);
console.log(`[JWT]   Refresh token expira em: ${REFRESH_EXPIRES}`);
console.log(`[JWT]   Access secret length:    ${ACCESS_SECRET.length} chars`);

function signAccessToken(payload) {
  return jwt.sign(payload, ACCESS_SECRET, { expiresIn: ACCESS_EXPIRES });
}

function signRefreshToken(payload) {
  return jwt.sign(payload, REFRESH_SECRET, { expiresIn: REFRESH_EXPIRES });
}

function verifyAccessToken(token) {
  return jwt.verify(token, ACCESS_SECRET);
}

function verifyRefreshToken(token) {
  return jwt.verify(token, REFRESH_SECRET);
}

module.exports = {
  signAccessToken,
  signRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
  ACCESS_EXPIRES,
};
