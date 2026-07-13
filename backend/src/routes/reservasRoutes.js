const router = require('express').Router();
const ctrl = require('../controllers/reservasController');
const auth = require('../middlewares/authMiddleware');
const { requireRole } = require('../middlewares/rbacMiddleware');
const validate = require('../middlewares/validateRequest');
const { criarReservaSchema } = require('../validators/reservaValidator');

router.get('/disponibilidade', auth, ctrl.disponibilidade);
router.get('/aprovacoes-pendentes', auth,
    requireRole(['ADMINISTRADOR', 'GERENTE', 'RESPONSAVEL']), ctrl.aprovacoesPendentes);
router.get('/', auth, requireRole(['ADMINISTRADOR', 'GERENTE']), ctrl.listarTodas);
router.post('/', auth, validate(criarReservaSchema), ctrl.criar);
router.get('/:id', auth, ctrl.obter);
router.patch('/:id/confirmar', auth, requireRole(['ADMINISTRADOR']), ctrl.confirmar);
router.patch('/:id/aprovar', auth,
    requireRole(['ADMINISTRADOR', 'GERENTE', 'RESPONSAVEL']), ctrl.aprovar);
router.patch('/:id/rejeitar', auth,
    requireRole(['ADMINISTRADOR', 'GERENTE', 'RESPONSAVEL']), ctrl.rejeitar);
router.patch('/:id/iniciar-uso', auth, ctrl.iniciar);
router.patch('/:id/concluir', auth, ctrl.concluir);
router.patch('/:id/cancelar', auth, ctrl.cancelar);

module.exports = router;
