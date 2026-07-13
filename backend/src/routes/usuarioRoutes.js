const router = require('express').Router();
const ctrl = require('../controllers/usuarioController');
const auth = require('../middlewares/authMiddleware');
const { requireRole } = require('../middlewares/rbacMiddleware');
const checklistCtrl = require('../controllers/checklistController');
const validate = require('../middlewares/validateRequest');
const { criarChecklistSchema } = require('../validators/checklistValidator');
const usuarioValidator = require('../validators/usuarioValidator');

const ADMIN = ['ADMINISTRADOR'];
const ADMIN_GER = ['ADMINISTRADOR', 'GERENTE'];

// Perfil do proprio usuario
router.get('/me', auth, ctrl.me);
router.get('/me/reservas', auth, ctrl.minhasReservas);
router.get('/me/checklists', auth, ctrl.minhasChecklists);
router.get('/me/reservas/:id/checklists/template', auth, checklistCtrl.obterTemplate);
router.post('/me/reservas/:id/checklists', auth, validate(criarChecklistSchema), checklistCtrl.criar);

// Perfis disponiveis (para os selects de administracao)
router.get('/perfis', auth, requireRole(ADMIN_GER), ctrl.listarPerfis);

// Administracao de usuarios
router.get('/', auth, requireRole(ADMIN_GER), ctrl.listar);
router.get('/:id', auth, requireRole(ADMIN_GER), ctrl.obter);
router.post('/', auth, requireRole(ADMIN), validate(usuarioValidator.criarSchema), ctrl.criar);
router.patch('/:id', auth, requireRole(ADMIN), validate(usuarioValidator.atualizarSchema), ctrl.atualizar);
router.patch('/:id/status', auth, requireRole(ADMIN), validate(usuarioValidator.statusSchema), ctrl.alterarStatus);
router.post('/:id/redefinir-senha', auth, requireRole(ADMIN), validate(usuarioValidator.senhaSchema), ctrl.redefinirSenha);

module.exports = router;
