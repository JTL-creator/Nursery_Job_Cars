const router = require('express').Router();
const ctrl = require('../controllers/checklistController');
const auth = require('../middlewares/authMiddleware');
const { requireRole } = require('../middlewares/rbacMiddleware');
const validate = require('../middlewares/validateRequest');
const {
    criarTemplateSchema, atualizarTemplateSchema,
} = require('../validators/checklistValidator');

const ADMIN = ['ADMINISTRADOR'];

// Templates de check-list
router.get('/templates', auth, ctrl.listarTemplates);
router.post('/templates', auth, requireRole(ADMIN), validate(criarTemplateSchema), ctrl.criarTemplate);
router.get('/templates/:id', auth, requireRole(ADMIN), ctrl.obterTemplatePorId);
router.patch('/templates/:id', auth, requireRole(ADMIN), validate(atualizarTemplateSchema), ctrl.atualizarTemplate);
router.delete('/templates/:id', auth, requireRole(ADMIN), ctrl.excluirTemplate);

router.get('/:id', auth, ctrl.obter);

module.exports = router;
