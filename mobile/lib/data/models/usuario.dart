class Usuario {
  final String id;
  final String nomeCompleto;
  final String? matricula;
  final String email;
  final String? telefone;
  final String? unidadeLotacao;
  final String? status;
  final String? perfil;

  const Usuario({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    this.matricula,
    this.telefone,
    this.unidadeLotacao,
    this.status,
    this.perfil,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id']?.toString() ?? '',
        nomeCompleto: json['nome_completo']?.toString() ?? '',
        matricula: json['matricula']?.toString(),
        email: json['email']?.toString() ?? '',
        telefone: json['telefone']?.toString(),
        unidadeLotacao: json['unidade_lotacao']?.toString(),
        status: json['status']?.toString(),
        perfil: json['perfil']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome_completo': nomeCompleto,
        'matricula': matricula,
        'email': email,
        'telefone': telefone,
        'unidade_lotacao': unidadeLotacao,
        'status': status,
        'perfil': perfil,
      };

  Usuario copyWith({String? perfil}) => Usuario(
        id: id,
        nomeCompleto: nomeCompleto,
        email: email,
        matricula: matricula,
        telefone: telefone,
        unidadeLotacao: unidadeLotacao,
        status: status,
        perfil: perfil ?? this.perfil,
      );
}
