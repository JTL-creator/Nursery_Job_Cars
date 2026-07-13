import '../models/usuario.dart';
import '../../core/network/api_client.dart';

class UsuarioService {
  static final _dio = ApiClient().dio;

  static Future<List<Usuario>> listar({String? perfil, String? q}) async {
    final resp = await _dio.get('/usuarios', queryParameters: {
      if (perfil != null) 'perfil': perfil,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return (resp.data['data'] as List)
        .map((e) => Usuario.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<Usuario>> responsaveis() => listar(perfil: 'RESPONSAVEL');
}
