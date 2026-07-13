import '../models/checklist_template.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/offline_cache_service.dart';

class ChecklistService {
  static final _dio = ApiClient().dio;

  static Future<ChecklistTemplate> obterTemplate({
    required String reservaId,
    required String etapa,
    String? tipoAtivoFallback,
  }) async {
    try {
      final resp = await _dio.get(
        '/usuarios/me/reservas/$reservaId/checklists/template',
        queryParameters: {'etapa': etapa},
      );
      final data = Map<String, dynamic>.from(resp.data['data'] as Map);
      final tipo = data['tipo_ativo']?.toString();
      if (tipo != null) {
        await OfflineCacheService.saveTemplateCache(tipo, etapa, data);
      }
      return ChecklistTemplate.fromJson(data);
    } catch (e) {
      if (tipoAtivoFallback != null) {
        final cached =
            OfflineCacheService.getTemplateCache(tipoAtivoFallback, etapa);
        if (cached != null) return ChecklistTemplate.fromJson(cached);
      }
      rethrow;
    }
  }

  static Future<bool> criarComFallbackOffline({
    required String reservaId,
    required String etapa,
    required List<Map<String, dynamic>> itens,
    String? local,
    String? responsavel,
    String? observacoes,
  }) async {
    try {
      await _dio.post(
        '/usuarios/me/reservas/$reservaId/checklists',
        data: {
          'etapa': etapa,
          if (local != null) 'local': local,
          if (responsavel != null) 'responsavel': responsavel,
          if (observacoes != null) 'observacoes': observacoes,
          'itens': itens,
        },
      );
      return true;
    } catch (e) {
      await OfflineCacheService.savePendingChecklist(
        reservaId: reservaId,
        etapa: etapa,
        itens: itens,
        local: local,
        responsavel: responsavel,
        observacoes: observacoes,
      );
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> minhasChecklists() async {
    final resp = await _dio.get('/usuarios/me/checklists');
    return (resp.data['data'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Detalhe completo do check-list com itens (para gerar PDF).
  static Future<Map<String, dynamic>> obterDetalhe(String id) async {
    final resp = await _dio.get('/checklists/$id');
    return Map<String, dynamic>.from(resp.data['data'] as Map);
  }

  // ===== Administracao de templates (somente ADMINISTRADOR) =====

  static Future<List<ChecklistTemplate>> listarTemplates({
    String? tipoAtivo,
    String? etapa,
  }) async {
    try {
      final resp = await _dio.get('/checklists/templates', queryParameters: {
        if (tipoAtivo != null) 'tipo_ativo': tipoAtivo,
        if (etapa != null) 'etapa': etapa,
      });
      final raw = (resp.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Cacheia a lista completa (sem filtros) para uso offline.
      if (tipoAtivo == null && etapa == null) {
        try {
          await OfflineCacheService.saveTemplatesListCache(raw);
        } catch (_) {}
      }

      return raw.map((e) => ChecklistTemplate.fromJson(e)).toList();
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      // Offline: usa o cache da ultima sincronizacao.
      var list = OfflineCacheService.getTemplatesListCache();
      if (tipoAtivo != null) {
        list = list
            .where((m) => m['tipo_ativo']?.toString() == tipoAtivo)
            .toList();
      }
      if (etapa != null) {
        list = list.where((m) => m['etapa']?.toString() == etapa).toList();
      }
      return list.map((e) => ChecklistTemplate.fromJson(e)).toList();
    }
  }

  static Future<ChecklistTemplate> criarTemplate(
      Map<String, dynamic> dados) async {
    try {
      final resp = await _dio.post('/checklists/templates', data: dados);
      final data = Map<String, dynamic>.from(resp.data['data'] as Map);
      await OfflineCacheService.upsertTemplateInList(data);
      return ChecklistTemplate.fromJson(data);
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
      final map = _templateLocalMap(localId, dados);
      await OfflineCacheService.upsertTemplateInList(map);
      await OfflineCacheService.enqueueOutbox(
        entidade: 'template',
        operacao: 'criar',
        refId: localId,
        payload: {
          'endpoint': '/checklists/templates',
          'metodo': 'POST',
          'body': dados,
        },
      );
      return ChecklistTemplate.fromJson(map);
    }
  }

  static Future<ChecklistTemplate> atualizarTemplate(
      String id, Map<String, dynamic> dados) async {
    try {
      final resp = await _dio.patch('/checklists/templates/$id', data: dados);
      final data = Map<String, dynamic>.from(resp.data['data'] as Map);
      await OfflineCacheService.upsertTemplateInList(data);
      return ChecklistTemplate.fromJson(data);
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      final map = _templateLocalMap(id, dados);
      await OfflineCacheService.upsertTemplateInList(map);
      await OfflineCacheService.enqueueOutbox(
        entidade: 'template',
        operacao: 'atualizar',
        refId: id,
        payload: {
          'endpoint': '/checklists/templates/$id',
          'metodo': 'PATCH',
          'body': dados,
        },
      );
      return ChecklistTemplate.fromJson(map);
    }
  }

  static Future<void> excluirTemplate(String id) async {
    try {
      await _dio.delete('/checklists/templates/$id');
      await OfflineCacheService.removeTemplateFromList(id);
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      await OfflineCacheService.removeTemplateFromList(id);
      await OfflineCacheService.enqueueOutbox(
        entidade: 'template',
        operacao: 'excluir',
        refId: id,
        payload: {
          'endpoint': '/checklists/templates/$id',
          'metodo': 'DELETE',
        },
      );
    }
  }

  /// Monta um mapa de template no formato esperado por [ChecklistTemplate]
  /// e pelo cache, a partir do payload enviado pelo formulario.
  static Map<String, dynamic> _templateLocalMap(
      String id, Map<String, dynamic> dados) {
    final itensRaw = (dados['itens'] as List?) ?? const [];
    final itens = <Map<String, dynamic>>[];
    for (var i = 0; i < itensRaw.length; i++) {
      final it = Map<String, dynamic>.from(itensRaw[i] as Map);
      itens.add({
        'id': 'local_item_${DateTime.now().microsecondsSinceEpoch}_$i',
        'chave_item': it['chave_item']?.toString() ?? '',
        'descricao': it['descricao'],
        'tipo_campo': it['tipo_campo'],
        'obrigatorio': it['obrigatorio'] == true,
        'ordem': it['ordem'] ?? (i + 1),
        if (it['opcoes'] != null) 'opcoes_json': {'opcoes': it['opcoes']},
      });
    }
    return {
      'id': id,
      'tipo_ativo': dados['tipo_ativo'],
      'etapa': dados['etapa'],
      'nome': dados['nome'],
      'versao': 1,
      'itens': itens,
      'pendente_sync': true,
    };
  }
}
