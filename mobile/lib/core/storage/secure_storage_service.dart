import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper para armazenamento seguro de tokens e usuário.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kUser = 'usuario_json';
  static const _kOffline = 'offline_session';

  static Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  static Future<String?> getAccessToken() => _storage.read(key: _kAccess);
  static Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);

  static Future<void> saveUser(String userJson) =>
      _storage.write(key: _kUser, value: userJson);

  static Future<String?> getUser() => _storage.read(key: _kUser);

  /// Marca que a sessao atual foi iniciada offline (sem tokens do backend).
  static Future<void> setOfflineFlag() =>
      _storage.write(key: _kOffline, value: 'true');

  static Future<bool> getOfflineFlag() async =>
      (await _storage.read(key: _kOffline)) == 'true';

  static Future<void> clearOfflineFlag() => _storage.delete(key: _kOffline);

  static Future<void> clearAll() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
    await _storage.delete(key: _kOffline);
  }
}
