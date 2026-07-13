const pool = require('../config/database');

/** Remove separadores e normaliza a placa para comparacao (ex.: "abc-1d23" -> "ABC1D23"). */
function normalizarPlaca(placa) {
    return String(placa || '')
        .toUpperCase()
        .replace(/[^A-Z0-9]/g, '');
}

/** Busca um ativo (veiculo) pela placa, ignorando separadores e caixa. */
async function buscarAtivoPorPlaca(placa) {
    const norm = normalizarPlaca(placa);
    if (!norm) return null;
    const { rows } = await pool.query(
        `SELECT a.*, u.nome_completo AS responsavel_nome
       FROM ativos a
       LEFT JOIN usuarios u ON u.id = a.responsavel_id
      WHERE regexp_replace(upper(coalesce(a.placa, '')), '[^A-Z0-9]', '', 'g') = $1
      ORDER BY a.codigo_interno ASC
      LIMIT 1`,
        [norm]
    );
    return rows[0] || null;
}

/**
 * Verifica se um veiculo (por placa) esta liberado para sair da unidade.
 * Regras: reserva CONFIRMADA/EM_USO + checklist de RETIRADA realizado +
 * horario atual dentro da janela da reserva.
 */
async function verificarPorPlaca(placa) {
    const ativo = await buscarAtivoPorPlaca(placa);
    if (!ativo) {
        return {
            encontrado: false,
            placa: normalizarPlaca(placa),
            liberado: false,
            motivos: ['Nenhum veiculo cadastrado com esta placa.'],
        };
    }

    // Reserva mais relevante: prioriza a que esta vigente agora.
    const { rows } = await pool.query(
        `SELECT r.*,
            u.nome_completo AS usuario_nome,
            EXISTS (
              SELECT 1 FROM checklists c
               WHERE c.reserva_id = r.id AND c.etapa = 'RETIRADA'
            ) AS checklist_retirada,
            (NOW() BETWEEN r.data_hora_inicio AND r.data_hora_fim) AS dentro_janela
       FROM reservas r
       JOIN usuarios u ON u.id = r.usuario_id
      WHERE r.ativo_id = $1
        AND r.status IN ('CONFIRMADA', 'EM_USO')
      ORDER BY (NOW() BETWEEN r.data_hora_inicio AND r.data_hora_fim) DESC,
               r.data_hora_inicio ASC
      LIMIT 1`,
        [ativo.id]
    );

    const reserva = rows[0] || null;

    const checks = {
        reserva_aprovada: !!reserva,
        checklist_retirada: !!(reserva && reserva.checklist_retirada),
        dentro_janela: !!(reserva && reserva.dentro_janela),
    };

    const motivos = [];
    if (!checks.reserva_aprovada) {
        motivos.push('Nao ha reserva aprovada (confirmada) para este veiculo.');
    } else {
        if (!checks.checklist_retirada) {
            motivos.push('Check-list de retirada ainda nao foi realizado.');
        }
        if (!checks.dentro_janela) {
            motivos.push('Fora do periodo autorizado da reserva.');
        }
    }

    const liberado =
        checks.reserva_aprovada && checks.checklist_retirada && checks.dentro_janela;

    return {
        encontrado: true,
        placa: normalizarPlaca(placa),
        liberado,
        checks,
        motivos,
        ativo: {
            id: ativo.id,
            codigo_interno: ativo.codigo_interno,
            descricao: ativo.descricao,
            tipo_ativo: ativo.tipo_ativo,
            placa: ativo.placa,
            unidade: ativo.unidade,
            equipe: ativo.equipe,
            status: ativo.status,
            responsavel_nome: ativo.responsavel_nome,
        },
        reserva: reserva
            ? {
                id: reserva.id,
                status: reserva.status,
                data_hora_inicio: reserva.data_hora_inicio,
                data_hora_fim: reserva.data_hora_fim,
                motivo: reserva.motivo,
                usuario_nome: reserva.usuario_nome,
            }
            : null,
    };
}

/** Registra uma movimentacao de portaria (saida ou entrada). */
async function registrarMovimentacao({
    ativo_id, reserva_id, vigilante_id, tipo, placa, liberado, motivo, observacoes,
}) {
    const { rows } = await pool.query(
        `INSERT INTO movimentacoes_portaria
       (ativo_id, reserva_id, vigilante_id, tipo, placa, liberado, motivo, observacoes)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
        [
            ativo_id, reserva_id || null, vigilante_id || null, tipo,
            placa || null, liberado !== false, motivo || null, observacoes || null,
        ]
    );
    return rows[0];
}

/** Lista o historico de movimentacoes de portaria. */
async function listarMovimentacoes({ ativo_id, tipo, limit, offset } = {}) {
    const params = [];
    const where = [];
    if (ativo_id) { params.push(ativo_id); where.push(`m.ativo_id = $${params.length}`); }
    if (tipo) { params.push(tipo); where.push(`m.tipo = $${params.length}`); }

    const whereSql = where.length ? 'WHERE ' + where.join(' AND ') : '';
    const lim = Math.min(Number(limit) || 50, 200);
    const off = Math.max(Number(offset) || 0, 0);

    const { rows } = await pool.query(
        `SELECT m.*,
            a.codigo_interno, a.descricao AS ativo_descricao,
            v.nome_completo AS vigilante_nome
       FROM movimentacoes_portaria m
       JOIN ativos a ON a.id = m.ativo_id
       LEFT JOIN usuarios v ON v.id = m.vigilante_id
       ${whereSql}
      ORDER BY m.criado_em DESC
      LIMIT ${lim} OFFSET ${off}`,
        params
    );
    return rows;
}

module.exports = {
    normalizarPlaca,
    buscarAtivoPorPlaca,
    verificarPorPlaca,
    registrarMovimentacao,
    listarMovimentacoes,
};
