/**
 * Middleware central de tratamento de erros.
 * Retorna payload padronizado conforme spec.
 */
const { v4: uuidv4 } = require('uuid');
const codes = require('../utils/errorCodes');
const logger = require('../utils/logger');

function errorHandler(err, req, res, next) {
  const trace_id = req.trace_id || uuidv4();
  const fallback = codes.SRV_500;

  // Se o erro for um código conhecido
  if (err && err.code && codes[err.code]) {
    const def = codes[err.code];
    logger.warn('Erro tratado', { trace_id, code: def.code, path: req.path });
    return res.status(def.http).json({
      error_code: def.code,
      message: def.message,
      details: err.details || null,
      timestamp: new Date().toISOString(),
      trace_id,
    });
  }

  logger.error('Erro não tratado', {
    trace_id, message: err.message, stack: err.stack, path: req.path,
  });

  return res.status(fallback.http).json({
    error_code: fallback.code,
    message: fallback.message,
    details: process.env.NODE_ENV === 'development' ? err.message : null,
    timestamp: new Date().toISOString(),
    trace_id,
  });
}

module.exports = errorHandler;
