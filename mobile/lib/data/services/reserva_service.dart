import 'dart:convert';

import '../models/reserva.dart';
import '../../core/network/api_client.dart';
import '../../core/services/reserva_notifications.dart';
import '../../core/storage/offline_cache_service.dart';
import '../../core/storage/secure_storage_service.dart';

class ReservaService {
  static final _dio = ApiClient().dio;

  // ===== Helpers de cache / offline =====

  static Reserva _fromCache(Map<String, dynamic> m) =>
      Reserva.fromJson(Map<String, dynamic>.from(m));

  static Map<String, dynamic>? _ativoCache(String ativoId) {
    for (final a in OfflineCacheService.getAtivosCache()) {
      if (a['id']?.toString() == ativoId) return Map<String, dynamic>.from(a);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _usuarioAtual() async {
    final raw = await SecureStorageService.getUser();
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static Future<void> _cacheStatus(String id, String status,
      {DateTime? canceladoEm, DateTime? confirmadoEm}) async {
    final atual = OfflineCacheService.getReservaCacheById(id);
    if (atual == null) return;
    atual['status'] = status;
    if (canceladoEm != null) {
      atual['cancelado_em'] = canceladoEm.toIso8601String();
    }
    if (confirmadoEm != null) {
      atual['confirmado_em'] = confirmadoEm.toIso8601String();
    }
    await OfflineCacheService.upsertReservaCache(atual);
  }

  // ===== Operacoes =====

  static Future<Reserva> criar({
    required String ativoId,
    required DateTime inicio,
    required DateTime fim,
    String? motivo,
    String? observacoes,
  }) async {
    try {
      final resp = await _dio.post('/reservas', data: {
        'ativo_id': ativoId,
        'data_hora_inicio': inicio.toUtc().toIso8601String(),
        'data_hora_fim': fim.toUtc().toIso8601String(),
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
        if (observacoes != null && observacoes.isNotEmpty)
          'observacoes': observacoes,
      });
      final reserva =
          Reserva.fromJson(Map<String, dynamic>.from(resp.data['data'] as Map));

      await OfflineCacheService.upsertReservaCache(_reservaToMap(reserva));
      await ReservaNotifications.agendarParaReserva(reserva);
      return reserva;
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      return _criarOffline(
        ativoId: ativoId,
        inicio: inicio,
        fim: fim,
        motivo: motivo,
        observacoes: observacoes,
      );
    }
  }

  /// Cria a reserva localmente (status PENDENTE) e enfileira o envio.
  static Future<Reserva> _criarOffline({
    required String ativoId,
    required DateTime inicio,
    required DateTime fim,
    String? motivo,
    String? observacoes,
  }) async {
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final user = await _usuarioAtual();
    final ativo = _ativoCache(ativoId);

    final map = <String, dynamic>{
      'id': localId,
      'usuario_id': user?['id']?.toString() ?? '',
      'usuario_nome': user?['nome_completo']?.toString(),
      'ativo_id': ativoId,
      'data_hora_inicio': inicio.toUtc().toIso8601String(),
      'data_hora_fim': fim.toUtc().toIso8601String(),
      'status': 'PENDENTE',
      'motivo': motivo,
      'observacoes': observacoes,
      'criado_em': DateTime.now().toIso8601String(),
      'codigo_interno': ativo?['codigo_interno']?.toString(),
      'ativo_descricao': ativo?['descricao']?.toString(),
      'tipo_ativo': ativo?['tipo_ativo']?.toString(),
      'placa': ativo?['placa']?.toString(),
      'pendente_sync': true,
    };

    await OfflineCacheService.upsertReservaCache(map);
    await OfflineCacheService.enqueueOutbox(
      entidade: 'reserva',
      operacao: 'criar',
      refId: localId,
      payload: {
        'ativo_id': ativoId,
        'data_hora_inicio': inicio.toUtc().toIso8601String(),
        'data_hora_fim': fim.toUtc().toIso8601String(),
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
        if (observacoes != null && observacoes.isNotEmpty)
          'observacoes': observacoes,
      },
    );
    return _fromCache(map);
  }

  static Future<List<Reserva>> minhasReservas({String? status}) async {
    try {
      final resp = await _dio.get('/usuarios/me/reservas', queryParameters: {
        if (status != null) 'status': status,
      });
      final list = (resp.data['data'] as List)
          .map((e) => Reserva.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // Atualiza cache (preserva itens locais ainda nao sincronizados).
      await _mesclarCacheReservas(list);
      return list;
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      return _reservasDoCache(status: status);
    }
  }

  static Future<void> _mesclarCacheReservas(List<Reserva> remotas) async {
    // Mantem no cache as reservas locais pendentes de sync.
    final locaisPendentes = OfflineCacheService.getReservasCache()
        .where((m) => m['pendente_sync'] == true)
        .toList();
    await OfflineCacheService.saveReservasCache(
      remotas.map(_reservaToMap).toList(),
    );
    for (final l in locaisPendentes) {
      await OfflineCacheService.upsertReservaCache(l);
    }
  }

  static List<Reserva> _reservasDoCache({String? status}) {
    var list = OfflineCacheService.getReservasCache().map(_fromCache).toList();
    if (status != null) {
      list = list.where((r) => r.status == status).toList();
    }
    list.sort((a, b) => b.dataHoraInicio.compareTo(a.dataHoraInicio));
    return list;
  }

  static Future<Reserva> obter(String id) async {
    try {
      final resp = await _dio.get('/reservas/$id');
      final reserva =
          Reserva.fromJson(Map<String, dynamic>.from(resp.data['data'] as Map));
      await OfflineCacheService.upsertReservaCache(_reservaToMap(reserva));
      return reserva;
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      final cache = OfflineCacheService.getReservaCacheById(id);
      if (cache != null) return _fromCache(cache);
      rethrow;
    }
  }

  static Future<Reserva> iniciarUso(String id) => _mudarStatus(
        id,
        endpoint: '/reservas/$id/iniciar-uso',
        operacao: 'iniciar-uso',
        novoStatus: 'EM_USO',
      );

  static Future<Reserva> concluir(String id) async {
    final r = await _mudarStatus(
      id,
      endpoint: '/reservas/$id/concluir',
      operacao: 'concluir',
      novoStatus: 'CONCLUIDA',
    );
    await ReservaNotifications.cancelarParaReserva(id);
    return r;
  }

  static Future<Reserva> cancelar(String id) async {
    final r = await _mudarStatus(
      id,
      endpoint: '/reservas/$id/cancelar',
      operacao: 'cancelar',
      novoStatus: 'CANCELADA',
    );
    await ReservaNotifications.cancelarParaReserva(id);
    return r;
  }

  static Future<Reserva> aprovar(String id) async {
    final r = await _mudarStatus(
      id,
      endpoint: '/reservas/$id/aprovar',
      operacao: 'aprovar',
      novoStatus: 'CONFIRMADA',
    );
    await ReservaNotifications.agendarParaReserva(r);
    return r;
  }

  static Future<Reserva> rejeitar(String id, {String? motivo}) => _mudarStatus(
        id,
        endpoint: '/reservas/$id/rejeitar',
        operacao: 'rejeitar',
        novoStatus: 'REJEITADA',
        body: {if (motivo != null && motivo.isNotEmpty) 'motivo': motivo},
      );

  /// Executa uma mudanca de status via API; se offline, aplica no cache
  /// e enfileira a operacao para sincronizar depois.
  static Future<Reserva> _mudarStatus(
    String id, {
    required String endpoint,
    required String operacao,
    required String novoStatus,
    Map<String, dynamic>? body,
  }) async {
    try {
      final resp = await _dio.patch(endpoint, data: body);
      final reserva =
          Reserva.fromJson(Map<String, dynamic>.from(resp.data['data'] as Map));
      await OfflineCacheService.upsertReservaCache(_reservaToMap(reserva));
      return reserva;
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      await _cacheStatus(
        id,
        novoStatus,
        canceladoEm: novoStatus == 'CANCELADA' ? DateTime.now() : null,
        confirmadoEm: novoStatus == 'CONFIRMADA' ? DateTime.now() : null,
      );
      await OfflineCacheService.enqueueOutbox(
        entidade: 'reserva',
        operacao: operacao,
        refId: id,
        payload: {
          'endpoint': endpoint,
          'metodo': 'PATCH',
          if (body != null) 'body': body,
        },
      );
      final cache = OfflineCacheService.getReservaCacheById(id);
      if (cache != null) return _fromCache(cache);
      rethrow;
    }
  }

  static Future<List<Reserva>> aprovacoesPendentes() async {
    try {
      final resp = await _dio.get('/reservas/aprovacoes-pendentes');
      return (resp.data['data'] as List)
          .map((e) => Reserva.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      return _reservasDoCache(status: 'PENDENTE');
    }
  }

  static Map<String, dynamic> _reservaToMap(Reserva r) => {
        'id': r.id,
        'usuario_id': r.usuarioId,
        'usuario_nome': r.usuarioNome,
        'ativo_id': r.ativoId,
        'data_hora_inicio': r.dataHoraInicio.toUtc().toIso8601String(),
        'data_hora_fim': r.dataHoraFim.toUtc().toIso8601String(),
        'status': r.status,
        'motivo': r.motivo,
        'observacoes': r.observacoes,
        'criado_em': r.criadoEm?.toIso8601String(),
        'confirmado_em': r.confirmadoEm?.toIso8601String(),
        'cancelado_em': r.canceladoEm?.toIso8601String(),
        'motivo_rejeicao': r.motivoRejeicao,
        'codigo_interno': r.codigoInterno,
        'ativo_descricao': r.ativoDescricao,
        'tipo_ativo': r.tipoAtivo,
        'placa': r.placa,
        'responsavel_id': r.responsavelId,
      };
}
