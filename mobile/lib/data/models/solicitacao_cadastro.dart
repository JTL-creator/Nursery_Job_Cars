class SolicitacaoCadastro {
  final String? id;
  final String nomeCompleto;
  final String matricula;
  final String email;
  final String? telefone;
  final String? unidadeLotacao;
  final String? justificativa;
  final String? status;
  final String? criadoEm;

  const SolicitacaoCadastro({
    this.id,
    required this.nomeCompleto,
    required this.matricula,
    required this.email,
    this.telefone,
    this.unidadeLotacao,
    this.justificativa,
    this.status,
    this.criadoEm,
  });

  factory SolicitacaoCadastro.fromJson(Map<String, dynamic> json) =>
      SolicitacaoCadastro(
        id: json['id']?.toString(),
        nomeCompleto: json['nome_completo']?.toString() ?? '',
        matricula: json['matricula']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        telefone: json['telefone']?.toString(),
        unidadeLotacao: json['unidade_lotacao']?.toString(),
        justificativa: json['justificativa']?.toString(),
        status: json['status']?.toString(),
        criadoEm: json['criado_em']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'nome_completo': nomeCompleto,
        'matricula': matricula,
        'email': email,
        if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
        if (unidadeLotacao != null && unidadeLotacao!.isNotEmpty)
          'unidade_lotacao': unidadeLotacao,
        if (justificativa != null && justificativa!.isNotEmpty)
          'justificativa': justificativa,
      };
}
