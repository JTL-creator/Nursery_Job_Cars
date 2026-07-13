const notificacaoService = require('../services/notificacaoService');

async function listar(req, res, next) {
    try {
        const list = await notificacaoService.listar({
            usuario_id: req.user.sub,
            apenasNaoLidas: req.query.nao_lidas === 'true',
            limit: req.query.limit,
            offset: req.query.offset,
        });
        const naoLidas = await notificacaoService.contarNaoLidas(req.user.sub);
        res.json({ data: list, meta: { total: list.length, nao_lidas: naoLidas } });
    } catch (e) { next(e); }
}

async function naoLidas(req, res, next) {
    try {
        const total = await notificacaoService.contarNaoLidas(req.user.sub);
        res.json({ data: { nao_lidas: total } });
    } catch (e) { next(e); }
}

async function marcarLida(req, res, next) {
    try {
        const n = await notificacaoService.marcarLida(req.params.id, req.user.sub);
        if (!n) { const e = new Error('Notificacao nao encontrada'); e.code = 'VAL_001'; throw e; }
        res.json({ data: n, message: 'Notificacao marcada como lida' });
    } catch (e) { next(e); }
}

async function marcarTodasLidas(req, res, next) {
    try {
        await notificacaoService.marcarTodasLidas(req.user.sub);
        res.json({ data: null, message: 'Todas marcadas como lidas' });
    } catch (e) { next(e); }
}

module.exports = { listar, naoLidas, marcarLida, marcarTodasLidas };
