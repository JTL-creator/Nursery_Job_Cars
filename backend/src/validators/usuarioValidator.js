const Joi = require('joi');

const perfis = ['USUARIO', 'ADMINISTRADOR', 'GERENTE', 'RESPONSAVEL', 'VIGILANTE'];
const status = ['ATIVO', 'INATIVO', 'BLOQUEADO'];

const criarSchema = Joi.object({
    nome_completo: Joi.string().min(2).max(200).required(),
    matricula: Joi.string().min(1).max(50).required(),
    email: Joi.string().email().max(200).required(),
    telefone: Joi.string().max(30).allow('', null),
    unidade_lotacao: Joi.string().max(120).allow('', null),
    perfil: Joi.string().valid(...perfis).required(),
    status: Joi.string().valid(...status),
    senha: Joi.string().min(6).max(100).allow('', null),
});

const atualizarSchema = Joi.object({
    nome_completo: Joi.string().min(2).max(200),
    matricula: Joi.string().min(1).max(50),
    email: Joi.string().email().max(200),
    telefone: Joi.string().max(30).allow('', null),
    unidade_lotacao: Joi.string().max(120).allow('', null),
    perfil: Joi.string().valid(...perfis),
}).min(1);

const statusSchema = Joi.object({
    status: Joi.string().valid(...status).required(),
});

const senhaSchema = Joi.object({
    senha: Joi.string().min(6).max(100).allow('', null),
});

module.exports = { criarSchema, atualizarSchema, statusSchema, senhaSchema };
