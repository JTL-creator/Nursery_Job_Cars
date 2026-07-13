const router = require('express').Router();
const ctrl = require('../controllers/portariaController');
const auth = require('../middlewares/authMiddleware');
const { requireRole } = require('../middlewares/rbacMiddleware');

const acessoPortaria = requireRole(['VIGILANTE', 'ADMINISTRADOR']);

router.get('/verificar', auth, acessoPortaria, ctrl.verificar);
router.post('/movimentacoes', auth, acessoPortaria, ctrl.registrar);
router.get('/movimentacoes', auth, acessoPortaria, ctrl.historico);

module.exports = router;
