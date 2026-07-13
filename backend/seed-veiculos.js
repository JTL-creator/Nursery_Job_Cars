/**
 * seed-veiculos.js
 * ----------------------------------------------
 * Cria os responsaveis (Pablo, Jhean) e cadastra os veiculos do padrao.
 * Uso: node seed-veiculos.js
 *
 * Responsaveis criados (perfil RESPONSAVEL), senha = matricula:
 *   Pablo -> pablo@gdm.com   / matricula RESP-PABLO
 *   Jhean -> jhean@gdm.com   / matricula RESP-JHEAN
 */
require('dotenv').config();
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

const log = (tag, msg) => console.log(`[${tag}] ${msg}`);

const RESPONSAVEIS = [
    { nome: 'Pablo', email: 'pablo@gdm.com', matricula: 'RESP-PABLO' },
    { nome: 'Jhean', email: 'jhean@gdm.com', matricula: 'RESP-JHEAN' },
];

const VEICULOS = [
    { modelo: 'S10', placa: 'SEG6I81', equipe: 'Milho', responsavel: 'Pablo' },
    { modelo: 'S10', placa: 'FYV0F42', equipe: 'Soja', responsavel: 'Pablo' },
    { modelo: 'S10', placa: 'FIL9E41', equipe: 'Agronomia', responsavel: 'Pablo' },
    { modelo: 'Mobi', placa: 'TYS2G06', equipe: 'Soja', responsavel: 'Pablo' },
    { modelo: 'Tracker', placa: 'TJJ8B47', equipe: 'Soja', responsavel: 'Jhean' },
];

async function main() {
    const pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
    });
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Garante o perfil RESPONSAVEL
        await client.query(`
      INSERT INTO perfis (nome, descricao)
      VALUES ('RESPONSAVEL', 'Responsavel por ativos - aprova reservas')
      ON CONFLICT (nome) DO NOTHING;
    `);
        const { rows: pRows } = await client.query(
            "SELECT id FROM perfis WHERE nome = 'RESPONSAVEL' LIMIT 1"
        );
        const perfilRespId = pRows[0].id;

        // Cria/garante responsaveis e coleta os ids por nome
        const idsPorNome = {};
        for (const r of RESPONSAVEIS) {
            const senhaHash = await bcrypt.hash(r.matricula, 10);
            await client.query(
                `INSERT INTO usuarios
           (nome_completo, matricula, email, telefone, unidade_lotacao, senha_hash, perfil_id, status)
         VALUES ($1,$2,$3,NULL,'Porto Nacional - TO',$4,$5,'ATIVO')
         ON CONFLICT (email) DO NOTHING;`,
                [r.nome, r.matricula, r.email, senhaHash, perfilRespId]
            );
            const { rows } = await client.query(
                'SELECT id FROM usuarios WHERE email = $1 LIMIT 1', [r.email]
            );
            idsPorNome[r.nome] = rows[0].id;
            log('OK', `Responsavel garantido: ${r.nome} (${r.email})`);
        }

        // Cadastra os veiculos (idempotente via codigo_interno = placa)
        for (const v of VEICULOS) {
            const responsavelId = idsPorNome[v.responsavel] || null;
            await client.query(
                `INSERT INTO ativos
           (codigo_interno, descricao, tipo_ativo, placa, unidade, equipe, responsavel_id, status)
         VALUES ($1,$2,'VEICULO',$3,'Porto Nacional - TO',$4,$5,'DISPONIVEL')
         ON CONFLICT (codigo_interno) DO UPDATE
           SET descricao = EXCLUDED.descricao,
               equipe = EXCLUDED.equipe,
               responsavel_id = EXCLUDED.responsavel_id,
               placa = EXCLUDED.placa,
               atualizado_em = NOW();`,
                [v.placa, v.modelo, v.placa, v.equipe, responsavelId]
            );
            log('OK', `Veiculo cadastrado: ${v.modelo} - ${v.placa} (${v.equipe} / ${v.responsavel})`);
        }

        await client.query('COMMIT');
        log('OK', 'Seed de veiculos concluido!');
        log('INFO', 'Responsaveis -> pablo@gdm.com / RESP-PABLO  |  jhean@gdm.com / RESP-JHEAN (senha = matricula)');
    } catch (e) {
        await client.query('ROLLBACK');
        log('ERRO', e.message);
        process.exitCode = 1;
    } finally {
        client.release();
        await pool.end();
    }
}

main();
