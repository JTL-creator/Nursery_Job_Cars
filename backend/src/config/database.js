/**
 * Configuração do pool PostgreSQL (Neon).
 */
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: 10,
  idleTimeoutMillis: 30000,
});

// Evita derrubar o processo em ECONNRESET / desconexões transitórias do Neon
pool.on('error', (err) => {
  console.warn('[DB][AVISO] Erro no pool:', err.message);
});

module.exports = pool;
