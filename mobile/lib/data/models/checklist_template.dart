class ChecklistTemplateItem {
  final String id;
  final String chaveItem;
  final String descricao;
  final String tipoCampo; // texto, numero, booleano, selecao, data, observacao
  final bool obrigatorio;
  final int ordem;
  final List<String>? opcoes;

  const ChecklistTemplateItem({
    required this.id,
    required this.chaveItem,
    required this.descricao,
    required this.tipoCampo,
    required this.obrigatorio,
    required this.ordem,
    this.opcoes,
  });

  factory ChecklistTemplateItem.fromJson(Map<String, dynamic> json) {
    List<String>? opcoes;
    final opc = json['opcoes_json'];
    if (opc != null) {
      try {
        final map = opc is Map ? opc : (opc is String ? {} : {});
        if (map['opcoes'] is List) {
          opcoes = (map['opcoes'] as List).map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return ChecklistTemplateItem(
      id: json['id']?.toString() ?? '',
      chaveItem: json['chave_item']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      tipoCampo: json['tipo_campo']?.toString() ?? 'texto',
      obrigatorio: json['obrigatorio'] == true,
      ordem: (json['ordem'] as num?)?.toInt() ?? 0,
      opcoes: opcoes,
    );
  }
}

class ChecklistTemplate {
  final String id;
  final String tipoAtivo;
  final String etapa;
  final String nome;
  final int versao;
  final List<ChecklistTemplateItem> itens;
  final bool pendenteSync; // criado/editado offline, aguardando envio

  const ChecklistTemplate({
    required this.id,
    required this.tipoAtivo,
    required this.etapa,
    required this.nome,
    required this.versao,
    required this.itens,
    this.pendenteSync = false,
  });

  factory ChecklistTemplate.fromJson(Map<String, dynamic> json) {
    final itensRaw = json['itens'] as List? ?? [];
    return ChecklistTemplate(
      id: json['id']?.toString() ?? '',
      tipoAtivo: json['tipo_ativo']?.toString() ?? '',
      etapa: json['etapa']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      versao: (json['versao'] as num?)?.toInt() ?? 1,
      itens: itensRaw
          .map((e) => ChecklistTemplateItem.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      pendenteSync: json['pendente_sync'] == true,
    );
  }
}
