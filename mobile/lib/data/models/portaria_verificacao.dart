/// Resultado da verificacao de liberacao de saida na portaria (por placa).
class PortariaVerificacao {
  final bool encontrado;
  final String placa;
  final bool liberado;

  // Conferencias individuais
  final bool reservaAprovada;
  final bool checklistRetirada;
  final bool dentroJanela;

  final List<String> motivos;

  // Dados do veiculo (quando encontrado)
  final String? ativoId;
  final String? ativoCodigo;
  final String? ativoDescricao;
  final String? ativoTipo;
  final String? ativoPlaca;
  final String? unidade;
  final String? responsavelNome;

  // Dados da reserva vigente (quando existe)
  final String? reservaId;
  final String? reservaStatus;
  final String? usuarioNome;
  final String? motivoReserva;
  final DateTime? inicio;
  final DateTime? fim;

  const PortariaVerificacao({
    required this.encontrado,
    required this.placa,
    required this.liberado,
    required this.reservaAprovada,
    required this.checklistRetirada,
    required this.dentroJanela,
    required this.motivos,
    this.ativoId,
    this.ativoCodigo,
    this.ativoDescricao,
    this.ativoTipo,
    this.ativoPlaca,
    this.unidade,
    this.responsavelNome,
    this.reservaId,
    this.reservaStatus,
    this.usuarioNome,
    this.motivoReserva,
    this.inicio,
    this.fim,
  });

  factory PortariaVerificacao.fromJson(Map<String, dynamic> json) {
    final checks = json['checks'] is Map
        ? Map<String, dynamic>.from(json['checks'] as Map)
        : const <String, dynamic>{};
    final ativo = json['ativo'] is Map
        ? Map<String, dynamic>.from(json['ativo'] as Map)
        : const <String, dynamic>{};
    final reserva = json['reserva'] is Map
        ? Map<String, dynamic>.from(json['reserva'] as Map)
        : const <String, dynamic>{};

    DateTime? parseData(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return PortariaVerificacao(
      encontrado: json['encontrado'] == true,
      placa: json['placa']?.toString() ?? '',
      liberado: json['liberado'] == true,
      reservaAprovada: checks['reserva_aprovada'] == true,
      checklistRetirada: checks['checklist_retirada'] == true,
      dentroJanela: checks['dentro_janela'] == true,
      motivos: (json['motivos'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      ativoId: ativo['id']?.toString(),
      ativoCodigo: ativo['codigo_interno']?.toString(),
      ativoDescricao: ativo['descricao']?.toString(),
      ativoTipo: ativo['tipo_ativo']?.toString(),
      ativoPlaca: ativo['placa']?.toString(),
      unidade: ativo['unidade']?.toString(),
      responsavelNome: ativo['responsavel_nome']?.toString(),
      reservaId: reserva['id']?.toString(),
      reservaStatus: reserva['status']?.toString(),
      usuarioNome: reserva['usuario_nome']?.toString(),
      motivoReserva: reserva['motivo']?.toString(),
      inicio: parseData(reserva['data_hora_inicio']),
      fim: parseData(reserva['data_hora_fim']),
    );
  }
}

/// Registro de movimentacao de portaria (log de saida/entrada).
class MovimentacaoPortaria {
  final String id;
  final String tipo; // SAIDA | ENTRADA
  final String? placa;
  final bool liberado;
  final String? motivo;
  final String? observacoes;
  final String? ativoCodigo;
  final String? ativoDescricao;
  final String? vigilanteNome;
  final DateTime? criadoEm;

  const MovimentacaoPortaria({
    required this.id,
    required this.tipo,
    this.placa,
    required this.liberado,
    this.motivo,
    this.observacoes,
    this.ativoCodigo,
    this.ativoDescricao,
    this.vigilanteNome,
    this.criadoEm,
  });

  factory MovimentacaoPortaria.fromJson(Map<String, dynamic> json) =>
      MovimentacaoPortaria(
        id: json['id']?.toString() ?? '',
        tipo: json['tipo']?.toString() ?? '',
        placa: json['placa']?.toString(),
        liberado: json['liberado'] != false,
        motivo: json['motivo']?.toString(),
        observacoes: json['observacoes']?.toString(),
        ativoCodigo: json['codigo_interno']?.toString(),
        ativoDescricao: json['ativo_descricao']?.toString(),
        vigilanteNome: json['vigilante_nome']?.toString(),
        criadoEm: json['criado_em'] != null
            ? DateTime.tryParse(json['criado_em'].toString())
            : null,
      );
}
