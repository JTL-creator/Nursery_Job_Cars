const portariaService = require('../services/portariaService');
const { registrarEvento } = require('../middlewares/auditMiddleware');

async function verificar(req, res, next) {
    try {
        const placa = req.query.placa;
        if (!placa || !String(placa).trim()) {
            const err = new Error('Placa nao informada'); err.code = 'VAL_003';
            return next(err);
        }
        const resultado = await portariaService.verificarPorPlaca(placa);
        res.json({ data: resultado });
    } catch (e) { next(e); }
}

async function registrar(req, res, next) {
    try {
        const { ativo_id, reserva_id, tipo, placa, liberado, motivo, observacoes } = req.body;
        if (!ativo_id) {
            const err = new Error('Ativo nao informado'); err.code = 'VAL_003';
            return next(err);
        }
        if (!['SAIDA', 'ENTRADA'].includes(tipo)) {
            const err = new Error('Tipo invalido (use SAIDA ou ENTRADA)'); err.code = 'VAL_002';
            return next(err);
        }
        const mov = await portariaService.registrarMovimentacao({
            ativo_id, reserva_id, vigilante_id: req.user.sub,
            tipo, placa, liberado, motivo, observacoes,
        });
        await registrarEvento({
            usuario_id: req.user.sub,
            entidade: 'movimentacoes_portaria', entidade_id: mov.id,
            acao: tipo === 'SAIDA' ? 'REGISTRAR_SAIDA_PORTARIA' : 'REGISTRAR_ENTRADA_PORTARIA',
            depois: mov,
            ip: req.ip, user_agent: req.headers['user-agent'],
        });
        res.status(201).json({ data: mov, message: 'Movimentacao registrada' });
    } catch (e) { next(e); }
}

async function historico(req, res, next) {
    try {
        const dados = await portariaService.listarMovimentacoes(req.query);
        res.json({ data: dados });
    } catch (e) { next(e); }
}

module.exports = { verificar, registrar, historico };
