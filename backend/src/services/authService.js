const bcrypt = require('bcryptjs');
const pool = require('../config/database');
const { signAccessToken, signRefreshToken } = require('../config/jwt');

async function autenticar(email, senha) {
  const { rows } = await pool.query(
    `SELECT u.id, u.nome_completo, u.email, u.senha_hash, u.status, p.nome AS perfil
       FROM usuarios u
       JOIN perfis p ON p.id = u.perfil_id
      WHERE u.email = $1
      LIMIT 1`,
    [email]
  );
  if (rows.length === 0) {
    const e = new Error('Credenciais inválidas'); e.code = 'AUTH_001'; throw e;
  }
  const user = rows[0];
  if (user.status !== 'ATIVO') {
    const e = new Error('Usuário inativo'); e.code = 'AUTH_002'; throw e;
  }
  const ok = await bcrypt.compare(senha, user.senha_hash);
  if (!ok) {
    const e = new Error('Credenciais inválidas'); e.code = 'AUTH_001'; throw e;
  }

  await pool.query('UPDATE usuarios SET ultimo_login_em = NOW() WHERE id = $1', [user.id]);

  const payload = { sub: user.id, email: user.email, perfil: user.perfil };
  return {
    access_token:  signAccessToken(payload),
    refresh_token: signRefreshToken(payload),
    expires_in:    process.env.JWT_EXPIRES_IN || '15m',
    usuario: {
      id: user.id,
      nome_completo: user.nome_completo,
      email: user.email,
    },
    perfil: user.perfil,
  };
}

module.exports = { autenticar };
