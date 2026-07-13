import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../storage/offline_cache_service.dart';

/// Resultado de uma rodada de sync.
class SyncResult {
  final int enviados;
  final int falhas;
  final List<String> erros;
  final bool houveSync;

  const SyncResult({
    required this.enviados,
    required this.falhas,
    required this.erros,
    required this.houveSync,
  });

  factory SyncResult.empty() =>
      const SyncResult(enviados: 0, falhas: 0, erros: [], houveSync: false);

  bool get totalSucesso => falhas == 0 && enviados > 0;

  SyncResult operator +(SyncResult o) => SyncResult(
        enviados: enviados + o.enviados,
        falhas: falhas + o.falhas,
        erros: [...erros, ...o.erros],
        houveSync: houveSync || o.houveSync,
      );
}

/// Servico responsavel por sincronizar checklists pendentes com o backend.
class SyncService {
  static bool _emAndamento = false;

  /// Verifica se ha sync em andamento.
  static bool get emAndamento => _emAndamento;

  /// Sincroniza todos os checklists pendentes.
  /// Retorna o resultado da operacao.
  static Future<SyncResult> syncPendingChecklists() async {
    if (_emAndamento) {
      debugPrint('[SYNC] Ja em andamento, ignorando chamada concorrente.');
      return SyncResult.empty();
    }
    _emAndamento = true;

    int enviados = 0;
    int falhas = 0;
    final erros = <String>[];
    final pendentes = OfflineCacheService.listPendingChecklists();

    if (pendentes.isEmpty) {
      _emAndamento = false;
      return SyncResult.empty();
    }

    debugPrint('[SYNC] Iniciando sync de ${pendentes.length} pendente(s)...');

    for (final p in pendentes) {
      final localId = p['local_id'] as String;
      final reservaId = p['reserva_id'] as String;
      final etapa = p['etapa'] as String;
      final tentativas = p['tentativas'] as int? ?? 0;

      // Limite de tentativas (evita loop infinito)
      if (tentativas >= 5) {
        debugPrint('[SYNC] $localId atingiu limite de tentativas. Pulando.');
        falhas++;
        continue;
      }

      try {
        await ApiClient().dio.post(
          '/usuarios/me/reservas/$reservaId/checklists',
          data: {
            'etapa': etapa,
            if (p['local'] != null) 'local': p['local'],
            if (p['responsavel'] != null) 'responsavel': p['responsavel'],
            if (p['observacoes'] != null) 'observacoes': p['observacoes'],
            'itens': p['itens'],
          },
        );
        await OfflineCacheService.removePending(localId);
        enviados++;
        debugPrint('[SYNC] $localId enviado com sucesso.');
      } catch (e) {
        falhas++;
        final msg = ApiClient.extractMessage(e);
        erros.add('$localId: $msg');
        await OfflineCacheService.markPendingAttempt(localId, msg);
        debugPrint('[SYNC] $localId falhou: $msg');
      }
    }

    await OfflineCacheService.setLastSyncTimestamp();
    _emAndamento = false;

    debugPrint('[SYNC] Concluido: $enviados enviados, $falhas falhas.');
    return SyncResult(
      enviados: enviados,
      falhas: falhas,
      erros: erros,
      houveSync: true,
    );
  }

  /// Drena a fila generica de mutacoes (outbox): reservas criadas/alteradas
  /// offline, e demais operacoes enfileiradas.
  ///
  /// Processa em ordem FIFO e remapeia ids locais para os ids reais
  /// retornados pelo backend (ex.: criar reserva offline e depois cancelar).
  static Future<SyncResult> syncOutbox() async {
    final ops = OfflineCacheService.listOutbox();
    if (ops.isEmpty) return SyncResult.empty();

    final dio = ApiClient().dio;
    final remap = <String, String>{};
    int enviados = 0;
    int falhas = 0;
    final erros = <String>[];

    debugPrint('[SYNC] Outbox: ${ops.length} operacao(oes) pendente(s)...');

    for (final op in ops) {
      final localId = op['local_id'] as String;
      final entidade = op['entidade'] as String;
      final operacao = op['operacao'] as String;
      final refId = op['ref_id']?.toString();
      final tentativas = op['tentativas'] as int? ?? 0;
      final payload = Map<String, dynamic>.from(op['payload'] as Map);

      if (tentativas >= 5) {
        falhas++;
        continue;
      }

      try {
        if (operacao == 'criar') {
          // Criacao: POST e remapeamento do id local -> id real no cache.
          final estruturado = payload.containsKey('endpoint');
          final endpoint =
              estruturado ? payload['endpoint'].toString() : '/reservas';
          final body = estruturado ? payload['body'] : payload;

          final resp = await dio.post(endpoint, data: body);
          final data = Map<String, dynamic>.from(resp.data['data'] as Map);
          final novoId = data['id']?.toString();
          if (refId != null && novoId != null) {
            remap[refId] = novoId;
          }
          await _aplicarCriacaoNoCache(entidade, refId, data);
        } else {
          var endpoint = payload['endpoint']?.toString() ?? '';
          if (refId != null && remap.containsKey(refId)) {
            endpoint = endpoint.replaceAll(refId, remap[refId]!);
          }
          if (endpoint.isEmpty) {
            throw StateError('Operacao sem endpoint: $entidade/$operacao');
          }
          final metodo =
              (payload['metodo']?.toString() ?? 'PATCH').toUpperCase();
          await dio.request(
            endpoint,
            data: payload['body'],
            options: Options(method: metodo),
          );
        }

        await OfflineCacheService.removeOutbox(localId);
        enviados++;
      } catch (e) {
        // Ainda offline: interrompe e mantem o restante para a proxima rodada.
        if (ApiClient.isConnectionError(e)) {
          debugPrint('[SYNC] Offline novamente; interrompendo outbox.');
          break;
        }
        falhas++;
        final msg = ApiClient.extractMessage(e);
        erros.add('$entidade/$operacao: $msg');
        await OfflineCacheService.markOutboxAttempt(localId, msg);
      }
    }

    debugPrint('[SYNC] Outbox concluido: $enviados enviados, $falhas falhas.');
    return SyncResult(
      enviados: enviados,
      falhas: falhas,
      erros: erros,
      houveSync: true,
    );
  }

  /// Sincroniza tudo: outbox (mutacoes) + checklists pendentes.
  static Future<SyncResult> syncAll() async {
    final outbox = await syncOutbox();
    final checklists = await syncPendingChecklists();
    await OfflineCacheService.setLastSyncTimestamp();
    return outbox + checklists;
  }

  /// Apos criar uma entidade no backend, substitui o registro local
  /// (id temporario) pelo registro real no cache correspondente.
  static Future<void> _aplicarCriacaoNoCache(
    String entidade,
    String? localId,
    Map<String, dynamic> data,
  ) async {
    switch (entidade) {
      case 'reserva':
        if (localId != null) {
          await OfflineCacheService.removeReservaCache(localId);
        }
        await OfflineCacheService.upsertReservaCache(data);
        break;
      case 'ativo':
        if (localId != null) {
          await OfflineCacheService.removeAtivoCache(localId);
        }
        await OfflineCacheService.upsertAtivoCache(data);
        break;
      case 'template':
        if (localId != null) {
          await OfflineCacheService.removeTemplateFromList(localId);
        }
        await OfflineCacheService.upsertTemplateInList(data);
        break;
      default:
        break;
    }
  }
}
