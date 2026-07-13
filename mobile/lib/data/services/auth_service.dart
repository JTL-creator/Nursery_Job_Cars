import '../models/login_response.dart';
import '../models/usuario.dart';
import '../../core/network/api_client.dart';

class AuthService {
  static final _dio = ApiClient().dio;

  static Future<LoginResponse> login(String email, String senha) async {
    final resp = await _dio.post('/auth/login', data: {
      'email': email,
      'senha': senha,
    });
    return LoginResponse.fromJson(
      Map<String, dynamic>.from(resp.data['data'] as Map),
    );
  }

  static Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {/* ignorar */}
  }

  static Future<Usuario> me() async {
    final resp = await _dio.get('/usuarios/me');
    return Usuario.fromJson(
      Map<String, dynamic>.from(resp.data['data'] as Map),
    );
  }
}
