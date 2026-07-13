import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/storage/offline_cache_service.dart';
import '../../core/sync/sync_service.dart';
import '../../core/services/connectivity_service.dart';

/// Provider que gerencia o estado de sync e quantidade de pendentes.
/// Reage automaticamente quando a conexao volta.
class SyncProvider extends ChangeNotifier {
  int _pendentes = 0;
  bool _sincronizando = false;
  String? _ultimaMensagem;
  DateTime? _ultimoSync;
  StreamSubscription<bool>? _subConn;

  int get pendentes => _pendentes;
  bool get sincronizando => _sincronizando;
  String? get ultimaMensagem => _ultimaMensagem;
  DateTime? get ultimoSync => _ultimoSync;
  bool get temPendentes => _pendentes > 0;

  SyncProvider() {
    _refreshContador();
    _ultimoSync = OfflineCacheService.getLastSyncTimestamp();

    // Escuta mudancas de conectividade
    _subConn = ConnectivityService.instance.onChange.listen((online) {
      if (online && _pendentes > 0) {
        debugPrint('[SYNC] Conexao restaurada, disparando sync automatico...');
        sincronizar();
      }
    });
  }

  @override
  void dispose() {
    _subConn?.cancel();
    super.dispose();
  }

  void _refreshContador() {
    _pendentes = OfflineCacheService.totalPendentes();
    notifyListeners();
  }

  /// Chamado quando um checklist e salvo localmente (offline).
  void onChecklistSalvoOffline() {
    _refreshContador();
  }

  /// Chamado quando qualquer mutacao e enfileirada offline (reservas, etc.).
  void onMutacaoOffline() {
    _refreshContador();
  }

  /// Executa sync manual ou automatico.
  Future<SyncResult> sincronizar() async {
    if (_sincronizando) return SyncResult.empty();
    _sincronizando = true;
    _ultimaMensagem = 'Sincronizando...';
    notifyListeners();

    final result = await SyncService.syncAll();

    _sincronizando = false;
    _ultimoSync = DateTime.now();

    if (!result.houveSync) {
      _ultimaMensagem = null;
    } else if (result.totalSucesso) {
      _ultimaMensagem = '${result.enviados} item(ns) sincronizado(s)!';
    } else if (result.enviados > 0) {
      _ultimaMensagem =
          '${result.enviados} enviado(s), ${result.falhas} falha(s)';
    } else {
      _ultimaMensagem = 'Falha ao sincronizar (${result.falhas})';
    }

    _refreshContador();
    return result;
  }

  void limparMensagem() {
    _ultimaMensagem = null;
    notifyListeners();
  }
}
