import '../models/solicitacao_cadastro.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/offline_cache_service.dart';

class CadastroService {
  static final _dio = ApiClient().dio;

  static Future<SolicitacaoCadastro> criarSolicitacao(
      SolicitacaoCadastro s) async {
    try {
      final resp = await _dio.post(
        '/cadastros/solicitacoes',
        data: s.toJson(),
      );
      return SolicitacaoCadastro.fromJson(
        Map<String, dynamic>.from(resp.data['data'] as Map),
      );
    } catch (e) {
      if (!ApiClient.isConnectionError(e)) rethrow;
      // Offline: enfileira o envio para quando houver conexao.
      await OfflineCacheService.enqueueOutbox(
        entidade: 'cadastro',
        operacao: 'criar',
        payload: {
          'endpoint': '/cadastros/solicitacoes',
          'metodo': 'POST',
          'body': s.toJson(),
        },
      );
      return SolicitacaoCadastro.fromJson({
        ...s.toJson(),
        'status': 'PENDENTE',
      });
    }
  }
}
