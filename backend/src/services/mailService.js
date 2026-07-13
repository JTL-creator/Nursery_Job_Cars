/**
 * Servico de e-mail (opcional).
 *
 * O envio so acontece se as variaveis SMTP estiverem configuradas no .env:
 *   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM
 *
 * Enquanto nao estiver configurado, as chamadas apenas registram um log e
 * retornam sem erro (nao quebram o fluxo de reservas).
 */
const logger = require('../utils/logger');

let _transporter = null;
let _tentouCarregar = false;

function getTransporter() {
    if (_tentouCarregar) return _transporter;
    _tentouCarregar = true;

    const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;
    if (!SMTP_HOST) {
        return null; // SMTP nao configurado
    }

    try {
        // require tardio: so exige a dependencia se o SMTP estiver configurado
        // eslint-disable-next-line global-require
        const nodemailer = require('nodemailer');
        _transporter = nodemailer.createTransport({
            host: SMTP_HOST,
            port: Number(SMTP_PORT) || 587,
            secure: Number(SMTP_PORT) === 465,
            auth: SMTP_USER ? { user: SMTP_USER, pass: SMTP_PASS } : undefined,
        });
    } catch (e) {
        logger.warn('nodemailer indisponivel - e-mails desabilitados', { message: e.message });
        _transporter = null;
    }
    return _transporter;
}

async function enviar({ para, assunto, texto, html }) {
    if (!para) return { enviado: false, motivo: 'sem_destinatario' };
    const transporter = getTransporter();
    if (!transporter) {
        logger.info('[MAIL] SMTP nao configurado - e-mail nao enviado', { para, assunto });
        return { enviado: false, motivo: 'smtp_nao_configurado' };
    }
    try {
        await transporter.sendMail({
            from: process.env.SMTP_FROM || process.env.SMTP_USER,
            to: para,
            subject: assunto,
            text: texto,
            html: html || undefined,
        });
        return { enviado: true };
    } catch (e) {
        logger.warn('[MAIL] Falha ao enviar e-mail', { message: e.message });
        return { enviado: false, motivo: e.message };
    }
}

module.exports = { enviar };
