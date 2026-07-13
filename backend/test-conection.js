require('dotenv').config();
const { Pool } = require('pg');

const url = process.env.DATABASE_URL || '';
const masked = url.replace(/:\/\/([^:]+):([^@]+)@/, '://$1:***@');
console.log('[INFO] DATABASE_URL =', masked || '(NAO DEFINIDA)');

if (!url) {
  console.error('[ERRO] DATABASE_URL nao definida no .env');
  process.exit(1);
}

const pool = new Pool({
  connectionString: url,
  ssl: { rejectUnauthorized: false },
  connectionTimeoutMillis: 10000,
});

(async () => {
  try {
    console.log('[INFO] Conectando ao Neon...');
    const { rows } = await pool.query(
      'SELECT NOW() as agora, current_user as usuario, current_database() as banco;'
    );
    console.log('[OK] Conexao bem-sucedida!');
    console.log('     Usuario:', rows[0].usuario);
    console.log('     Banco:  ', rows[0].banco);
    console.log('     Hora:   ', rows[0].agora);
  } catch (err) {
    console.error('[ERRO] Falha:', err.code, '-', err.message);
  } finally {
    await pool.end().catch(() => {});
  }
})();