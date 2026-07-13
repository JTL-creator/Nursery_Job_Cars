/// Constantes globais da aplicação.
class AppConstants {
  /// URL base da API.
  ///
  /// Pode ser definida no build sem alterar o codigo, via:
  ///   flutter run  --dart-define=API_BASE_URL=https://seu-backend/api/v1
  ///   flutter build apk --release --dart-define=API_BASE_URL=https://seu-backend/api/v1
  ///
  /// Sem a variavel, usa localhost (dev via `adb reverse tcp:5000 tcp:5000`).
  static const String _apiBaseUrlEnv =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl {
    if (_apiBaseUrlEnv.isNotEmpty) return _apiBaseUrlEnv;
    return 'http://localhost:5000/api/v1';
  }

  static const String appName = 'GDM Job Cars';
  static const String appVersion = '0.1.0';
  static const Duration apiTimeout = Duration(seconds: 15);

  /// Resolve a URL completa de um arquivo enviado (ex.: /uploads/ativos/x.jpg).
  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final origin = apiBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    return '$origin${path.startsWith('/') ? '' : '/'}$path';
  }
}
