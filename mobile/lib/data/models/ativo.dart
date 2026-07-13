class Ativo {
  final String id;
  final String codigoInterno;
  final String descricao;
  final String tipoAtivo;
  final String? subTipo;
  final String? placa;
  final String? patrimonio;
  final String? unidade;
  final String status;
  final String? observacoes;
  final String? responsavelId;
  final String? responsavelNome;
  final String? equipe;
  final String? fotoUrl;
  final bool? disponivel; // calculado pelo endpoint de disponibilidade
  final bool pendenteSync; // criado/editado offline, aguardando envio

  const Ativo({
    required this.id,
    required this.codigoInterno,
    required this.descricao,
    required this.tipoAtivo,
    required this.status,
    this.subTipo,
    this.placa,
    this.patrimonio,
    this.unidade,
    this.observacoes,
    this.responsavelId,
    this.responsavelNome,
    this.equipe,
    this.fotoUrl,
    this.disponivel,
    this.pendenteSync = false,
  });

  factory Ativo.fromJson(Map<String, dynamic> json) => Ativo(
        id: json['id']?.toString() ?? '',
        codigoInterno: json['codigo_interno']?.toString() ?? '',
        descricao: json['descricao']?.toString() ?? '',
        tipoAtivo: json['tipo_ativo']?.toString() ?? '',
        status: json['status']?.toString() ?? 'DISPONIVEL',
        subTipo: json['sub_tipo']?.toString(),
        placa: json['placa']?.toString(),
        patrimonio: json['patrimonio']?.toString(),
        unidade: json['unidade']?.toString(),
        observacoes: json['observacoes']?.toString(),
        responsavelId: json['responsavel_id']?.toString(),
        responsavelNome: json['responsavel_nome']?.toString(),
        equipe: json['equipe']?.toString(),
        fotoUrl: json['foto_url']?.toString(),
        disponivel: json['disponivel'] as bool?,
        pendenteSync: json['pendente_sync'] == true,
      );

  /// Categoria de alto nivel: 'veiculos' ou 'maquinas'
  /// (IMPLEMENTO agrupa com maquinas).
  String get categoria => tipoAtivo == 'VEICULO' ? 'veiculos' : 'maquinas';

  bool get temResponsavel => responsavelId != null && responsavelId!.isNotEmpty;

  String get tipoLabel {
    switch (tipoAtivo) {
      case 'VEICULO':
        return 'Veiculo';
      case 'MAQUINA_AGRICOLA':
        return 'Maquina Agricola';
      case 'IMPLEMENTO':
        return 'Implemento';
      default:
        return tipoAtivo;
    }
  }

  String get tituloCompleto =>
      '$codigoInterno - $descricao${placa != null ? ' ($placa)' : ''}';
}
