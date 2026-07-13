const router = require('express').Router();
const ctrl = require('../controllers/cadastroController');
const auth = require('../middlewares/authMiddleware');
const { requireRole } = require('../middlewares/rbacMiddleware');
const validate = require('../middlewares/validateRequest');
const { criarSolicitacaoSchema, rejeitarSchema } = require('../validators/cadastroValidator');

// Público — qualquer um pode solicitar cadastro
router.post('/solicitacoes', validate(criarSolicitacaoSchema), ctrl.criarSolicitacao);

// Administrativo
router.get('/solicitacoes', auth, requireRole(['ADMINISTRADOR']), ctrl.listarSolicitacoes);
router.patch('/solicitacoes/:id/aprovar', auth, requireRole(['ADMINISTRADOR']), ctrl.aprovar);
router.patch('/solicitacoes/:id/rejeitar',
  auth, requireRole(['ADMINISTRADOR']), validate(rejeitarSchema), ctrl.rejeitar);

module.exports = router;
