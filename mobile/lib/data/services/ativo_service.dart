import 'dart:io';
import 'package:dio/dio.dart';
import '../models/ativo.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/offline_cache_service.dart';

class AtivoService {
  static final _dio = ApiClient().dio;

  static Future<List<Ativo>> listar({
    String? tipoAtivo,
    String? categoria,
    String? status,
    String? q,
  }) async {
    try {
      final resp = await _dio.get('/ativos', queryParameters: {
        if (categoria != null) 'categoria': categoria,
        if (tipoAtivo != null) 'tipo_ativo': tipoAtivo,
        if (status != null) 'status': status,
        if (q != null && q.isNotEmpty) 'q': q,
      });
      final list = (resp.data['data'] as List)
          .map((e) => Ativo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      // Atualiza cache offline
      try {
        await OfflineCacheService.saveAtivosCache(
          list
              .map((a) => {
                    'id': a.id,
                    'codigo_interno': a.codigoInterno,
                    'descricao': a.descricao,
                    'tipo_ativo': a.tipoAtivo,
                    'sub_tipo': a.subTipo,
                    'placa': a.placa,
                    'patrimonio': a.patrimonio,
                    'unidade': a.unidade,
                    'status': a.status,
                  })
              .toList(),
        );
      } catch (_) {}

      return list;
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      return _listarOffline(
        tipoAtivo: tipoAtivo,
        status: status,
        q: q,
      );
    }
  }

  /// Lista ativos a partir do cache local (offline).
  static List<Ativo> _listarOffline({
    String? tipoAtivo,
    String? status,
    String? q,
  }) {
    final termo = q?.trim().toLowerCase();
    return OfflineCacheService.getAtivosCache()
        .where((a) {
          if (tipoAtivo != null && a['tipo_ativo']?.toString() != tipoAtivo) {
            return false;
          }
          if (status != null && a['status']?.toString() != status) return false;
          if (termo != null && termo.isNotEmpty) {
            final alvo = [
              a['codigo_interno'],
              a['descricao'],
              a['placa'],
              a['patrimonio'],
            ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');
            if (!alvo.contains(termo)) return false;
          }
          return true;
        })
        .map((a) => Ativo.fromJson(Map<String, dynamic>.from(a)))
        .toList();
  }

  static Future<Ativo> obter(String id) async {
    try {
      final resp = await _dio.get('/ativos/$id');
      return Ativo.fromJson(
          Map<String, dynamic>.from(resp.data['data'] as Map));
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      for (final a in OfflineCacheService.getAtivosCache()) {
        if (a['id']?.toString() == id) {
          return Ativo.fromJson(Map<String, dynamic>.from(a));
        }
      }
      rethrow;
    }
  }

  static Future<Ativo> criar(Map<String, dynamic> dados) async {
    try {
      final resp = await _dio.post('/ativos', data: dados);
      final ativo =
          Ativo.fromJson(Map<String, dynamic>.from(resp.data['data'] as Map));
      await OfflineCacheService.upsertAtivoCache(_ativoToMap(ativo));
      return ativo;
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      // Offline: cria localmente e enfileira o envio.
      final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
      final map = <String, dynamic>{
        ...dados,
        'id': localId,
        'status': dados['status']?.toString() ?? 'DISPONIVEL',
        'pendente_sync': true,
      };
      await OfflineCacheService.upsertAtivoCache(map);
      await OfflineCacheService.enqueueOutbox(
        entidade: 'ativo',
        operacao: 'criar',
        refId: localId,
        payload: {
          'endpoint': '/ativos',
          'metodo': 'POST',
          'body': dados,
        },
      );
      return Ativo.fromJson(map);
    }
  }

  static Future<Ativo> atualizar(String id, Map<String, dynamic> dados) async {
    try {
      final resp = await _dio.patch('/ativos/$id', data: dados);
      final ativo =
          Ativo.fromJson(Map<String, dynamic>.from(resp.data['data'] as Map));
      await OfflineCacheService.upsertAtivoCache(_ativoToMap(ativo));
      return ativo;
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      await OfflineCacheService.upsertAtivoCache({'id': id, ...dados});
      await OfflineCacheService.enqueueOutbox(
        entidade: 'ativo',
        operacao: 'atualizar',
        refId: id,
        payload: {
          'endpoint': '/ativos/$id',
          'metodo': 'PATCH',
          'body': dados,
        },
      );
      final cache = OfflineCacheService.getAtivosCache().firstWhere(
          (a) => a['id']?.toString() == id,
          orElse: () => {'id': id});
      return Ativo.fromJson(Map<String, dynamic>.from(cache));
    }
  }

  static Future<Ativo> atualizarStatusRemoto(String id, String status) async {
    try {
      final resp =
          await _dio.patch('/ativos/$id/status', data: {'status': status});
      final ativo =
          Ativo.fromJson(Map<String, dynamic>.from(resp.data['data'] as Map));
      await OfflineCacheService.upsertAtivoCache(_ativoToMap(ativo));
      return ativo;
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      await OfflineCacheService.upsertAtivoCache({'id': id, 'status': status});
      await OfflineCacheService.enqueueOutbox(
        entidade: 'ativo',
        operacao: 'status',
        refId: id,
        payload: {
          'endpoint': '/ativos/$id/status',
          'metodo': 'PATCH',
          'body': {'status': status},
        },
      );
      final cache = OfflineCacheService.getAtivosCache().firstWhere(
          (a) => a['id']?.toString() == id,
          orElse: () => {'id': id});
      return Ativo.fromJson(Map<String, dynamic>.from(cache));
    }
  }

  static Map<String, dynamic> _ativoToMap(Ativo a) => {
        'id': a.id,
        'codigo_interno': a.codigoInterno,
        'descricao': a.descricao,
        'tipo_ativo': a.tipoAtivo,
        'sub_tipo': a.subTipo,
        'placa': a.placa,
        'patrimonio': a.patrimonio,
        'unidade': a.unidade,
        'status': a.status,
      };

  /// Envia uma foto do ativo e retorna a URL relativa (ex.: /uploads/ativos/x.jpg).
  static Future<String> uploadFoto(File file) async {
    final nome = file.path.split(Platform.pathSeparator).last;
    final form = FormData.fromMap({
      'foto': await MultipartFile.fromFile(file.path, filename: nome),
    });
    final resp = await _dio.post('/ativos/foto', data: form);
    return resp.data['data']['url'] as String;
  }

  /// Busca um ativo pelo codigo interno (usado pelo QR Scanner).
  /// Tenta API primeiro, depois cache offline.
  static Future<Ativo?> buscarPorCodigo(String codigo) async {
    try {
      final resp = await _dio.get('/ativos', queryParameters: {
        'q': codigo,
        'limit': 5,
      });
      final list = (resp.data['data'] as List)
          .map((e) => Ativo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // Filtra match exato
      final exact = list
          .where((a) => a.codigoInterno.toUpperCase() == codigo.toUpperCase())
          .toList();
      if (exact.isNotEmpty) return exact.first;
      if (list.isNotEmpty) return list.first;
      return null;
    } catch (_) {
      // Fallback: busca no cache
      final cache = OfflineCacheService.getAtivosCache();
      for (final c in cache) {
        if ((c['codigo_interno']?.toString().toUpperCase() ?? '') ==
            codigo.toUpperCase()) {
          return Ativo.fromJson(c);
        }
      }
      return null;
    }
  }

  /// Busca um ativo pela placa (usado pela leitura de placa/OCR).
  /// Tenta API primeiro, depois cache offline.
  static Future<Ativo?> buscarPorPlaca(String placa) async {
    final alvo = placa.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (alvo.isEmpty) return null;

    String norm(String? p) =>
        (p ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    try {
      final resp = await _dio.get('/ativos', queryParameters: {
        'q': placa,
        'limit': 10,
      });
      final list = (resp.data['data'] as List)
          .map((e) => Ativo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final exact = list.where((a) => norm(a.placa) == alvo).toList();
      if (exact.isNotEmpty) return exact.first;
      return null;
    } catch (_) {
      final cache = OfflineCacheService.getAtivosCache();
      for (final c in cache) {
        if (norm(c['placa']?.toString()) == alvo) {
          return Ativo.fromJson(Map<String, dynamic>.from(c));
        }
      }
      return null;
    }
  }

  static Future<List<Ativo>> disponibilidade({
    required DateTime inicio,
    required DateTime fim,
    String? tipoAtivo,
    String? categoria,
    String? unidade,
  }) async {
    try {
      final resp =
          await _dio.get('/reservas/disponibilidade', queryParameters: {
        'inicio': inicio.toUtc().toIso8601String(),
        'fim': fim.toUtc().toIso8601String(),
        if (categoria != null) 'categoria': categoria,
        if (tipoAtivo != null) 'tipo_ativo': tipoAtivo,
        if (unidade != null) 'unidade': unidade,
      });
      return (resp.data['data'] as List)
          .map((e) => Ativo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      return _disponibilidadeOffline(
        inicio: inicio,
        fim: fim,
        tipoAtivo: tipoAtivo,
        unidade: unidade,
      );
    }
  }

  /// Calcula disponibilidade offline cruzando o cache de ativos com o de
  /// reservas (um ativo esta livre se nenhuma reserva ativa se sobrepoe).
  static List<Ativo> _disponibilidadeOffline({
    required DateTime inicio,
    required DateTime fim,
    String? tipoAtivo,
    String? unidade,
  }) {
    const statusAtivos = {'PENDENTE', 'CONFIRMADA', 'EM_USO'};
    final reservas = OfflineCacheService.getReservasCache();

    bool ocupado(String ativoId) {
      for (final r in reservas) {
        if (r['ativo_id']?.toString() != ativoId) continue;
        if (!statusAtivos.contains(r['status']?.toString())) continue;
        final ri = DateTime.tryParse(r['data_hora_inicio']?.toString() ?? '');
        final rf = DateTime.tryParse(r['data_hora_fim']?.toString() ?? '');
        if (ri == null || rf == null) continue;
        // Sobreposicao de periodos.
        if (ri.isBefore(fim) && rf.isAfter(inicio)) return true;
      }
      return false;
    }

    return OfflineCacheService.getAtivosCache()
        .where((a) {
          final st = a['status']?.toString();
          if (st == 'INDISPONIVEL' || st == 'MANUTENCAO') return false;
          if (tipoAtivo != null && a['tipo_ativo']?.toString() != tipoAtivo) {
            return false;
          }
          if (unidade != null && a['unidade']?.toString() != unidade) {
            return false;
          }
          if (ocupado(a['id']?.toString() ?? '')) return false;
          return true;
        })
        .map((a) => Ativo.fromJson(Map<String, dynamic>.from(a)))
        .toList();
  }
}
