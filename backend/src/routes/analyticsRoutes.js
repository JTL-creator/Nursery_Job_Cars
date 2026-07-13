const router = require('express').Router();
const ctrl = require('../controllers/analyticsController');
const auth = require('../middlewares/authMiddleware');
const { requireRole } = require('../middlewares/rbacMiddleware');

router.use(auth, requireRole(['ADMINISTRADOR', 'GERENTE']));

router.get('/resumo', ctrl.resumo);
router.get('/uso-por-ativo', ctrl.usoPorAtivo);
router.get('/ocorrencias', ctrl.ocorrencias);

module.exports = router;
