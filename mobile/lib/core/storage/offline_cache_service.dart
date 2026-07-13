import 'package:hive_flutter/hive_flutter.dart';

/// Servico de cache offline com Hive.
///
/// Estrutura de boxes:
/// - pending_checklists: checklists preenchidos sem internet (fila de envio)
/// - cache_ativos: lista de ativos cacheada para uso offline
/// - cache_reservas: minhas reservas cacheadas
/// - cache_templates: templates de checklist cacheados (por tipo+etapa)
/// - sync_meta: metadados (ultimo sync, contadores, etc.)
class OfflineCacheService {
  static const String boxPending = 'pending_checklists';
  static const String boxAtivos = 'cache_ativos';
  static const String boxReservas = 'cache_reservas';
  static const String boxTemplates = 'cache_templates';
  static const String boxNotificacoes = 'cache_notificacoes';
  static const String boxCadastros = 'cache_cadastros';
  static const String boxOutbox = 'outbox_mutations';
  static const String boxMeta = 'sync_meta';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(boxPending),
      Hive.openBox(boxAtivos),
      Hive.openBox(boxReservas),
      Hive.openBox(boxTemplates),
      Hive.openBox(boxNotificacoes),
      Hive.openBox(boxCadastros),
      Hive.openBox(boxOutbox),
      Hive.openBox(boxMeta),
    ]);
  }

  // ===== OUTBOX (fila generica de mutacoes offline) =====

  static Box get _outbox => Hive.box(boxOutbox);

  /// Enfileira uma mutacao para envio quando houver conexao.
  ///
  /// - [entidade]: ex. 'reserva', 'cadastro', 'ativo_status'
  /// - [operacao]: ex. 'criar', 'cancelar', 'aprovar', 'atualizar'
  /// - [payload]: dados necessarios para reexecutar a chamada.
  /// - [refId]: id (local ou remoto) da entidade afetada, quando houver.
  ///
  /// Retorna o id local da entrada na fila.
  static Future<String> enqueueOutbox({
    required String entidade,
    required String operacao,
    required Map<String, dynamic> payload,
    String? refId,
  }) async {
    final localId = 'op_${DateTime.now().microsecondsSinceEpoch}';
    await _outbox.put(localId, {
      'local_id': localId,
      'entidade': entidade,
      'operacao': operacao,
      'payload': payload,
      'ref_id': refId,
      'criado_em_local': DateTime.now().toIso8601String(),
      'tentativas': 0,
      'ultimo_erro': null,
    });
    return localId;
  }

  /// Lista todas as mutacoes pendentes, em ordem de criacao (FIFO).
  static List<Map<String, dynamic>> listOutbox() {
    return _outbox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) => (a['criado_em_local'] as String)
          .compareTo(b['criado_em_local'] as String));
  }

  static int outboxCount() => _outbox.length;

  static Future<void> removeOutbox(String localId) async {
    await _outbox.delete(localId);
  }

  static Future<void> markOutboxAttempt(String localId, String? erro) async {
    final atual = _outbox.get(localId);
    if (atual == null) return;
    final m = Map<String, dynamic>.from(atual as Map);
    m['tentativas'] = (m['tentativas'] as int? ?? 0) + 1;
    m['ultimo_erro'] = erro;
    m['ultima_tentativa'] = DateTime.now().toIso8601String();
    await _outbox.put(localId, m);
  }

  static Future<void> clearOutbox() async => _outbox.clear();

  // ===== PENDING CHECKLISTS =====

  static Box get _pending => Hive.box(boxPending);

  /// Salva um checklist preenchido offline para envio posterior.
  /// Retorna um id local temporario.
  static Future<String> savePendingChecklist({
    required String reservaId,
    required String etapa,
    required List<Map<String, dynamic>> itens,
    String? local,
    String? responsavel,
    String? observacoes,
  }) async {
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    await _pending.put(localId, {
      'local_id': localId,
      'reserva_id': reservaId,
      'etapa': etapa,
      'itens': itens,
      'local': local,
      'responsavel': responsavel,
      'observacoes': observacoes,
      'criado_em_local': DateTime.now().toIso8601String(),
      'tentativas': 0,
      'ultimo_erro': null,
    });
    return localId;
  }

  /// Lista todos os checklists pendentes.
  static List<Map<String, dynamic>> listPendingChecklists() {
    return _pending.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) => (a['criado_em_local'] as String)
          .compareTo(b['criado_em_local'] as String));
  }

  /// Quantidade de pendentes.
  static int pendingCount() => _pending.length;

  /// Total de itens aguardando sincronizacao (checklists + outbox).
  static int totalPendentes() => _pending.length + _outbox.length;

  /// Remove um pendente (apos envio bem-sucedido).
  static Future<void> removePending(String localId) async {
    await _pending.delete(localId);
  }

  /// Marca tentativa de envio (incrementa contador e salva erro).
  static Future<void> markPendingAttempt(String localId, String? erro) async {
    final atual = _pending.get(localId);
    if (atual == null) return;
    final m = Map<String, dynamic>.from(atual as Map);
    m['tentativas'] = (m['tentativas'] as int? ?? 0) + 1;
    m['ultimo_erro'] = erro;
    m['ultima_tentativa'] = DateTime.now().toIso8601String();
    await _pending.put(localId, m);
  }

  static Future<void> clearAllPending() async => _pending.clear();

  // ===== CACHE DE ATIVOS =====

  static Box get _ativos => Hive.box(boxAtivos);

  static Future<void> saveAtivosCache(List<Map<String, dynamic>> ativos) async {
    await _ativos.clear();
    for (final a in ativos) {
      await _ativos.put(a['id'], a);
    }
    await _setMeta('ativos_atualizado_em', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>> getAtivosCache() {
    return _ativos.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Insere/atualiza um ativo no cache (criacao/edicao offline).
  static Future<void> upsertAtivoCache(Map<String, dynamic> ativo) async {
    final id = ativo['id']?.toString();
    if (id == null || id.isEmpty) return;
    final atual = _ativos.get(id);
    if (atual is Map) {
      // Mescla com o que ja existe (edicao parcial).
      final merged = Map<String, dynamic>.from(atual)..addAll(ativo);
      await _ativos.put(id, merged);
    } else {
      await _ativos.put(id, ativo);
    }
  }

  static Future<void> removeAtivoCache(String id) async {
    await _ativos.delete(id);
  }

  // ===== CACHE DE RESERVAS =====

  static Box get _reservas => Hive.box(boxReservas);

  static Future<void> saveReservasCache(
      List<Map<String, dynamic>> reservas) async {
    await _reservas.clear();
    for (final r in reservas) {
      await _reservas.put(r['id'], r);
    }
    await _setMeta('reservas_atualizado_em', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>> getReservasCache() {
    return _reservas.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Insere/atualiza uma reserva no cache (usado em criacao/edicao offline).
  static Future<void> upsertReservaCache(Map<String, dynamic> reserva) async {
    final id = reserva['id']?.toString();
    if (id == null || id.isEmpty) return;
    await _reservas.put(id, reserva);
  }

  static Map<String, dynamic>? getReservaCacheById(String id) {
    final v = _reservas.get(id);
    if (v == null) return null;
    return Map<String, dynamic>.from(v as Map);
  }

  static Future<void> removeReservaCache(String id) async {
    await _reservas.delete(id);
  }

  // ===== CACHE DE NOTIFICACOES =====

  static Box get _notificacoes => Hive.box(boxNotificacoes);

  static Future<void> saveNotificacoesCache(
      List<Map<String, dynamic>> itens) async {
    await _notificacoes.clear();
    for (final n in itens) {
      final id = n['id']?.toString();
      if (id != null) await _notificacoes.put(id, n);
    }
    await _setMeta(
        'notificacoes_atualizado_em', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>> getNotificacoesCache() {
    return _notificacoes.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ===== CACHE DE CADASTROS (solicitacoes) =====

  static Box get _cadastros => Hive.box(boxCadastros);

  static Future<void> saveCadastrosCache(
      List<Map<String, dynamic>> itens) async {
    await _cadastros.clear();
    for (final c in itens) {
      final id = c['id']?.toString();
      if (id != null) await _cadastros.put(id, c);
    }
    await _setMeta('cadastros_atualizado_em', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>> getCadastrosCache() {
    return _cadastros.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ===== CACHE DE TEMPLATES =====

  static Box get _templates => Hive.box(boxTemplates);

  /// Chave: tipo_ativo + "_" + etapa (ex: VEICULO_RETIRADA)
  static String _tplKey(String tipoAtivo, String etapa) =>
      '${tipoAtivo}_$etapa';

  static Future<void> saveTemplateCache(
    String tipoAtivo,
    String etapa,
    Map<String, dynamic> template,
  ) async {
    await _templates.put(_tplKey(tipoAtivo, etapa), template);
  }

  static Map<String, dynamic>? getTemplateCache(
      String tipoAtivo, String etapa) {
    final v = _templates.get(_tplKey(tipoAtivo, etapa));
    if (v == null) return null;
    return Map<String, dynamic>.from(v as Map);
  }

  /// Cache da lista completa de templates (tela de administracao).
  static const String _kTemplatesList = '__admin_templates_list__';

  static Future<void> saveTemplatesListCache(
      List<Map<String, dynamic>> itens) async {
    await _templates.put(_kTemplatesList, itens);
    await _setMeta('templates_atualizado_em', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>> getTemplatesListCache() {
    final v = _templates.get(_kTemplatesList);
    if (v is! List) return [];
    return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Insere/atualiza um template na lista cacheada (por id).
  static Future<void> upsertTemplateInList(Map<String, dynamic> tpl) async {
    final id = tpl['id']?.toString();
    if (id == null || id.isEmpty) return;
    final list = getTemplatesListCache();
    final idx = list.indexWhere((m) => m['id']?.toString() == id);
    if (idx >= 0) {
      list[idx] = tpl;
    } else {
      list.add(tpl);
    }
    await _templates.put(_kTemplatesList, list);
  }

  static Future<void> removeTemplateFromList(String id) async {
    final list = getTemplatesListCache()
      ..removeWhere((m) => m['id']?.toString() == id);
    await _templates.put(_kTemplatesList, list);
  }

  // ===== META =====

  static Box get _meta => Hive.box(boxMeta);

  static Future<void> _setMeta(String key, dynamic value) async {
    await _meta.put(key, value);
  }

  static T? getMeta<T>(String key) {
    final v = _meta.get(key);
    return v as T?;
  }

  static Future<void> setLastSyncTimestamp() async {
    await _setMeta('ultimo_sync', DateTime.now().toIso8601String());
  }

  static DateTime? getLastSyncTimestamp() {
    final v = _meta.get('ultimo_sync');
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
