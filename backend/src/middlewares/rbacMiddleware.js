/**
 * Controle de acesso baseado em perfil (RBAC).
 * Uso: router.get('/rota', auth, requireRole(['ADMINISTRADOR']), handler)
 */
function requireRole(allowed = []) {
  return (req, res, next) => {
    const perfil = req.user && req.user.perfil;
    if (!perfil || !allowed.includes(perfil)) {
      const err = new Error('Acesso negado');
      err.code = 'PERM_001';
      return next(err);
    }
    next();
  };
}

module.exports = { requireRole };
