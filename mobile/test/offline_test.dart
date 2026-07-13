import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:gdm_job_cars_mobile/core/storage/local_auth_service.dart';
import 'package:gdm_job_cars_mobile/core/storage/offline_cache_service.dart';
import 'package:gdm_job_cars_mobile/data/models/usuario.dart';

/// Testes do nucleo offline-first: login offline + fila de mutacoes (outbox)
/// + cache local. Nao dependem de rede nem de backend.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================
  // LOGIN OFFLINE (LocalAuthService)
  // ===========================================================
  group('LocalAuthService (login offline)', () {
    const canal = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    final store = <String, String>{};

    setUp(() {
      store.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
        final args = (call.arguments as Map?) ?? const {};
        final key = args['key'] as String?;
        switch (call.method) {
          case 'write':
            store[key!] = args['value'] as String;
            return null;
          case 'read':
            return store[key];
          case 'delete':
            store.remove(key);
            return null;
          case 'containsKey':
            return store.containsKey(key);
          case 'readAll':
            return Map<String, String>.from(store);
          case 'deleteAll':
            store.clear();
            return null;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, null);
    });

    const usuario = Usuario(
      id: 'u1',
      nomeCompleto: 'Fulano de Tal',
      email: 'a@b.com',
      perfil: 'USUARIO',
    );

    test('autentica offline com a senha correta apos login online', () async {
      await LocalAuthService.registrarLoginOnline(
        email: 'A@B.com', // e-mail deve ser normalizado (case-insensitive)
        senha: 'segredo123',
        usuario: usuario,
        perfil: 'USUARIO',
      );

      final cred =
          await LocalAuthService.autenticarOffline('a@b.com', 'segredo123');

      expect(cred, isNotNull);
      expect(cred!.usuario.id, 'u1');
      expect(cred.perfil, 'USUARIO');
    });

    test('rejeita senha incorreta', () async {
      await LocalAuthService.registrarLoginOnline(
        email: 'a@b.com',
        senha: 'segredo123',
        usuario: usuario,
        perfil: 'USUARIO',
      );

      final cred =
          await LocalAuthService.autenticarOffline('a@b.com', 'errada');

      expect(cred, isNull);
    });

    test('retorna null para usuario sem credencial salva', () async {
      final cred =
          await LocalAuthService.autenticarOffline('naoexiste@b.com', 'x');
      expect(cred, isNull);
    });

    test('nunca persiste a senha em texto puro', () async {
      await LocalAuthService.registrarLoginOnline(
        email: 'a@b.com',
        senha: 'segredo123',
        usuario: usuario,
        perfil: 'USUARIO',
      );

      final conteudo = store.values.join(' ');
      expect(conteudo.contains('segredo123'), isFalse,
          reason: 'A senha nao pode ser gravada em texto puro.');
    });
  });

  // ===========================================================
  // OUTBOX + CACHE LOCAL (OfflineCacheService)
  // ===========================================================
  group('OfflineCacheService (outbox + cache)', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('hive_offline_test');
      Hive.init(dir.path);
      await Hive.openBox(OfflineCacheService.boxOutbox);
      await Hive.openBox(OfflineCacheService.boxReservas);
      await Hive.openBox(OfflineCacheService.boxPending);
      await Hive.openBox(OfflineCacheService.boxMeta);
    });

    tearDown(() async {
      await Hive.close();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('enfileira e lista mutacoes em ordem FIFO', () async {
      final id1 = await OfflineCacheService.enqueueOutbox(
        entidade: 'reserva',
        operacao: 'criar',
        payload: {'ativo_id': 'a1'},
      );
      await Future<void>.delayed(const Duration(milliseconds: 3));
      final id2 = await OfflineCacheService.enqueueOutbox(
        entidade: 'reserva',
        operacao: 'cancelar',
        payload: {'endpoint': '/reservas/r1/cancelar', 'metodo': 'PATCH'},
      );

      final ops = OfflineCacheService.listOutbox();
      expect(ops.length, 2);
      expect(OfflineCacheService.outboxCount(), 2);
      expect(ops.first['local_id'], id1);
      expect(ops.last['local_id'], id2);
      expect(ops.first['entidade'], 'reserva');
      expect(ops.first['operacao'], 'criar');
    });

    test('remove mutacao apos envio bem-sucedido', () async {
      final id = await OfflineCacheService.enqueueOutbox(
        entidade: 'cadastro',
        operacao: 'criar',
        payload: const {},
      );
      expect(OfflineCacheService.outboxCount(), 1);

      await OfflineCacheService.removeOutbox(id);
      expect(OfflineCacheService.outboxCount(), 0);
    });

    test('markOutboxAttempt incrementa tentativas e guarda o erro', () async {
      final id = await OfflineCacheService.enqueueOutbox(
        entidade: 'reserva',
        operacao: 'criar',
        payload: const {},
      );

      await OfflineCacheService.markOutboxAttempt(id, 'timeout');

      final op = OfflineCacheService.listOutbox().first;
      expect(op['tentativas'], 1);
      expect(op['ultimo_erro'], 'timeout');
    });

    test('upsert / get / remove de reserva no cache', () async {
      await OfflineCacheService.upsertReservaCache({
        'id': 'r1',
        'status': 'PENDENTE',
        'pendente_sync': true,
      });

      final r = OfflineCacheService.getReservaCacheById('r1');
      expect(r, isNotNull);
      expect(r!['status'], 'PENDENTE');

      await OfflineCacheService.removeReservaCache('r1');
      expect(OfflineCacheService.getReservaCacheById('r1'), isNull);
    });

    test('totalPendentes soma checklists pendentes + outbox', () async {
      await OfflineCacheService.enqueueOutbox(
        entidade: 'reserva',
        operacao: 'criar',
        payload: const {},
      );
      await OfflineCacheService.savePendingChecklist(
        reservaId: 'r1',
        etapa: 'RETIRADA',
        itens: const <Map<String, dynamic>>[],
      );

      expect(OfflineCacheService.totalPendentes(), 2);
    });
  });
}
