/**
 * seed-templates.js
 * --------------------------------------------------
 * Insere templates de check-list padrao e ativos de exemplo.
 * Idempotente: usa WHERE NOT EXISTS, pode rodar varias vezes.
 *
 * Uso: node seed-templates.js
 */
require('dotenv').config();
const { Pool } = require('pg');

const log = (tag, msg) => console.log(`[${tag}] ${msg}`);

const TEMPLATES = [
  {
    nome: 'Veiculo - Retirada',
    tipo_ativo: 'VEICULO',
    etapa: 'RETIRADA',
    itens: [
      { chave: 'quilometragem_inicial', descricao: 'Quilometragem inicial', tipo: 'numero', obrigatorio: true, ordem: 1 },
      { chave: 'nivel_combustivel', descricao: 'Nivel de combustivel', tipo: 'selecao', obrigatorio: true, ordem: 2,
        opcoes: ['Reserva', '1/4', '1/2', '3/4', 'Cheio'] },
      { chave: 'estado_pneus', descricao: 'Estado dos pneus', tipo: 'selecao', obrigatorio: true, ordem: 3,
        opcoes: ['OK', 'Atencao', 'Trocar'] },
      { chave: 'estado_lataria', descricao: 'Estado da lataria', tipo: 'texto', obrigatorio: true, ordem: 4 },
      { chave: 'farois_setas_ok', descricao: 'Farois e setas funcionando', tipo: 'booleano', obrigatorio: true, ordem: 5 },
      { chave: 'documentos_no_veiculo', descricao: 'Documentos no veiculo', tipo: 'booleano', obrigatorio: true, ordem: 6 },
      { chave: 'observacoes', descricao: 'Observacoes', tipo: 'texto', obrigatorio: false, ordem: 7 },
      { chave: 'foto_veiculo', descricao: 'Foto do veiculo', tipo: 'texto', obrigatorio: true, ordem: 8 },
      { chave: 'gps_lat', descricao: 'Latitude (GPS)', tipo: 'numero', obrigatorio: false, ordem: 9 },
      { chave: 'gps_long', descricao: 'Longitude (GPS)', tipo: 'numero', obrigatorio: false, ordem: 10 },
    ],
  },
  {
    nome: 'Veiculo - Devolucao',
    tipo_ativo: 'VEICULO',
    etapa: 'DEVOLUCAO',
    itens: [
      { chave: 'quilometragem_final', descricao: 'Quilometragem final', tipo: 'numero', obrigatorio: true, ordem: 1 },
      { chave: 'nivel_combustivel', descricao: 'Nivel de combustivel', tipo: 'selecao', obrigatorio: true, ordem: 2,
        opcoes: ['Reserva', '1/4', '1/2', '3/4', 'Cheio'] },
      { chave: 'estado_pneus', descricao: 'Estado dos pneus', tipo: 'selecao', obrigatorio: true, ordem: 3,
        opcoes: ['OK', 'Atencao', 'Trocar'] },
      { chave: 'estado_pos_uso', descricao: 'Estado pos-uso da lataria', tipo: 'texto', obrigatorio: true, ordem: 4 },
      { chave: 'farois_setas_ok', descricao: 'Farois e setas funcionando', tipo: 'booleano', obrigatorio: true, ordem: 5 },
      { chave: 'documentos_no_veiculo', descricao: 'Documentos no veiculo', tipo: 'booleano', obrigatorio: true, ordem: 6 },
      { chave: 'observacoes', descricao: 'Observacoes', tipo: 'texto', obrigatorio: false, ordem: 7 },
      { chave: 'foto_veiculo', descricao: 'Foto do veiculo', tipo: 'texto', obrigatorio: true, ordem: 8 },
      { chave: 'gps_lat', descricao: 'Latitude (GPS)', tipo: 'numero', obrigatorio: false, ordem: 9 },
      { chave: 'gps_long', descricao: 'Longitude (GPS)', tipo: 'numero', obrigatorio: false, ordem: 10 },
    ],
  },
  {
    nome: 'Maquina Agricola - Retirada',
    tipo_ativo: 'MAQUINA_AGRICOLA',
    etapa: 'RETIRADA',
    itens: [
      { chave: 'horimetro_inicial', descricao: 'Horimetro inicial', tipo: 'numero', obrigatorio: true, ordem: 1 },
      { chave: 'nivel_combustivel', descricao: 'Nivel de combustivel', tipo: 'selecao', obrigatorio: true, ordem: 2,
        opcoes: ['Reserva', '1/4', '1/2', '3/4', 'Cheio'] },
      { chave: 'nivel_oleo', descricao: 'Nivel de oleo', tipo: 'selecao', obrigatorio: true, ordem: 3,
        opcoes: ['OK', 'Baixo', 'Critico'] },
      { chave: 'implementos_acoplados', descricao: 'Implementos acoplados', tipo: 'texto', obrigatorio: false, ordem: 4 },
      { chave: 'estado_geral', descricao: 'Estado geral', tipo: 'selecao', obrigatorio: true, ordem: 5,
        opcoes: ['OK', 'Atencao', 'Manutencao'] },
      { chave: 'observacoes', descricao: 'Observacoes', tipo: 'texto', obrigatorio: false, ordem: 6 },
      { chave: 'foto_maquina', descricao: 'Foto da maquina', tipo: 'texto', obrigatorio: true, ordem: 7 },
      { chave: 'gps_lat', descricao: 'Latitude (GPS)', tipo: 'numero', obrigatorio: false, ordem: 8 },
      { chave: 'gps_long', descricao: 'Longitude (GPS)', tipo: 'numero', obrigatorio: false, ordem: 9 },
    ],
  },
  {
    nome: 'Maquina Agricola - Devolucao',
    tipo_ativo: 'MAQUINA_AGRICOLA',
    etapa: 'DEVOLUCAO',
    itens: [
      { chave: 'horimetro_final', descricao: 'Horimetro final', tipo: 'numero', obrigatorio: true, ordem: 1 },
      { chave: 'nivel_combustivel', descricao: 'Nivel de combustivel', tipo: 'selecao', obrigatorio: true, ordem: 2,
        opcoes: ['Reserva', '1/4', '1/2', '3/4', 'Cheio'] },
      { chave: 'nivel_oleo', descricao: 'Nivel de oleo', tipo: 'selecao', obrigatorio: true, ordem: 3,
        opcoes: ['OK', 'Baixo', 'Critico'] },
      { chave: 'estado_geral', descricao: 'Estado geral', tipo: 'selecao', obrigatorio: true, ordem: 4,
        opcoes: ['OK', 'Atencao', 'Manutencao'] },
      { chave: 'observacoes', descricao: 'Observacoes', tipo: 'texto', obrigatorio: false, ordem: 5 },
      { chave: 'foto_maquina', descricao: 'Foto da maquina', tipo: 'texto', obrigatorio: true, ordem: 6 },
      { chave: 'gps_lat', descricao: 'Latitude (GPS)', tipo: 'numero', obrigatorio: false, ordem: 7 },
      { chave: 'gps_long', descricao: 'Longitude (GPS)', tipo: 'numero', obrigatorio: false, ordem: 8 },
    ],
  },
];

const ATIVOS_EXEMPLO = [
  { codigo_interno: 'VEIC-001', descricao: 'Job Car Toyota Hilux', tipo_ativo: 'VEICULO',
    sub_tipo: 'Pickup', placa: 'ABC1D23', unidade: 'Porto Nacional - TO' },
  { codigo_interno: 'VEIC-002', descricao: 'Job Car Fiat Strada', tipo_ativo: 'VEICULO',
    sub_tipo: 'Pickup', placa: 'DEF4G56', unidade: 'Porto Nacional - TO' },
  { codigo_interno: 'VEIC-003', descricao: 'Job Car Ford Ranger', tipo_ativo: 'VEICULO',
    sub_tipo: 'Pickup', placa: 'HIJ7K89', unidade: 'Palmas - TO' },
  { codigo_interno: 'MAQ-001', descricao: 'Trator John Deere 6110', tipo_ativo: 'MAQUINA_AGRICOLA',
    sub_tipo: 'Trator', patrimonio: 'PAT-1001', unidade: 'Porto Nacional - TO' },
  { codigo_interno: 'MAQ-002', descricao: 'Pulverizador Jacto', tipo_ativo: 'MAQUINA_AGRICOLA',
    sub_tipo: 'Pulverizador', patrimonio: 'PAT-1002', unidade: 'Porto Nacional - TO' },
];

async function main() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  pool.on('error', (e) => log('AVISO', e.message));

  const client = await pool.connect();
  try {
    log('INFO', 'Inserindo templates de check-list...');

    for (const tpl of TEMPLATES) {
      const exists = await client.query(
        `SELECT id FROM checklist_templates
          WHERE tipo_ativo=$1 AND etapa=$2 AND nome=$3 LIMIT 1`,
        [tpl.tipo_ativo, tpl.etapa, tpl.nome]
      );

      let tplId;
      if (exists.rows.length > 0) {
        tplId = exists.rows[0].id;
        log('SKIP', `Template ${tpl.nome} ja existe`);
      } else {
        const ins = await client.query(
          `INSERT INTO checklist_templates
             (tipo_ativo, etapa, nome, ativo, versao)
           VALUES ($1,$2,$3,TRUE,1) RETURNING id`,
          [tpl.tipo_ativo, tpl.etapa, tpl.nome]
        );
        tplId = ins.rows[0].id;
        log('OK', `Template criado: ${tpl.nome}`);

        for (const it of tpl.itens) {
          await client.query(
            `INSERT INTO checklist_template_itens
               (template_id, chave_item, descricao, tipo_campo,
                obrigatorio, ordem, opcoes_json)
             VALUES ($1,$2,$3,$4,$5,$6,$7)`,
            [tplId, it.chave, it.descricao, it.tipo,
             it.obrigatorio === true, it.ordem,
             it.opcoes ? JSON.stringify({ opcoes: it.opcoes }) : null]
          );
        }
        log('OK', `   ${tpl.itens.length} itens inseridos`);
      }
    }

    log('INFO', 'Inserindo ativos de exemplo...');
    for (const a of ATIVOS_EXEMPLO) {
      const exists = await client.query(
        `SELECT id FROM ativos WHERE codigo_interno=$1`, [a.codigo_interno]
      );
      if (exists.rows.length > 0) {
        log('SKIP', `Ativo ${a.codigo_interno} ja existe`);
        continue;
      }
      await client.query(
        `INSERT INTO ativos
           (codigo_interno, descricao, tipo_ativo, sub_tipo,
            placa, patrimonio, unidade, status)
         VALUES ($1,$2,$3,$4,$5,$6,$7,'DISPONIVEL')`,
        [a.codigo_interno, a.descricao, a.tipo_ativo, a.sub_tipo || null,
         a.placa || null, a.patrimonio || null, a.unidade || null]
      );
      log('OK', `Ativo criado: ${a.codigo_interno} - ${a.descricao}`);
    }

    log('OK', 'Seed de templates e ativos concluido!');
  } catch (err) {
    log('ERRO', err.message);
    console.error(err);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

main();
