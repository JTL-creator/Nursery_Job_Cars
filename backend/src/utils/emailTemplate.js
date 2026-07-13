/**
 * Template de e-mail HTML com identidade GDM Job Cars.
 */
const NAVY = '#092A3B';
const NAVY2 = '#0E3A52';
const LIME = '#B4BD00';

function escapeHtml(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, (c) => (
        { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]
    ));
}

function linhaDetalhe(label, valor) {
    if (valor == null || valor === '') return '';
    return `<tr>
    <td style="padding:7px 0;color:#9ca3af;font-size:12px;vertical-align:top;width:120px;">${escapeHtml(label)}</td>
    <td style="padding:7px 0;color:#111827;font-size:13px;font-weight:500;">${escapeHtml(valor)}</td>
  </tr>`;
}

/**
 * Monta o HTML do e-mail.
 * @param {Object} opts
 * @param {string} opts.titulo
 * @param {string} opts.mensagem
 * @param {Array<[string,string]>} [opts.detalhes] pares [label, valor]
 * @param {string} [opts.selo] texto do selo (ex.: "AGUARDANDO APROVACAO")
 * @param {string} [opts.acento] cor do selo/acento (hex)
 */
function email({ titulo, mensagem, detalhes = [], selo, acento = LIME }) {
    const detalhesHtml = detalhes.length
        ? `<table role="presentation" width="100%" style="border-top:1px solid #eef0f2;border-bottom:1px solid #eef0f2;margin:8px 0 20px;border-collapse:collapse;">
         ${detalhes.map((d) => linhaDetalhe(d[0], d[1])).join('')}
       </table>`
        : '';

    const seloHtml = selo
        ? `<div style="display:inline-block;padding:5px 12px;border-radius:999px;background:${acento}22;color:${acento};font-size:11px;font-weight:700;letter-spacing:.4px;margin-bottom:16px;">${escapeHtml(selo)}</div>`
        : '';

    return `<!doctype html>
<html lang="pt-BR">
<body style="margin:0;padding:0;background:#f4f6f8;">
  <div style="padding:24px;font-family:'Segoe UI',Roboto,Arial,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin:0 auto;background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #e8eaed;">
      <tr>
        <td style="background:linear-gradient(135deg,${NAVY2},${NAVY});padding:22px 28px;">
          <span style="color:#ffffff;font-size:19px;font-weight:700;letter-spacing:-.2px;">GDM <span style="color:${LIME};">Job Cars</span></span>
        </td>
      </tr>
      <tr>
        <td style="padding:28px;">
          ${seloHtml}
          <h1 style="margin:0 0 8px;color:${NAVY};font-size:20px;font-weight:700;">${escapeHtml(titulo)}</h1>
          <p style="margin:0 0 18px;color:#4b5563;font-size:14px;line-height:1.6;">${escapeHtml(mensagem)}</p>
          ${detalhesHtml}
          <p style="margin:6px 0 0;color:#6b7280;font-size:13px;">Acesse o app <strong>GDM Job Cars</strong> para ver os detalhes e gerenciar a reserva.</p>
        </td>
      </tr>
      <tr>
        <td style="padding:16px 28px;background:#f9fafb;border-top:1px solid #eef0f2;color:#9ca3af;font-size:11px;line-height:1.5;">
          Mensagem automatica do GDM Job Cars. Por favor, nao responda este e-mail.
        </td>
      </tr>
    </table>
  </div>
</body>
</html>`;
}

module.exports = { email };
