/**
 * apply-schema.js
 * ----------------------------------------------
 * Aplica o schema PostgreSQL no banco Neon.
 * Uso: node apply-schema.js
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const log = (tag, msg) => console.log(`[${tag}] ${msg}`);

async function main() {
  if (!process.env.DATABASE_URL) {
    log('ERRO', 'DATABASE_URL não definida no .env');
    process.exit(1);
  }

  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });

  // Evita crash em desconexões transitórias do Neon
  pool.on('error', (err) => {
    log('AVISO', `Erro no pool (ignorado): ${err.message}`);
  });

  const schemaPath = path.join(__dirname, 'db', 'schema.sql');
  log('INFO', `Lendo schema de: ${schemaPath}`);
  const sql = fs.readFileSync(schemaPath, 'utf-8');

  const client = await pool.connect();
  try {
    log('INFO', 'Aplicando schema no banco...');
    await client.query(sql);
    log('OK', 'Schema aplicado com sucesso!');
  } catch (err) {
    log('ERRO', `Falha ao aplicar schema: ${err.message}`);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
    log('INFO', 'Conexão encerrada.');
  }
}

main();
