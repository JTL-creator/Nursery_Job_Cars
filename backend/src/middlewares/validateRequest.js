/**
 * Valida req.body usando schemas Joi.
 */
function validateRequest(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, { abortEarly: false });
    if (error) {
      const e = new Error('Payload inválido');
      e.code = 'VAL_002';
      e.details = error.details.map((d) => d.message);
      return next(e);
    }
    req.body = value;
    next();
  };
}

module.exports = validateRequest;
