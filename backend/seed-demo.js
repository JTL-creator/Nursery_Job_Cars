/**
 * seed-demo.js
 * --------------------------------------------------
 * Popula ~20 reservas variadas + check-lists para demonstracao do MVP.
 * Idempotente: reservas/check-lists demo sao marcados com "[DEMO]" e
 * recriados a cada execucao. Tambem normaliza o status dos ativos.
 *
 * Uso: node seed-demo.js   (ou: npm run seed:demo)
 */
require('dotenv').config();
const { Pool } = require('pg');

const log = (tag, msg) => console.log(`[${tag}] ${msg}`);

const rand = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
const horas = (h) => h * 3600 * 1000;
const dias = (d) => d * 24 * 3600 * 1000;

const MOTIVOS = [
    'Visita tecnica a campo',
    'Transporte de insumos',
    'Vistoria de lavoura',
    'Coleta de amostras de solo',
    'Reuniao com produtor parceiro',
    'Acompanhamento de plantio',
    'Monitoramento de pragas',
    'Entrega de materiais',
    'Suporte a equipe de campo',
    'Deslocamento entre unidades',
];

const FRASES_TEXTO = [
    'Sem avarias aparentes',
    'Em bom estado',
    'Conforme padrao',
    'Verificado e OK',
];

const MOTIVOS_REJEICAO = [
    'Periodo indisponivel para o ativo',
    'Conflito com manutencao programada',
    'Justificativa insuficiente',
];

function valorPara(it) {
    const tipo = it.tipo_campo;
    const chave = (it.chave_item || '').toLowerCase();
    if (tipo === 'numero') {
        if (chave.includes('quilometr') || chave.includes('km')) {
            return { valor_numero: rand(15000, 90000) };
        }
        if (chave.includes('horimetro')) return { valor_numero: rand(300, 5000) };
        if (chave.includes('lat')) {
            return { valor_numero: Number((-10.7 - Math.random() * 0.2).toFixed(6)) };
        }
        if (chave.includes('long')) {
            return { valor_numero: Number((-48.4 - Math.random() * 0.2).toFixed(6)) };
        }
        return { valor_numero: rand(1, 100) };
    }
    if (tipo === 'booleano') return { valor_booleano: Math.random() > 0.15 };
    if (tipo === 'selecao') {
        const opc = (it.opcoes_json && Array.isArray(it.opcoes_json.opcoes))
            ? it.opcoes_json.opcoes : [];
        // tende a escolher as primeiras opcoes (ex.: "OK", "Cheio")
        const escolha = opc.length ? opc[rand(0, Math.min(opc.length, 2) - 1)] : 'OK';
        return { valor_texto: escolha };
    }
    if (tipo === 'data') {
        return { valor_texto: new Date().toISOString().slice(0, 10) };
    }
    return { valor_texto: pick(FRASES_TEXTO) };
}

async function main() {
    const pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
    });
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // ---- Limpeza dos dados demo anteriores ----
        await client.query(`
      DELETE FROM checklist_itens WHERE checklist_id IN (
        SELECT c.id FROM checklists c
          JOIN reservas r ON r.id = c.reserva_id
         WHERE r.observacoes LIKE '[DEMO]%'
      )`);
        await client.query(`
      DELETE FROM checklists WHERE reserva_id IN (
        SELECT id FROM reservas WHERE observacoes LIKE '[DEMO]%'
      )`);
        await client.query(`DELETE FROM reservas WHERE observacoes LIKE '[DEMO]%'`);
        log('OK', 'Dados demo anteriores removidos.');

        // ---- Dados base ----
        const { rows: ativos } = await client.query(
            `SELECT id, codigo_interno, tipo_ativo, unidade FROM ativos
        WHERE status <> 'INDISPONIVEL' ORDER BY codigo_interno`
        );
        if (ativos.length === 0) throw new Error('Nenhum ativo cadastrado. Rode o seed de ativos antes.');

        const { rows: usuarios } = await client.query(
            `SELECT id, nome_completo FROM usuarios WHERE status = 'ATIVO' ORDER BY nome_completo`
        );
        if (usuarios.length === 0) throw new Error('Nenhum usuario ativo.');

        const { rows: adminRows } = await client.query(
            `SELECT u.id FROM usuarios u JOIN perfis p ON p.id = u.perfil_id
        WHERE p.nome = 'ADMINISTRADOR' AND u.status = 'ATIVO' LIMIT 1`
        );
        const adminId = adminRows[0]?.id || usuarios[0].id;

        // Templates ativos por tipo+etapa (com itens)
        const { rows: tplRows } = await client.query(`
      SELECT t.tipo_ativo, t.etapa,
             (SELECT json_agg(i ORDER BY i.ordem)
                FROM checklist_template_itens i WHERE i.template_id = t.id) AS itens
        FROM checklist_templates t
       WHERE t.ativo = TRUE
       ORDER BY t.versao DESC`);
        const templates = {}; // chave: TIPO_ETAPA
        for (const t of tplRows) {
            const k = `${t.tipo_ativo}_${t.etapa}`;
            if (!templates[k]) templates[k] = t.itens || [];
        }

        // ---- Plano de status (20 reservas) ----
        const plano = [
            ...Array(9).fill('CONCLUIDA'),
            ...Array(3).fill('EM_USO'),
            ...Array(3).fill('CONFIRMADA'),
            ...Array(2).fill('PENDENTE'),
            ...Array(2).fill('CANCELADA'),
            ...Array(1).fill('REJEITADA'),
        ];

        const agora = Date.now();
        let nReservas = 0;
        let nChecklists = 0;
        const emUsoAtivoIds = [];

        async function inserirChecklist(reservaId, ativo, usuario, etapa, quando) {
            const itens = templates[`${ativo.tipo_ativo}_${etapa}`];
            if (!itens || itens.length === 0) return;
            const { rows } = await client.query(
                `INSERT INTO checklists
           (reserva_id, ativo_id, usuario_id, tipo_checklist, etapa,
            data_hora_evento, local, responsavel, observacoes)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING id`,
                [reservaId, ativo.id, usuario.id, ativo.tipo_ativo, etapa, quando,
                    ativo.unidade || 'Porto Nacional - TO', usuario.nome_completo,
                    `[DEMO] Check-list de ${etapa === 'RETIRADA' ? 'retirada' : 'devolucao'}`]
            );
            const chkId = rows[0].id;
            for (const it of itens) {
                const v = valorPara(it);
                await client.query(
                    `INSERT INTO checklist_itens
             (checklist_id, chave_item, descricao_item, valor_texto,
              valor_numero, valor_booleano, obrigatorio, ordem)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
                    [chkId, it.chave_item, it.descricao,
                        v.valor_texto ?? null,
                        v.valor_numero ?? null,
                        v.valor_booleano ?? null,
                        it.obrigatorio === true, it.ordem || 0]
                );
            }
            nChecklists++;
        }

        for (let i = 0; i < plano.length; i++) {
            const status = plano[i];
            const ativo = ativos[i % ativos.length];
            const usuario = usuarios[i % usuarios.length];
            const motivo = pick(MOTIVOS);

            let inicio;
            let fim;
            let criadoEm;
            let confirmadoEm = null;
            let canceladoEm = null;
            let aprovadoPor = null;
            let aprovadoEm = null;
            let rejeitadoPor = null;
            let rejeitadoEm = null;
            let motivoRejeicao = null;
            const durMs = horas(rand(3, 8));

            if (status === 'CONCLUIDA') {
                const d = rand(2, 25);
                inicio = new Date(agora - dias(d) + horas(rand(7, 11)) - horas(7));
                fim = new Date(inicio.getTime() + durMs);
                criadoEm = new Date(inicio.getTime() - dias(rand(1, 3)));
                confirmadoEm = new Date(inicio.getTime() - dias(1));
                aprovadoPor = adminId; aprovadoEm = confirmadoEm;
            } else if (status === 'EM_USO') {
                inicio = new Date(agora - horas(rand(2, 6)));
                fim = new Date(agora + horas(rand(2, 5)));
                criadoEm = new Date(agora - horas(rand(6, 20)));
                confirmadoEm = new Date(inicio.getTime() - horas(1));
                aprovadoPor = adminId; aprovadoEm = confirmadoEm;
                emUsoAtivoIds.push(ativo.id);
            } else if (status === 'CONFIRMADA') {
                inicio = new Date(agora + dias(rand(1, 7)) + horas(rand(7, 12)) - horas(7));
                fim = new Date(inicio.getTime() + durMs);
                criadoEm = new Date(agora - dias(rand(0, 2)));
                confirmadoEm = new Date(agora - horas(rand(1, 20)));
                aprovadoPor = adminId; aprovadoEm = confirmadoEm;
            } else if (status === 'PENDENTE') {
                inicio = new Date(agora + dias(rand(1, 5)) + horas(rand(7, 12)) - horas(7));
                fim = new Date(inicio.getTime() + durMs);
                criadoEm = new Date(agora - horas(rand(0, 10)));
            } else if (status === 'CANCELADA') {
                const d = rand(1, 12);
                inicio = new Date(agora - dias(d) + horas(rand(8, 12)) - horas(7));
                fim = new Date(inicio.getTime() + durMs);
                criadoEm = new Date(inicio.getTime() - dias(1));
                canceladoEm = new Date(inicio.getTime() - horas(rand(2, 12)));
            } else { // REJEITADA
                inicio = new Date(agora + dias(rand(1, 6)) + horas(rand(8, 12)) - horas(7));
                fim = new Date(inicio.getTime() + durMs);
                criadoEm = new Date(agora - dias(rand(0, 2)));
                rejeitadoPor = adminId; rejeitadoEm = new Date(criadoEm.getTime() + horas(rand(1, 6)));
                motivoRejeicao = pick(MOTIVOS_REJEICAO);
            }

            const { rows } = await client.query(
                `INSERT INTO reservas
           (usuario_id, ativo_id, data_hora_inicio, data_hora_fim, status,
            motivo, observacoes, criado_em, atualizado_em,
            confirmado_em, cancelado_em,
            aprovado_por, aprovado_em, rejeitado_por, rejeitado_em, motivo_rejeicao)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$8,$9,$10,$11,$12,$13,$14,$15)
         RETURNING id`,
                [usuario.id, ativo.id, inicio, fim, status,
                    motivo, `[DEMO] ${motivo}`, criadoEm,
                    confirmadoEm, canceladoEm,
                    aprovadoPor, aprovadoEm, rejeitadoPor, rejeitadoEm, motivoRejeicao]
            );
            const reservaId = rows[0].id;
            nReservas++;

            // Check-lists
            if (status === 'CONCLUIDA') {
                await inserirChecklist(reservaId, ativo, usuario, 'RETIRADA', inicio);
                await inserirChecklist(reservaId, ativo, usuario, 'DEVOLUCAO', fim);
            } else if (status === 'EM_USO') {
                await inserirChecklist(reservaId, ativo, usuario, 'RETIRADA', inicio);
            }
        }

        // ---- Normaliza status dos ativos para o dashboard ----
        await client.query(`UPDATE ativos SET status='DISPONIVEL' WHERE status <> 'INDISPONIVEL'`);
        if (emUsoAtivoIds.length) {
            await client.query(
                `UPDATE ativos SET status='RESERVADO' WHERE id = ANY($1::uuid[])`,
                [emUsoAtivoIds]
            );
        }
        // deixa 1 maquina em manutencao para variar o grafico (se existir)
        await client.query(`
      UPDATE ativos SET status='MANUTENCAO'
       WHERE id = (SELECT id FROM ativos
                    WHERE tipo_ativo='MAQUINA_AGRICOLA' AND status='DISPONIVEL'
                    ORDER BY codigo_interno LIMIT 1)`);

        await client.query('COMMIT');
        log('OK', `Reservas criadas: ${nReservas}`);
        log('OK', `Check-lists criados: ${nChecklists}`);
        log('INFO', 'Distribuicao: 9 concluidas, 3 em uso, 3 confirmadas, 2 pendentes, 2 canceladas, 1 rejeitada.');
        log('OK', 'Seed de demonstracao concluido!');
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
