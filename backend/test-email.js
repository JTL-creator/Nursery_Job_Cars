/**
 * test-email.js
 * ----------------------------------------------
 * Envia um e-mail de teste usando as credenciais SMTP do .env.
 *
 * Uso: node test-email.js destinatario@dominio.com
 *
 * Se o SMTP nao estiver configurado (SMTP_HOST vazio), o script avisa.
 */
require('dotenv').config();
const mail = require('./src/services/mailService');
const emailTemplate = require('./src/utils/emailTemplate');

(async () => {
    const to = process.argv[2];
    if (!to) {
        console.log('Uso: node test-email.js destinatario@dominio.com');
        process.exit(1);
    }
    if (!process.env.SMTP_HOST) {
        console.log('[AVISO] SMTP_HOST esta vazio no .env. Preencha as variaveis SMTP_* antes de testar.');
        process.exit(1);
    }

    console.log(`Enviando e-mail de teste para ${to} via ${process.env.SMTP_HOST}...`);
    const html = emailTemplate.email({
        titulo: 'Configuracao de e-mail concluida',
        mensagem: 'Se voce recebeu esta mensagem, o SMTP do GDM Job Cars esta configurado corretamente.',
        selo: 'TESTE',
        acento: '#16A34A',
        detalhes: [
            ['Servidor', process.env.SMTP_HOST],
            ['Porta', process.env.SMTP_PORT || '587'],
            ['Remetente', process.env.SMTP_FROM || process.env.SMTP_USER],
        ],
    });
    const r = await mail.enviar({
        para: to,
        assunto: 'Teste GDM Job Cars',
        texto:
            'Este e um e-mail de teste do GDM Job Cars.\n\n' +
            'Se voce recebeu esta mensagem, o SMTP esta configurado corretamente.',
        html,
    });

    if (r.enviado) {
        console.log('[OK] E-mail enviado com sucesso!');
    } else {
        console.log('[FALHA] Nao foi possivel enviar. Motivo:', r.motivo);
    }
    process.exit(0);
})();
