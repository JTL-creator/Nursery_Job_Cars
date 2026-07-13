const Joi = require('joi');

const criarReservaSchema = Joi.object({
  ativo_id: Joi.string().uuid().required(),
  data_hora_inicio: Joi.string().isoDate().required(),
  data_hora_fim: Joi.string().isoDate().required(),
  motivo: Joi.string().max(255).allow('', null),
  observacoes: Joi.string().max(1000).allow('', null),
});

module.exports = { criarReservaSchema };
