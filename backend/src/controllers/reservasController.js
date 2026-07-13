const pool = require('../config/database');
const reservaService = require('../services/reservaService');
const notificacaoService = require('../services/notificacaoService');
const mailService = require('../services/mailService');
const emailTemplate = require('../utils/emailTemplate');
const { registrarEvento } = require('../middlewares/auditMiddleware');

function fmtPeriodo(reserva) {
  try {
    const ini = new Date(reserva.data_hora_inicio).toLocaleString('pt-BR');
    const fim = new Date(reserva.data_hora_fim).toLocaleString('pt-BR');
    return `${ini} ate ${fim}`;
  } catch (_) { return ''; }
}

async function notificarResponsavel(responsavelId, reservaId) {
  const full = await reservaService.obterReserva(reservaId);
  if (!full) return;
  const titulo = 'Nova reserva aguardando aprovacao';
  const mensagem =
    `${full.usuario_nome} solicitou ${full.codigo_interno} - ${full.ativo_descricao} (${fmtPeriodo(full)})`;
  try {
    await notificacaoService.criar({
      usuario_id: responsavelId,
      tipo: 'APROVACAO_RESERVA',
      titulo, mensagem,
      entidade: 'reservas', entidade_id: reservaId,
    });
  } catch (_) { /* nao bloqueia */ }
  try {
    const { rows } = await pool.query(
      'SELECT email FROM usuarios WHERE id = $1', [responsavelId]
    );
    if (rows[0] && rows[0].email) {
      const html = emailTemplate.email({
        titulo: 'Nova reserva aguardando aprovacao',
        mensagem: `${full.usuario_nome} solicitou uma reserva que precisa da sua aprovacao.`,
        selo: 'AGUARDANDO APROVACAO',
        acento: '#B4BD00',
        detalhes: [
          ['Ativo', `${full.codigo_interno} - ${full.ativo_descricao}`],
          ['Solicitante', full.usuario_nome],
          ['Periodo', fmtPeriodo(full)],
          ['Motivo', full.motivo],
        ],
      });
      await mailService.enviar({
        para: rows[0].email,
        assunto: titulo,
        texto: `${mensagem}\n\nAcesse o app GDM Job Cars para aprovar ou rejeitar.`,
        html,
      });
    }
  } catch (_) { /* best-effort */ }
}

async function notificarSolicitante(usuarioId, reservaId, aprovada, motivo) {
  const full = await reservaService.obterReserva(reservaId);
  if (!full) return;
  const titulo = aprovada ? 'Reserva aprovada' : 'Reserva rejeitada';
  const mensagem =
    `${full.codigo_interno} - ${full.ativo_descricao} foi ${aprovada ? 'aprovada' : 'rejeitada'}` +
    (!aprovada && motivo ? `: ${motivo}` : '');
  try {
    await notificacaoService.criar({
      usuario_id: usuarioId,
      tipo: aprovada ? 'RESERVA_APROVADA' : 'RESERVA_REJEITADA',
      titulo, mensagem,
      entidade: 'reservas', entidade_id: reservaId,
    });
  } catch (_) { /* nao bloqueia */ }
  try {
    const { rows } = await pool.query(
      'SELECT email FROM usuarios WHERE id = $1', [usuarioId]
    );
    if (rows[0] && rows[0].email) {
      const html = emailTemplate.email({
        titulo,
        mensagem: aprovada
          ? 'Sua reserva foi aprovada pelo responsavel. Ja pode utilizar o ativo no periodo reservado.'
          : 'Sua reserva foi rejeitada pelo responsavel.',
        selo: aprovada ? 'APROVADA' : 'REJEITADA',
        acento: aprovada ? '#16A34A' : '#EA580C',
        detalhes: [
          ['Ativo', `${full.codigo_interno} - ${full.ativo_descricao}`],
          ['Periodo', fmtPeriodo(full)],
          ['Motivo da rejeicao', !aprovada ? motivo : null],
        ],
      });
      await mailService.enviar({ para: rows[0].email, assunto: titulo, texto: mensagem, html });
    }
  } catch (_) { /* best-effort */ }
}

function validarPeriodo(inicio, fim) {
  const ini = new Date(inicio);
  const f = new Date(fim);
  if (isNaN(ini) || isNaN(f)) {
    const e = new Error('Datas invalidas'); e.code = 'RES_002'; throw e;
  }
  if (f <= ini) {
    const e = new Error('Fim deve ser maior que inicio'); e.code = 'RES_002'; throw e;
  }
  const horas = (f - ini) / 1000 / 60 / 60;
  if (horas < 1) {
    const e = new Error('Periodo minimo: 1 hora'); e.code = 'RES_002'; throw e;
  }
  if (horas > 24 * 30) {
    const e = new Error('Periodo maximo: 30 dias'); e.code = 'RES_002'; throw e;
  }
}

async function disponibilidade(req, res, next) {
  try {
    const { inicio, fim, tipo_ativo, categoria, unidade } = req.query;
    if (!inicio || !fim) {
      const e = new Error('inicio e fim sao obrigatorios'); e.code = 'VAL_001'; throw e;
    }
    validarPeriodo(inicio, fim);
    const ativos = await reservaService.listarDisponibilidade({
      inicio, fim, tipo_ativo, categoria, unidade,
    });
    res.json({ data: ativos, meta: { total: ativos.length } });
  } catch (e) { next(e); }
}

async function criar(req, res, next) {
  try {
    const { ativo_id, data_hora_inicio, data_hora_fim, motivo, observacoes } = req.body;
    validarPeriodo(data_hora_inicio, data_hora_fim);

    const { reserva, responsavel_id } = await reservaService.criarReservaTransacional({
      usuario_id: req.user.sub,
      ativo_id, data_hora_inicio, data_hora_fim, motivo, observacoes,
    });

    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'reservas', entidade_id: reserva.id,
      acao: 'CRIAR_RESERVA', depois: reserva,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });

    const pendente = reserva.status === 'PENDENTE';
    if (pendente && responsavel_id) {
      await notificarResponsavel(responsavel_id, reserva.id);
    }

    res.status(201).json({
      data: reserva,
      message: pendente
        ? 'Reserva registrada. Aguardando aprovacao do responsavel.'
        : 'Reserva confirmada',
    });
  } catch (e) { next(e); }
}

async function obter(req, res, next) {
  try {
    const r = await reservaService.obterReserva(req.params.id);
    if (!r) {
      const e = new Error('Reserva nao encontrada'); e.code = 'RES_003'; throw e;
    }
    const isAdmin = req.user.perfil === 'ADMINISTRADOR' || req.user.perfil === 'GERENTE';
    if (!isAdmin && r.usuario_id !== req.user.sub) {
      const e = new Error('Acesso negado'); e.code = 'PERM_001'; throw e;
    }
    res.json({ data: r });
  } catch (e) { next(e); }
}

async function minhasReservas(req, res, next) {
  try {
    const list = await reservaService.listarReservas({
      usuario_id: req.user.sub,
      status: req.query.status,
      limit: req.query.limit,
      offset: req.query.offset,
    });
    res.json({ data: list, meta: { total: list.length } });
  } catch (e) { next(e); }
}

async function listarTodas(req, res, next) {
  try {
    const list = await reservaService.listarReservas({
      status: req.query.status,
      limit: req.query.limit,
      offset: req.query.offset,
    });
    res.json({ data: list, meta: { total: list.length } });
  } catch (e) { next(e); }
}

async function aprovacoesPendentes(req, res, next) {
  try {
    const isAdmin = req.user.perfil === 'ADMINISTRADOR' || req.user.perfil === 'GERENTE';
    const list = await reservaService.listarAprovacoesPendentes({
      responsavel_id: req.user.sub,
      todos: isAdmin,
    });
    res.json({ data: list, meta: { total: list.length } });
  } catch (e) { next(e); }
}

function podeAprovar(user, reserva) {
  const isAdmin = user.perfil === 'ADMINISTRADOR' || user.perfil === 'GERENTE';
  const isResponsavel = reserva.responsavel_id && reserva.responsavel_id === user.sub;
  return isAdmin || isResponsavel;
}

async function aprovar(req, res, next) {
  try {
    const r = await reservaService.obterReserva(req.params.id);
    if (!r) { const e = new Error('Reserva nao encontrada'); e.code = 'RES_003'; throw e; }
    if (!podeAprovar(req.user, r)) {
      const e = new Error('Acesso negado'); e.code = 'PERM_001'; throw e;
    }
    if (r.status !== 'PENDENTE') {
      const e = new Error(`Status atual (${r.status}) nao permite aprovacao`);
      e.code = 'VAL_002'; throw e;
    }

    const upd = await reservaService.aprovarReserva(req.params.id, req.user.sub);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'reservas', entidade_id: req.params.id,
      acao: 'APROVAR_RESERVA', antes: r, depois: upd,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    await notificarSolicitante(r.usuario_id, req.params.id, true);

    res.json({ data: upd, message: 'Reserva aprovada' });
  } catch (e) { next(e); }
}

async function rejeitar(req, res, next) {
  try {
    const r = await reservaService.obterReserva(req.params.id);
    if (!r) { const e = new Error('Reserva nao encontrada'); e.code = 'RES_003'; throw e; }
    if (!podeAprovar(req.user, r)) {
      const e = new Error('Acesso negado'); e.code = 'PERM_001'; throw e;
    }
    if (r.status !== 'PENDENTE') {
      const e = new Error(`Status atual (${r.status}) nao permite rejeicao`);
      e.code = 'VAL_002'; throw e;
    }

    const motivo = (req.body && req.body.motivo) || null;
    const upd = await reservaService.rejeitarReserva(req.params.id, req.user.sub, motivo);
    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'reservas', entidade_id: req.params.id,
      acao: 'REJEITAR_RESERVA', antes: r, depois: upd,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });
    await notificarSolicitante(r.usuario_id, req.params.id, false, motivo);

    res.json({ data: upd, message: 'Reserva rejeitada' });
  } catch (e) { next(e); }
}

async function _mudarStatus(req, res, next, novoStatus, statusEsperados, acao, camposExtras = {}) {
  try {
    const r = await reservaService.obterReserva(req.params.id);
    if (!r) { const e = new Error('Reserva nao encontrada'); e.code = 'RES_003'; throw e; }

    const isAdmin = req.user.perfil === 'ADMINISTRADOR' || req.user.perfil === 'GERENTE';
    if (!isAdmin && r.usuario_id !== req.user.sub) {
      const e = new Error('Acesso negado'); e.code = 'PERM_001'; throw e;
    }
    if (!statusEsperados.includes(r.status)) {
      const e = new Error(`Status atual (${r.status}) nao permite essa acao`);
      e.code = 'VAL_002'; throw e;
    }

    const upd = await reservaService.atualizarStatus(req.params.id, novoStatus, camposExtras);

    await registrarEvento({
      usuario_id: req.user.sub,
      entidade: 'reservas', entidade_id: req.params.id,
      acao, antes: r, depois: upd,
      ip: req.ip, user_agent: req.headers['user-agent'],
    });

    res.json({ data: upd, message: 'Reserva atualizada' });
  } catch (e) { next(e); }
}

const confirmar = (req, res, next) =>
  _mudarStatus(req, res, next, 'CONFIRMADA', ['PENDENTE'], 'CONFIRMAR_RESERVA',
    { confirmado_em: new Date() });

const iniciar = (req, res, next) =>
  _mudarStatus(req, res, next, 'EM_USO', ['CONFIRMADA'], 'INICIAR_RESERVA');

const concluir = (req, res, next) =>
  _mudarStatus(req, res, next, 'CONCLUIDA', ['EM_USO'], 'CONCLUIR_RESERVA');

const cancelar = (req, res, next) =>
  _mudarStatus(req, res, next, 'CANCELADA',
    ['PENDENTE', 'CONFIRMADA'], 'CANCELAR_RESERVA',
    { cancelado_em: new Date() });

module.exports = {
  disponibilidade, criar, obter, minhasReservas, listarTodas,
  aprovacoesPendentes, aprovar, rejeitar,
  confirmar, iniciar, concluir, cancelar,
};
