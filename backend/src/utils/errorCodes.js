/**
 * Códigos de erro padronizados conforme especificação técnica.
 */
module.exports = {
  AUTH_001: { code: 'AUTH_001', http: 401, message: 'Credenciais inválidas' },
  AUTH_002: { code: 'AUTH_002', http: 403, message: 'Usuário inativo' },
  AUTH_003: { code: 'AUTH_003', http: 401, message: 'Token expirado' },
  PERM_001: { code: 'PERM_001', http: 403, message: 'Acesso negado' },
  RES_001: { code: 'RES_001', http: 409, message: 'Conflito de reserva' },
  RES_002: { code: 'RES_002', http: 400, message: 'Período inválido' },
  RES_003: { code: 'RES_003', http: 404, message: 'Reserva inexistente' },
  CHK_001: { code: 'CHK_001', http: 400, message: 'Check-list sem reserva válida' },
  CHK_002: { code: 'CHK_002', http: 404, message: 'Template não encontrado' },
  VAL_001: { code: 'VAL_001', http: 400, message: 'Campo obrigatório ausente' },
  VAL_002: { code: 'VAL_002', http: 400, message: 'Formato inválido' },
  VAL_003: { code: 'VAL_003', http: 400, message: 'Arquivo inválido' },
  LIMIT_FILE_SIZE: { code: 'VAL_003', http: 413, message: 'Arquivo muito grande (máx. 5 MB)' },
  SRV_500: { code: 'SRV_500', http: 500, message: 'Erro interno' },
};
