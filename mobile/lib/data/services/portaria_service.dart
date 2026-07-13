import '../models/portaria_verificacao.dart';
import '../../core/network/api_client.dart';

/// Servico da portaria: conferencia de liberacao de saida e registro de
/// movimentacoes (saida/entrada) dos veiculos. Consumido por vigilantes.
///
/// Requer conexao com o backend (nao ha modo offline para a portaria, pois a
/// conferencia depende do estado atual das reservas e check-lists).
class PortariaService {
  static final _dio = ApiClient().dio;

  /// Verifica se o veiculo (pela placa) esta liberado para sair da unidade.
  /// Retorna as conferencias (reserva aprovada, check-list de retirada e
  /// janela de horario) e os dados do veiculo/reserva vigente.
  static Future<PortariaVerificacao> verificar(String placa) async {
    final resp = await _dio.get(
      '/portaria/verificar',
      queryParameters: {'placa': placa},
    );
    return PortariaVerificacao.fromJson(
      Map<String, dynamic>.from(resp.data['data'] as Map),
    );
  }

  /// Registra uma movimentacao de portaria (SAIDA ou ENTRADA).
  static Future<void> registrarMovimentacao({
    required String ativoId,
    String? reservaId,
    required String tipo,
    String? placa,
    required bool liberado,
    String? motivo,
    String? observacoes,
  }) async {
    await _dio.post('/portaria/movimentacoes', data: {
      'ativo_id': ativoId,
      if (reservaId != null) 'reserva_id': reservaId,
      'tipo': tipo,
      if (placa != null) 'placa': placa,
      'liberado': liberado,
      if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
      if (observacoes != null && observacoes.isNotEmpty)
        'observacoes': observacoes,
    });
  }

  /// Lista o historico de movimentacoes de portaria.
  static Future<List<MovimentacaoPortaria>> historico({
    String? tipo,
    int limit = 30,
  }) async {
    final resp = await _dio.get('/portaria/movimentacoes', queryParameters: {
      if (tipo != null) 'tipo': tipo,
      'limit': limit,
    });
    return (resp.data['data'] as List)
        .map((e) =>
            MovimentacaoPortaria.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
