class Reserva {
  final String id;
  final String usuarioId;
  final String ativoId;
  final DateTime dataHoraInicio;
  final DateTime dataHoraFim;
  final String status;
  final String? motivo;
  final String? observacoes;
  final DateTime? criadoEm;
  final DateTime? confirmadoEm;
  final DateTime? canceladoEm;
  final String? motivoRejeicao;

  // Dados do JOIN (vem do backend)
  final String? codigoInterno;
  final String? ativoDescricao;
  final String? tipoAtivo;
  final String? placa;
  final String? usuarioNome;
  final String? responsavelId;
  final bool pendenteSync; // criada/alterada offline, aguardando envio

  const Reserva({
    required this.id,
    required this.usuarioId,
    required this.ativoId,
    required this.dataHoraInicio,
    required this.dataHoraFim,
    required this.status,
    this.motivo,
    this.observacoes,
    this.criadoEm,
    this.confirmadoEm,
    this.canceladoEm,
    this.motivoRejeicao,
    this.codigoInterno,
    this.ativoDescricao,
    this.tipoAtivo,
    this.placa,
    this.usuarioNome,
    this.responsavelId,
    this.pendenteSync = false,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
        id: json['id']?.toString() ?? '',
        usuarioId: json['usuario_id']?.toString() ?? '',
        ativoId: json['ativo_id']?.toString() ?? '',
        dataHoraInicio: DateTime.parse(json['data_hora_inicio'].toString()),
        dataHoraFim: DateTime.parse(json['data_hora_fim'].toString()),
        status: json['status']?.toString() ?? 'PENDENTE',
        motivo: json['motivo']?.toString(),
        observacoes: json['observacoes']?.toString(),
        criadoEm: json['criado_em'] != null
            ? DateTime.tryParse(json['criado_em'].toString())
            : null,
        confirmadoEm: json['confirmado_em'] != null
            ? DateTime.tryParse(json['confirmado_em'].toString())
            : null,
        canceladoEm: json['cancelado_em'] != null
            ? DateTime.tryParse(json['cancelado_em'].toString())
            : null,
        motivoRejeicao: json['motivo_rejeicao']?.toString(),
        codigoInterno: json['codigo_interno']?.toString(),
        ativoDescricao: json['ativo_descricao']?.toString(),
        tipoAtivo: json['tipo_ativo']?.toString(),
        placa: json['placa']?.toString(),
        usuarioNome: json['usuario_nome']?.toString(),
        responsavelId: json['responsavel_id']?.toString(),
        pendenteSync: json['pendente_sync'] == true,
      );

  bool get podeIniciar => status == 'CONFIRMADA';
  bool get podeConcluir => status == 'EM_USO';
  bool get podeCancelar => status == 'PENDENTE' || status == 'CONFIRMADA';
  bool get estaAtiva => ['CONFIRMADA', 'EM_USO', 'PENDENTE'].contains(status);
  bool get estaPendente => status == 'PENDENTE';
  bool get foiRejeitada => status == 'REJEITADA';

  String get tituloAtivo => '${codigoInterno ?? ""} - ${ativoDescricao ?? ""}';
}
