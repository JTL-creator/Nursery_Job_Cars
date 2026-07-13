import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_auth_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/usuario.dart';
import '../../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Usuario? _user;
  String? _perfil;
  bool _loading = true;

  bool _offline = false;

  Usuario? get user => _user;
  String? get perfil => _perfil;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  /// Sessao iniciada sem backend (login offline).
  bool get isOffline => _offline;

  /// Perfis que podem aprovar/rejeitar reservas.
  bool get podeAprovar =>
      _perfil == 'RESPONSAVEL' ||
      _perfil == 'ADMINISTRADOR' ||
      _perfil == 'GERENTE';

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    try {
      final token = await SecureStorageService.getAccessToken();
      final offline = await SecureStorageService.getOfflineFlag();
      final cached = await SecureStorageService.getUser();
      if (cached != null && (token != null || offline)) {
        _user = Usuario.fromJson(
          Map<String, dynamic>.from(jsonDecode(cached) as Map),
        );
        _perfil = _user?.perfil;
        _offline = offline;
        // So tenta atualizar do backend se houver token real (sessao online).
        if (token != null) {
          try {
            final fresh = await AuthService.me();
            _user = fresh.copyWith(perfil: _perfil ?? fresh.perfil);
            _perfil = _user?.perfil ?? _perfil;
            _offline = false;
            await SecureStorageService.saveUser(jsonEncode(_user!.toJson()));
          } catch (_) {/* mantem cache offline */}
        }
      }
    } catch (_) {
      await SecureStorageService.clearAll();
      _user = null;
      _perfil = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String senha) async {
    try {
      final resp = await AuthService.login(email, senha);
      await SecureStorageService.saveTokens(
          resp.accessToken, resp.refreshToken);
      await SecureStorageService.clearOfflineFlag();
      _user = resp.usuario.copyWith(perfil: resp.perfil);
      _perfil = resp.perfil;
      _offline = false;
      await SecureStorageService.saveUser(jsonEncode(_user!.toJson()));
      // Guarda credencial para permitir login offline futuro.
      await LocalAuthService.registrarLoginOnline(
        email: email,
        senha: senha,
        usuario: _user!,
        perfil: _perfil!,
      );
      notifyListeners();
    } on DioException catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      await _loginOffline(email, senha);
    }
  }

  /// Fallback: autentica localmente quando o backend esta inacessivel.
  Future<void> _loginOffline(String email, String senha) async {
    final cred = await LocalAuthService.autenticarOffline(email, senha);
    if (cred == null) {
      throw Exception(
        'Sem conexao com o servidor. Este usuario ainda nao possui acesso '
        'offline salvo neste dispositivo. Conecte-se a internet no primeiro '
        'login para habilitar o modo offline.',
      );
    }
    _user = cred.usuario.copyWith(perfil: cred.perfil);
    _perfil = cred.perfil;
    _offline = true;
    await SecureStorageService.saveUser(jsonEncode(_user!.toJson()));
    await SecureStorageService.setOfflineFlag();
    notifyListeners();
  }

  Future<void> logout() async {
    if (!_offline) {
      await AuthService.logout();
    }
    await SecureStorageService.clearAll();
    _user = null;
    _perfil = null;
    _offline = false;
    notifyListeners();
  }
}
