/**
 * seed-responsavel.js
 * ----------------------------------------------
 * Cria um usuario RESPONSAVEL de demonstracao e o vincula como responsavel
 * de todos os ativos que ainda nao possuem responsavel.
 *
 * Uso: node seed-responsavel.js
 *
 * Responsavel demo:
 *   email: responsavel@gdm.com
 *   senha: Resp@123
 */
require('dotenv').config();
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

const log = (tag, msg) => console.log(`[${tag}] ${msg}`);

async function main() {
    const pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
    });
    const client = await pool.connect();
    try {
        const { rows: perfilRows } = await client.query(
            "SELECT id FROM perfis WHERE nome = 'RESPONSAVEL' LIMIT 1"
        );
        if (perfilRows.length === 0) {
            throw new Error('Perfil RESPONSAVEL nao existe. Rode a migration sprint3 antes.');
        }
        const perfilId = perfilRows[0].id;

        const senhaHash = await bcrypt.hash('Resp@123', 10);

        log('INFO', 'Criando usuario responsavel demo (se nao existir)...');
        await client.query(
            `INSERT INTO usuarios
         (nome_completo, matricula, email, telefone, unidade_lotacao,
          senha_hash, perfil_id, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,'ATIVO')
       ON CONFLICT (email) DO NOTHING;`,
            [
                'Responsavel GDM', 'RESP-0001', 'responsavel@gdm.com',
                '(00) 00000-0000', 'Porto Nacional - TO', senhaHash, perfilId,
            ]
        );

        const { rows: respRows } = await client.query(
            "SELECT id FROM usuarios WHERE email = 'responsavel@gdm.com' LIMIT 1"
        );
        const responsavelId = respRows[0].id;

        log('INFO', 'Vinculando responsavel aos ativos sem responsavel...');
        const upd = await client.query(
            `UPDATE ativos SET responsavel_id = $1, atualizado_em = NOW()
        WHERE responsavel_id IS NULL`,
            [responsavelId]
        );

        log('OK', `Ativos vinculados: ${upd.rowCount}`);
        log('INFO', 'Login responsavel -> responsavel@gdm.com / Resp@123');
    } catch (err) {
        log('ERRO', err.message);
        process.exitCode = 1;
    } finally {
        client.release();
        await pool.end();
    }
}

main();
