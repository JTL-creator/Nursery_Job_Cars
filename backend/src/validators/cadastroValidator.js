const Joi = require('joi');

const criarSolicitacaoSchema = Joi.object({
  nome_completo:   Joi.string().min(3).max(200).required(),
  matricula:       Joi.string().min(1).max(50).required(),
  email:           Joi.string().email().required(),
  telefone:        Joi.string().max(30).allow('', null),
  unidade_lotacao: Joi.string().max(120).allow('', null),
  justificativa:   Joi.string().max(1000).allow('', null),
});

const rejeitarSchema = Joi.object({
  observacao_rejeicao: Joi.string().min(3).max(1000).required(),
});

module.exports = { criarSolicitacaoSchema, rejeitarSchema };
