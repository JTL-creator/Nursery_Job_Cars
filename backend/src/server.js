require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const rateLimit = require('express-rate-limit');
const { v4: uuidv4 } = require('uuid');

const routes = require('./routes');
const errorHandler = require('./middlewares/errorHandler');
const logger = require('./utils/logger');

const app = express();

// Segurança e parsing
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

// CORS com allowlist. CORS_ORIGIN aceita uma lista separada por virgula.
// Requisicoes sem cabecalho Origin (apps mobile, curl, health checks) sao
// sempre permitidas; navegadores ficam restritos as origens configuradas.
const corsOrigins = (process.env.CORS_ORIGIN || '*')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);
app.use(cors({
  origin(origin, cb) {
    if (!origin || corsOrigins.includes('*') || corsOrigins.includes(origin)) {
      return cb(null, true);
    }
    return cb(new Error('Origin nao permitida pelo CORS'));
  },
  credentials: true,
}));

app.use(express.json({ limit: '1mb' }));
app.use(morgan('combined'));

// Arquivos enviados (fotos de ativos)
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// trace_id por requisição
app.use((req, res, next) => {
  req.trace_id = req.headers['x-trace-id'] || uuidv4();
  res.setHeader('X-Trace-Id', req.trace_id);
  next();
});

// Rate limit global leve
const limiter = rateLimit({
  windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS || 60000),
  max: Number(process.env.RATE_LIMIT_MAX || 100),
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Rotas
app.use('/api/v1', routes);

// 404
app.use((req, res) => {
  res.status(404).json({
    error_code: 'NOT_FOUND',
    message: 'Recurso não encontrado',
    path: req.path,
    timestamp: new Date().toISOString(),
    trace_id: req.trace_id,
  });
});

// Error handler central
app.use(errorHandler);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  logger.info(`GDM Job Cars API iniciada na porta ${PORT}`, {
    env: process.env.NODE_ENV || 'development',
  });
});
