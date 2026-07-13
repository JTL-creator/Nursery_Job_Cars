import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/checklist_template.dart';
import '../../../data/services/checklist_service.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pending_sync_chip.dart';
import '../../widgets/skeleton.dart';

const _tipos = {
  'VEICULO': 'Veiculo',
  'MAQUINA_AGRICOLA': 'Maquina Agricola',
  'IMPLEMENTO': 'Implemento',
};
const _etapas = {
  'RETIRADA': 'Retirada',
  'DEVOLUCAO': 'Devolucao',
};
const _campos = {
  'texto': 'Texto',
  'numero': 'Numero',
  'booleano': 'Sim/Nao',
  'selecao': 'Selecao',
  'data': 'Data',
  'observacao': 'Observacao',
};

/// Administracao de templates de check-list (somente ADMINISTRADOR).
class AdminTemplatesScreen extends StatefulWidget {
  const AdminTemplatesScreen({super.key});

  @override
  State<AdminTemplatesScreen> createState() => _AdminTemplatesScreenState();
}

class _AdminTemplatesScreenState extends State<AdminTemplatesScreen> {
  List<ChecklistTemplate> _templates = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final list = await ChecklistService.listarTemplates();
      if (mounted) setState(() => _templates = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.extractMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirForm({ChecklistTemplate? template}) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminTemplateFormScreen(template: template),
      ),
    );
    if (salvou == true) _carregar();
  }

  Future<void> _excluir(ChecklistTemplate tpl) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir template'),
        content: Text(
          'Desativar o template "${tpl.nome}"? Ele deixara de ser usado em novos check-lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ChecklistService.excluirTemplate(tpl.id);
      if (mounted) {
        context.read<SyncProvider>().onMutacaoOffline();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: const Text('Template desativado'),
          ),
        );
      }
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.extractMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Templates de check-list')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo template'),
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _carregando
            ? const ListSkeleton()
            : _templates.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.fact_check_outlined,
                        title: 'Nenhum template',
                        description: 'Toque em "Novo template" para criar.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _templates.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final t = _templates[i];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.gdmLime,
                          child: Icon(Icons.description_outlined,
                              color: AppColors.gdmBlue),
                        ),
                        title: Text(t.nome,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_tipos[t.tipoAtivo] ?? t.tipoAtivo} • '
                              '${_etapas[t.etapa] ?? t.etapa} • '
                              'v${t.versao} • ${t.itens.length} campos',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (t.pendenteSync)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: PendingSyncChip(compact: true),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 20, color: Colors.blue),
                              onPressed: () => _abrirForm(template: t),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red.shade700),
                              onPressed: () => _excluir(t),
                            ),
                          ],
                        ),
                        onTap: () => _abrirForm(template: t),
                      );
                    },
                  ),
      ),
    );
  }
}

class _ItemDraft {
  String descricao;
  String tipoCampo;
  bool obrigatorio;
  String opcoes; // separadas por virgula (apenas selecao)
  _ItemDraft({
    this.descricao = '',
    this.tipoCampo = 'texto',
    this.obrigatorio = false,
    this.opcoes = '',
  });
}

/// Formulario de criacao/edicao de template.
class AdminTemplateFormScreen extends StatefulWidget {
  final ChecklistTemplate? template;
  const AdminTemplateFormScreen({super.key, this.template});

  @override
  State<AdminTemplateFormScreen> createState() =>
      _AdminTemplateFormScreenState();
}

class _AdminTemplateFormScreenState extends State<AdminTemplateFormScreen> {
  final _nome = TextEditingController();
  String _tipo = 'VEICULO';
  String _etapa = 'RETIRADA';
  final List<_ItemDraft> _itens = [];
  bool _salvando = false;

  bool get _ehEdicao => widget.template != null;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t != null) {
      _nome.text = t.nome;
      _tipo = _tipos.containsKey(t.tipoAtivo) ? t.tipoAtivo : 'VEICULO';
      _etapa = _etapas.containsKey(t.etapa) ? t.etapa : 'RETIRADA';
      for (final it in t.itens) {
        _itens.add(_ItemDraft(
          descricao: it.descricao,
          tipoCampo: _campos.containsKey(it.tipoCampo) ? it.tipoCampo : 'texto',
          obrigatorio: it.obrigatorio,
          opcoes: (it.opcoes ?? []).join(', '),
        ));
      }
    }
    if (_itens.isEmpty) _itens.add(_ItemDraft());
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _mover(int index, int dir) {
    final alvo = index + dir;
    if (alvo < 0 || alvo >= _itens.length) return;
    setState(() {
      final tmp = _itens[index];
      _itens[index] = _itens[alvo];
      _itens[alvo] = tmp;
    });
  }

  Future<void> _salvar() async {
    final validos = _itens.where((i) => i.descricao.trim().isNotEmpty).toList();
    if (_nome.text.trim().isEmpty) {
      _msg('Informe o nome do template');
      return;
    }
    if (validos.isEmpty) {
      _msg('Adicione ao menos um campo com descricao');
      return;
    }
    for (final it in validos) {
      if (it.tipoCampo == 'selecao') {
        final opc = it.opcoes
            .split(',')
            .map((o) => o.trim())
            .where((o) => o.isNotEmpty)
            .toList();
        if (opc.isEmpty) {
          _msg('Campos de selecao precisam de opcoes');
          return;
        }
      }
    }

    final itensPayload = <Map<String, dynamic>>[];
    for (var i = 0; i < validos.length; i++) {
      final it = validos[i];
      itensPayload.add({
        'descricao': it.descricao.trim(),
        'tipo_campo': it.tipoCampo,
        'obrigatorio': it.obrigatorio,
        'ordem': i + 1,
        if (it.tipoCampo == 'selecao')
          'opcoes': it.opcoes
              .split(',')
              .map((o) => o.trim())
              .where((o) => o.isNotEmpty)
              .toList(),
      });
    }

    final dados = <String, dynamic>{
      'nome': _nome.text.trim(),
      'tipo_ativo': _tipo,
      'etapa': _etapa,
      'itens': itensPayload,
    };

    setState(() => _salvando = true);
    try {
      if (_ehEdicao) {
        await ChecklistService.atualizarTemplate(widget.template!.id, dados);
      } else {
        await ChecklistService.criarTemplate(dados);
      }
      if (!mounted) return;
      context.read<SyncProvider>().onMutacaoOffline();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(_ehEdicao ? 'Template atualizado' : 'Template criado'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _msg(ApiClient.extractMessage(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _msg(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red.shade700, content: Text(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ehEdicao ? 'Editar template' : 'Novo template'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nome,
            decoration: const InputDecoration(
              labelText: 'Nome do template *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: _tipos.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _tipo = v ?? 'VEICULO'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _etapa,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Etapa',
                    border: OutlineInputBorder(),
                  ),
                  items: _etapas.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _etapa = v ?? 'RETIRADA'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text('Campos do check-list',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.gdmBlue)),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _itens.add(_ItemDraft())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ..._itens.asMap().entries.map((entry) {
            final idx = entry.key;
            final it = entry.value;
            return _ItemEditor(
              key: ValueKey(it),
              item: it,
              index: idx,
              total: _itens.length,
              onChanged: () => setState(() {}),
              onRemover: () => setState(() => _itens.removeAt(idx)),
              onSubir: () => _mover(idx, -1),
              onDescer: () => _mover(idx, 1),
            );
          }),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _salvando ? null : _salvar,
            icon: _salvando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_ehEdicao ? 'Salvar alteracoes' : 'Criar template'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gdmBlue,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editor de um campo do template.
class _ItemEditor extends StatefulWidget {
  final _ItemDraft item;
  final int index;
  final int total;
  final VoidCallback onChanged;
  final VoidCallback onRemover;
  final VoidCallback onSubir;
  final VoidCallback onDescer;

  const _ItemEditor({
    super.key,
    required this.item,
    required this.index,
    required this.total,
    required this.onChanged,
    required this.onRemover,
    required this.onSubir,
    required this.onDescer,
  });

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final TextEditingController _desc;
  late final TextEditingController _opc;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.item.descricao);
    _opc = TextEditingController(text: widget.item.opcoes);
  }

  @override
  void dispose() {
    _desc.dispose();
    _opc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.gdmBlue,
                  child: Text('${widget.index + 1}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: widget.index == 0 ? null : widget.onSubir,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed:
                      widget.index == widget.total - 1 ? null : widget.onDescer,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                  onPressed: widget.onRemover,
                ),
              ],
            ),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(
                labelText: 'Pergunta / campo',
                hintText: 'Ex.: Quilometragem inicial',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => it.descricao = v,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: it.tipoCampo,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de resposta',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _campos.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => it.tipoCampo = v ?? 'texto');
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Text('Obrig.', style: TextStyle(fontSize: 11)),
                    Switch(
                      value: it.obrigatorio,
                      onChanged: (v) => setState(() => it.obrigatorio = v),
                    ),
                  ],
                ),
              ],
            ),
            if (it.tipoCampo == 'selecao') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _opc,
                decoration: const InputDecoration(
                  labelText: 'Opcoes (separadas por virgula)',
                  hintText: 'Ex.: OK, Atencao, Trocar',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => it.opcoes = v,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
