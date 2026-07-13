/**
 * Logger estruturado simples (JSON).
 */
function log(level, message, extra = {}) {
  const entry = {
    timestamp: new Date().toISOString(),
    level,
    message,
    ...extra,
  };
  // eslint-disable-next-line no-console
  console.log(JSON.stringify(entry));
}

module.exports = {
  debug: (m, e) => log('debug', m, e),
  info:  (m, e) => log('info', m, e),
  warn:  (m, e) => log('warn', m, e),
  error: (m, e) => log('error', m, e),
};
