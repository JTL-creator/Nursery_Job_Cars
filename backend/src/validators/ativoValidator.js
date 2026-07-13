const Joi = require('joi');

const tipoAtivo = ['VEICULO', 'MAQUINA_AGRICOLA', 'IMPLEMENTO'];
const statusAtivo = ['DISPONIVEL', 'RESERVADO', 'INDISPONIVEL', 'MANUTENCAO'];

const criarSchema = Joi.object({
  codigo_interno: Joi.string().min(1).max(50).required(),
  descricao: Joi.string().min(1).max(255).required(),
  tipo_ativo: Joi.string().valid(...tipoAtivo).required(),
  sub_tipo: Joi.string().max(60).allow('', null),
  placa: Joi.string().max(15).allow('', null),
  patrimonio: Joi.string().max(50).allow('', null),
  unidade: Joi.string().max(120).allow('', null),
  status: Joi.string().valid(...statusAtivo),
  observacoes: Joi.string().max(1000).allow('', null),
  responsavel_id: Joi.string().uuid().allow('', null),
  equipe: Joi.string().max(80).allow('', null),
  foto_url: Joi.string().max(500).allow('', null),
});

const atualizarSchema = Joi.object({
  codigo_interno: Joi.string().max(50),
  descricao: Joi.string().max(255),
  tipo_ativo: Joi.string().valid(...tipoAtivo),
  sub_tipo: Joi.string().max(60).allow('', null),
  placa: Joi.string().max(15).allow('', null),
  patrimonio: Joi.string().max(50).allow('', null),
  unidade: Joi.string().max(120).allow('', null),
  observacoes: Joi.string().max(1000).allow('', null),
  responsavel_id: Joi.string().uuid().allow('', null),
  equipe: Joi.string().max(80).allow('', null),
  foto_url: Joi.string().max(500).allow('', null),
}).min(1);

const statusSchema = Joi.object({
  status: Joi.string().valid(...statusAtivo).required(),
});

module.exports = { criarSchema, atualizarSchema, statusSchema };
