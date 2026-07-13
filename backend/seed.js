/**
 * seed.js
 * ----------------------------------------------
 * Popula perfis padrão e cria usuário administrador inicial.
 * Uso: node seed.js
 *
 * Admin padrão:
 *   email: admin@gdm.com
 *   senha: Admin@123
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
  pool.on('error', (e) => log('AVISO', e.message));

  const client = await pool.connect();
  try {
    log('INFO', 'Inserindo perfis padrão...');
    await client.query(`
      INSERT INTO perfis (nome, descricao)
      VALUES
        ('USUARIO', 'Usuário operacional padrão'),
        ('ADMINISTRADOR', 'Administrador da plataforma'),
        ('GERENTE', 'Gestor com acesso analítico'),
        ('RESPONSAVEL', 'Responsável por ativos - aprova reservas'),
        ('VIGILANTE', 'Vigilante de portaria - confere liberação de saída dos veículos')
      ON CONFLICT (nome) DO NOTHING;
    `);
    log('OK', 'Perfis garantidos.');

    const { rows: perfilRows } = await client.query(
      "SELECT id FROM perfis WHERE nome = 'ADMINISTRADOR' LIMIT 1"
    );
    const perfilAdminId = perfilRows[0].id;

    const senhaHash = await bcrypt.hash('Admin@123', 10);

    log('INFO', 'Criando usuário admin padrão (se não existir)...');
    await client.query(
      `
      INSERT INTO usuarios
        (nome_completo, matricula, email, telefone, unidade_lotacao,
         senha_hash, perfil_id, status)
      VALUES
        ($1,$2,$3,$4,$5,$6,$7,'ATIVO')
      ON CONFLICT (email) DO NOTHING;
      `,
      [
        'Administrador GDM',
        'ADM-0001',
        'admin@gdm.com',
        '(00) 00000-0000',
        'Porto Nacional - TO',
        senhaHash,
        perfilAdminId,
      ]
    );

    log('OK', 'Seed concluído.');
    log('INFO', 'Login admin -> admin@gdm.com / Admin@123');
  } catch (err) {
    log('ERRO', err.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

main();
