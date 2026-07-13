const router = require('express').Router();
const ctrl = require('../controllers/notificacaoController');
const auth = require('../middlewares/authMiddleware');

router.get('/', auth, ctrl.listar);
router.get('/nao-lidas', auth, ctrl.naoLidas);
router.patch('/ler-todas', auth, ctrl.marcarTodasLidas);
router.patch('/:id/lida', auth, ctrl.marcarLida);

module.exports = router;
