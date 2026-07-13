const router = require('express').Router();
const ctrl = require('../controllers/ativosController');
const auth = require('../middlewares/authMiddleware');
const { requireRole } = require('../middlewares/rbacMiddleware');
const validate = require('../middlewares/validateRequest');
const { criarSchema, atualizarSchema, statusSchema } = require('../validators/ativoValidator');
const { uploadImagem } = require('../middlewares/uploadMiddleware');

router.get('/', auth, ctrl.listar);
router.post('/foto', auth, requireRole(['ADMINISTRADOR']), uploadImagem.single('foto'), ctrl.uploadFoto);
router.get('/:id', auth, ctrl.obter);
router.post('/', auth, requireRole(['ADMINISTRADOR']), validate(criarSchema), ctrl.criar);
router.patch('/:id', auth, requireRole(['ADMINISTRADOR']), validate(atualizarSchema), ctrl.atualizar);
router.patch('/:id/status', auth, requireRole(['ADMINISTRADOR']), validate(statusSchema), ctrl.atualizarStatus);
router.delete('/:id', auth, requireRole(['ADMINISTRADOR']), ctrl.excluir);

module.exports = router;
