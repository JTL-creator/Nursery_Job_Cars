import '../models/notificacao.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/offline_cache_service.dart';

class NotificacaoApiService {
  static final _dio = ApiClient().dio;

  static Future<List<Notificacao>> listar({bool apenasNaoLidas = false}) async {
    try {
      final resp = await _dio.get('/notificacoes', queryParameters: {
        if (apenasNaoLidas) 'nao_lidas': 'true',
      });
      final list = (resp.data['data'] as List)
          .map((e) => Notificacao.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      // Atualiza cache offline
      try {
        await OfflineCacheService.saveNotificacoesCache(
          list
              .map((n) => {
                    'id': n.id,
                    'tipo': n.tipo,
                    'titulo': n.titulo,
                    'mensagem': n.mensagem,
                    'entidade': n.entidade,
                    'entidade_id': n.entidadeId,
                    'lida': n.lida,
                    'criado_em': n.criadoEm?.toIso8601String(),
                  })
              .toList(),
        );
      } catch (_) {}

      return list;
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      return _doCache(apenasNaoLidas: apenasNaoLidas);
    }
  }

  static List<Notificacao> _doCache({bool apenasNaoLidas = false}) {
    var list = OfflineCacheService.getNotificacoesCache()
        .map((m) => Notificacao.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    if (apenasNaoLidas) {
      list = list.where((n) => !n.lida).toList();
    }
    list.sort((a, b) =>
        (b.criadoEm ?? DateTime(0)).compareTo(a.criadoEm ?? DateTime(0)));
    return list;
  }

  static Future<int> naoLidas() async {
    try {
      final resp = await _dio.get('/notificacoes/nao-lidas');
      return (resp.data['data']?['nao_lidas'] as int?) ?? 0;
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      return _doCache(apenasNaoLidas: true).length;
    }
  }

  static Future<void> marcarLida(String id) async {
    try {
      await _dio.patch('/notificacoes/$id/lida');
      await _marcarCacheLida(id);
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      await _marcarCacheLida(id);
      await OfflineCacheService.enqueueOutbox(
        entidade: 'notificacao',
        operacao: 'marcar-lida',
        refId: id,
        payload: {'endpoint': '/notificacoes/$id/lida', 'metodo': 'PATCH'},
      );
    }
  }

  static Future<void> marcarTodasLidas() async {
    try {
      await _dio.patch('/notificacoes/ler-todas');
      await _marcarCacheTodasLidas();
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      await _marcarCacheTodasLidas();
      await OfflineCacheService.enqueueOutbox(
        entidade: 'notificacao',
        operacao: 'ler-todas',
        payload: {'endpoint': '/notificacoes/ler-todas', 'metodo': 'PATCH'},
      );
    }
  }

  static Future<void> _marcarCacheLida(String id) async {
    final atual = OfflineCacheService.getNotificacoesCache();
    for (final n in atual) {
      if (n['id']?.toString() == id) n['lida'] = true;
    }
    await OfflineCacheService.saveNotificacoesCache(atual);
  }

  static Future<void> _marcarCacheTodasLidas() async {
    final atual = OfflineCacheService.getNotificacoesCache();
    for (final n in atual) {
      n['lida'] = true;
    }
    await OfflineCacheService.saveNotificacoesCache(atual);
  }
}
