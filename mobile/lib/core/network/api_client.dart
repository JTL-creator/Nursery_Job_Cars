import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorageService.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        final status = err.response?.statusCode;
        final code =
            err.response?.data is Map ? err.response?.data['error_code'] : null;

        // Token expirado: tenta refresh automaticamente
        final tokenInvalido = (status == 401) ||
            (code == 'AUTH_003') ||
            (code == 'AUTH_001' && err.requestOptions.path != '/auth/login');

        if (tokenInvalido && err.requestOptions.extra['retried'] != true) {
          try {
            final refresh = await SecureStorageService.getRefreshToken();
            if (refresh == null || refresh.isEmpty) {
              throw Exception('Sem refresh token');
            }

            // Dio limpo (sem interceptor) para nao loopar
            final dioRefresh = Dio(BaseOptions(
              baseUrl: AppConstants.apiBaseUrl,
              headers: {'Content-Type': 'application/json'},
            ));

            final resp = await dioRefresh.post(
              '/auth/refresh',
              data: {'refresh_token': refresh},
            );

            final newAccess = resp.data?['data']?['access_token'] as String?;
            if (newAccess == null || newAccess.isEmpty) {
              throw Exception('Resposta de refresh invalida');
            }

            // Salva o novo token (refresh permanece o mesmo)
            await SecureStorageService.saveTokens(newAccess, refresh);

            // Refaz a request original com o novo token
            final req = err.requestOptions;
            req.headers['Authorization'] = 'Bearer $newAccess';
            req.extra['retried'] = true;

            final retried = await _dio.fetch(req);
            return handler.resolve(retried);
          } catch (_) {
            // Refresh falhou: limpa tudo (forca novo login)
            await SecureStorageService.clearAll();
          }
        }
        handler.next(err);
      },
    ));
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  /// Indica se o erro decorre de falta de conexao com o backend
  /// (offline, timeout, servidor inacessivel).
  static bool isConnectionError(Object error) {
    if (error is! DioException) return false;
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        return error.error is SocketException;
      default:
        return false;
    }
  }

  /// Extrai mensagem amigavel de um DioException.
  static String extractMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final code = data['error_code']?.toString();
        final msg = data['message']?.toString();

        // Mensagens amigaveis por codigo
        if (code == 'AUTH_003') {
          return 'Sua sessao expirou. Faca login novamente.';
        }
        if (code == 'AUTH_001') {
          return 'Email ou senha incorretos.';
        }
        if (code == 'AUTH_002') {
          return 'Usuario inativo. Contate o administrador.';
        }
        if (code == 'PERM_001') {
          return 'Voce nao tem permissao para esta acao.';
        }
        if (code == 'RES_001') {
          return 'Ja existe uma reserva no periodo selecionado.';
        }
        if (code == 'RES_002') {
          return 'Periodo invalido. Verifique as datas.';
        }

        return msg ?? code ?? 'Erro ao processar requisicao.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Sem conexao com o servidor. Verifique sua internet.';
      }
      return error.message ?? 'Erro de comunicacao';
    }
    return error.toString();
  }
}
