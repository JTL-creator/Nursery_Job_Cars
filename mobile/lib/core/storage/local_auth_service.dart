import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/usuario.dart';

/// Credencial local verificada offline (sem backend).
class LocalCredential {
  final Usuario usuario;
  final String perfil;

  const LocalCredential({required this.usuario, required this.perfil});
}

/// Armazena de forma segura as credenciais necessarias para autenticar
/// o usuario **sem conexao** com o backend.
///
/// Estrategia: no primeiro login online bem-sucedido guardamos, por e-mail,
/// um hash derivado da senha via PBKDF2-HMAC-SHA256 (com salt aleatorio e
/// muitas iteracoes) + um snapshot do usuario. Em seguida, se o backend
/// estiver indisponivel, validamos a senha digitada contra esse hash e
/// liberamos o acesso usando o snapshot cacheado.
///
/// A senha em texto puro nunca e persistida.
class LocalAuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Guarda um mapa { emailLower: { algo, iter, salt, hash, perfil, ... } }.
  static const _kCredentials = 'offline_credentials';

  /// Numero de iteracoes do PBKDF2 (equilibrio seguranca x desempenho no device).
  static const int _iteracoes = 50000;
  static const int _tamChave = 32; // bytes derivados (SHA-256)

  static String _norm(String email) => email.trim().toLowerCase();

  /// Deriva a chave da senha com PBKDF2-HMAC-SHA256 (RFC 2898), 1 bloco.
  static String _hash(String senha, List<int> salt, int iteracoes) {
    final hmac = Hmac(sha256, utf8.encode(senha));
    // U1 = PRF(senha, salt || INT_32_BE(1))
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final resultado = List<int>.from(u);
    for (var i = 1; i < iteracoes; i++) {
      u = hmac.convert(u).bytes;
      for (var k = 0; k < resultado.length; k++) {
        resultado[k] ^= u[k];
      }
    }
    return base64.encode(resultado.sublist(0, _tamChave));
  }

  static List<int> _gerarSaltBytes() {
    final rnd = Random.secure();
    return List<int>.generate(16, (_) => rnd.nextInt(256));
  }

  static Future<Map<String, dynamic>> _readAll() async {
    final raw = await _storage.read(key: _kCredentials);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeAll(Map<String, dynamic> data) async {
    await _storage.write(key: _kCredentials, value: jsonEncode(data));
  }

  /// Registra/atualiza a credencial offline apos um login online bem-sucedido.
  static Future<void> registrarLoginOnline({
    required String email,
    required String senha,
    required Usuario usuario,
    required String perfil,
  }) async {
    final all = await _readAll();
    final salt = _gerarSaltBytes();
    all[_norm(email)] = {
      'algo': 'pbkdf2-sha256',
      'iter': _iteracoes,
      'salt': base64.encode(salt),
      'hash': _hash(senha, salt, _iteracoes),
      'perfil': perfil,
      'usuario_json': jsonEncode(usuario.toJson()),
      'atualizado_em': DateTime.now().toIso8601String(),
    };
    await _writeAll(all);
  }

  /// Tenta autenticar offline. Retorna a credencial se a senha conferir,
  /// ou `null` se nao houver registro/senha incorreta/formato antigo.
  static Future<LocalCredential?> autenticarOffline(
    String email,
    String senha,
  ) async {
    final all = await _readAll();
    final entry = all[_norm(email)];
    if (entry == null) return null;

    final m = Map<String, dynamic>.from(entry as Map);
    // So aceita o formato PBKDF2. Credenciais antigas (se houver) exigem um
    // novo login online para serem regravadas com seguranca.
    if (m['algo'] != 'pbkdf2-sha256') return null;

    final saltB64 = m['salt']?.toString() ?? '';
    final hash = m['hash']?.toString() ?? '';
    final iter = (m['iter'] as num?)?.toInt() ?? _iteracoes;
    if (saltB64.isEmpty || hash.isEmpty) return null;

    final salt = base64.decode(saltB64);
    if (_hash(senha, salt, iter) != hash) return null;

    final usuario = Usuario.fromJson(
      Map<String, dynamic>.from(jsonDecode(m['usuario_json'] as String) as Map),
    );
    final perfil = m['perfil']?.toString() ?? usuario.perfil ?? 'USUARIO';
    return LocalCredential(usuario: usuario, perfil: perfil);
  }

  /// Indica se existe alguma credencial offline registrada para o e-mail.
  static Future<bool> temCredencial(String email) async {
    final all = await _readAll();
    return all.containsKey(_norm(email));
  }

  /// Remove todas as credenciais offline (ex.: logout total do dispositivo).
  static Future<void> limpar() async {
    await _storage.delete(key: _kCredentials);
  }
}
