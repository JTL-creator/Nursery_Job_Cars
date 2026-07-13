const router = require('express').Router();

router.use('/auth', require('./authRoutes'));
router.use('/cadastros', require('./cadastroRoutes'));
router.use('/usuarios', require('./usuarioRoutes'));
router.use('/ativos', require('./ativosRoutes'));
router.use('/reservas', require('./reservasRoutes'));
router.use('/checklists', require('./checklistRoutes'));
router.use('/notificacoes', require('./notificacaoRoutes'));
router.use('/analytics', require('./analyticsRoutes'));
router.use('/portaria', require('./portariaRoutes'));

router.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

module.exports = router;
