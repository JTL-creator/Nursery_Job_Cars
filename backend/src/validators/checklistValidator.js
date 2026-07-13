const Joi = require('joi');

const itemSchema = Joi.object({
  chave_item: Joi.string().max(80).required(),
  descricao_item: Joi.string().max(255).allow('', null),
  valor_texto: Joi.string().allow('', null),
  valor_numero: Joi.number().allow(null),
  valor_booleano: Joi.boolean().allow(null),
  obrigatorio: Joi.boolean(),
  ordem: Joi.number().integer(),
});

const criarChecklistSchema = Joi.object({
  etapa: Joi.string().valid('RETIRADA', 'DEVOLUCAO').required(),
  local: Joi.string().max(120).allow('', null),
  responsavel: Joi.string().max(200).allow('', null),
  observacoes: Joi.string().max(2000).allow('', null),
  itens: Joi.array().items(itemSchema).min(1).required(),
});

const tiposCampo = ['texto', 'numero', 'booleano', 'selecao', 'data', 'observacao'];

const templateItemSchema = Joi.object({
  chave_item: Joi.string().max(80).allow('', null),
  descricao: Joi.string().min(1).max(255).required(),
  tipo_campo: Joi.string().valid(...tiposCampo).required(),
  obrigatorio: Joi.boolean(),
  ordem: Joi.number().integer(),
  opcoes: Joi.array().items(Joi.string().max(120)).allow(null),
});

const criarTemplateSchema = Joi.object({
  tipo_ativo: Joi.string().valid('VEICULO', 'MAQUINA_AGRICOLA', 'IMPLEMENTO').required(),
  etapa: Joi.string().valid('RETIRADA', 'DEVOLUCAO').required(),
  nome: Joi.string().min(1).max(120).required(),
  itens: Joi.array().items(templateItemSchema).min(1).required(),
});

const atualizarTemplateSchema = Joi.object({
  tipo_ativo: Joi.string().valid('VEICULO', 'MAQUINA_AGRICOLA', 'IMPLEMENTO'),
  etapa: Joi.string().valid('RETIRADA', 'DEVOLUCAO'),
  nome: Joi.string().min(1).max(120),
  itens: Joi.array().items(templateItemSchema).min(1),
}).min(1);

module.exports = {
  criarChecklistSchema, criarTemplateSchema, atualizarTemplateSchema,
};
