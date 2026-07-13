import 'usuario.dart';

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;
  final Usuario usuario;
  final String perfil;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.usuario,
    required this.perfil,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['access_token']?.toString() ?? '',
        refreshToken: json['refresh_token']?.toString() ?? '',
        expiresIn: json['expires_in']?.toString() ?? '',
        usuario: Usuario.fromJson(
          Map<String, dynamic>.from(json['usuario'] as Map),
        ).copyWith(perfil: json['perfil']?.toString()),
        perfil: json['perfil']?.toString() ?? 'USUARIO',
      );
}
