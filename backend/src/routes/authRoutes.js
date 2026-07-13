const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const ctrl = require('../controllers/authController');
const auth = require('../middlewares/authMiddleware');
const validate = require('../middlewares/validateRequest');
const { loginSchema, refreshSchema } = require('../validators/authValidator');

// Rate limit dedicado ao login (anti força-bruta).
// Conta apenas tentativas malsucedidas (skipSuccessfulRequests).
const loginLimiter = rateLimit({
    windowMs: Number(process.env.LOGIN_RATE_WINDOW_MS || 15 * 60 * 1000), // 15 min
    max: Number(process.env.LOGIN_RATE_MAX || 10),
    skipSuccessfulRequests: true,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        error_code: 'AUTH_429',
        message: 'Muitas tentativas de login. Tente novamente em alguns minutos.',
    },
});

router.post('/login', loginLimiter, validate(loginSchema), ctrl.login);
router.post('/refresh', validate(refreshSchema), ctrl.refresh);
router.post('/logout', auth, ctrl.logout);

module.exports = router;
