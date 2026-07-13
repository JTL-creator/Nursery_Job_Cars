require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const log = (tag, msg) => console.log(`[${tag}] ${msg}`);

async function main() {
    const pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
    });
    const client = await pool.connect();
    try {
        const sql = fs.readFileSync(
            path.join(__dirname, 'db', 'migration-sprint4.sql'), 'utf-8'
        );
        log('INFO', 'Aplicando migration Sprint 4 (equipe/foto nos ativos)...');
        await client.query(sql);
        log('OK', 'Migration Sprint 4 aplicada com sucesso!');
    } catch (e) {
        log('ERRO', e.message);
        process.exitCode = 1;
    } finally {
        client.release();
        await pool.end();
    }
}
main();
