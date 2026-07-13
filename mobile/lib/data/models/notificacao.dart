class Notificacao {
  final String id;
  final String tipo;
  final String titulo;
  final String? mensagem;
  final String? entidade;
  final String? entidadeId;
  final bool lida;
  final DateTime? criadoEm;

  const Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.mensagem,
    this.entidade,
    this.entidadeId,
    this.lida = false,
    this.criadoEm,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) => Notificacao(
        id: json['id']?.toString() ?? '',
        tipo: json['tipo']?.toString() ?? '',
        titulo: json['titulo']?.toString() ?? '',
        mensagem: json['mensagem']?.toString(),
        entidade: json['entidade']?.toString(),
        entidadeId: json['entidade_id']?.toString(),
        lida: json['lida'] == true,
        criadoEm: json['criado_em'] != null
            ? DateTime.tryParse(json['criado_em'].toString())
            : null,
      );

  bool get ehAprovacao => tipo == 'APROVACAO_RESERVA';
}
