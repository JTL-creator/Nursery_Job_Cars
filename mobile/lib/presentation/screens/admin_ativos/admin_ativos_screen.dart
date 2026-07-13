import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ativo.dart';
import '../../../data/models/usuario.dart';
import '../../../data/services/ativo_service.dart';
import '../../../data/services/usuario_service.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pending_sync_chip.dart';
import '../../widgets/skeleton.dart';

/// Tela de administracao de ativos (somente ADMINISTRADOR).
/// Permite cadastrar veiculos/maquinas e definir o responsavel pela aprovacao.
class AdminAtivosScreen extends StatefulWidget {
  const AdminAtivosScreen({super.key});

  @override
  State<AdminAtivosScreen> createState() => _AdminAtivosScreenState();
}

class _AdminAtivosScreenState extends State<AdminAtivosScreen> {
  List<Ativo> _ativos = [];
  bool _carregando = true;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final list = await AtivoService.listar(q: _busca.isEmpty ? null : _busca);
      if (mounted) setState(() => _ativos = list);
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

  Future<void> _abrirForm({Ativo? ativo}) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminAtivoFormScreen(ativo: ativo)),
    );
    if (salvou == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administracao de ativos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo ativo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por codigo ou descricao...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _busca.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _busca = '');
                          _carregar();
                        },
                      ),
              ),
              onChanged: (v) => _busca = v,
              onSubmitted: (_) => _carregar(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregar,
              child: _carregando
                  ? const ListSkeleton()
                  : _ativos.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: 'Nenhum ativo',
                              description:
                                  'Toque em "Novo ativo" para cadastrar.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _ativos.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final a = _ativos[i];
                            return ListTile(
                              leading: _AtivoThumb(ativo: a),
                              title: Text(a.codigoInterno,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.descricao),
                                  if (a.equipe != null && a.equipe!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.gdmLime
                                              .withValues(alpha: 0.25),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          a.equipe!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.gdmBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    a.temResponsavel
                                        ? 'Responsavel: ${a.responsavelNome ?? "definido"}'
                                        : 'Sem responsavel',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: a.temResponsavel
                                          ? Colors.green.shade700
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (a.pendenteSync)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: PendingSyncChip(compact: true),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.edit, size: 18),
                              onTap: () => _abrirForm(ativo: a),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulario de criacao/edicao de ativo.
class AdminAtivoFormScreen extends StatefulWidget {
  final Ativo? ativo;
  const AdminAtivoFormScreen({super.key, this.ativo});

  @override
  State<AdminAtivoFormScreen> createState() => _AdminAtivoFormScreenState();
}

class _AdminAtivoFormScreenState extends State<AdminAtivoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _descricao = TextEditingController();
  final _subTipo = TextEditingController();
  final _placa = TextEditingController();
  final _patrimonio = TextEditingController();
  final _unidade = TextEditingController();
  final _equipe = TextEditingController();
  final _observacoes = TextEditingController();

  String _tipo = 'VEICULO';
  String _status = 'DISPONIVEL';
  String? _responsavelId;
  String? _fotoUrl;
  bool _enviandoFoto = false;

  List<Usuario> _responsaveis = [];
  bool _salvando = false;

  static const _tipos = {
    'VEICULO': 'Veiculo',
    'MAQUINA_AGRICOLA': 'Maquina Agricola',
    'IMPLEMENTO': 'Implemento',
  };
  static const _statuses = {
    'DISPONIVEL': 'Disponivel',
    'RESERVADO': 'Reservado',
    'MANUTENCAO': 'Manutencao',
    'INDISPONIVEL': 'Indisponivel',
  };

  bool get _ehEdicao => widget.ativo != null;

  @override
  void initState() {
    super.initState();
    final a = widget.ativo;
    if (a != null) {
      _codigo.text = a.codigoInterno;
      _descricao.text = a.descricao;
      _subTipo.text = a.subTipo ?? '';
      _placa.text = a.placa ?? '';
      _patrimonio.text = a.patrimonio ?? '';
      _unidade.text = a.unidade ?? '';
      _equipe.text = a.equipe ?? '';
      _observacoes.text = a.observacoes ?? '';
      _tipo = _tipos.containsKey(a.tipoAtivo) ? a.tipoAtivo : 'VEICULO';
      _status = _statuses.containsKey(a.status) ? a.status : 'DISPONIVEL';
      _responsavelId = a.responsavelId;
      _fotoUrl = a.fotoUrl;
    }
    _carregarResponsaveis();
  }

  Future<void> _carregarResponsaveis() async {
    try {
      final list = await UsuarioService.responsaveis();
      if (mounted) setState(() => _responsaveis = list);
    } catch (_) {/* segue sem lista */}
  }

  Future<void> _selecionarFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;
      setState(() => _enviandoFoto = true);
      final url = await AtivoService.uploadFoto(File(picked.path));
      if (mounted) setState(() => _fotoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(ApiClient.extractMessage(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  @override
  void dispose() {
    _codigo.dispose();
    _descricao.dispose();
    _subTipo.dispose();
    _placa.dispose();
    _patrimonio.dispose();
    _unidade.dispose();
    _equipe.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final dados = <String, dynamic>{
      'codigo_interno': _codigo.text.trim(),
      'descricao': _descricao.text.trim(),
      'tipo_ativo': _tipo,
      'sub_tipo': _subTipo.text.trim(),
      'placa': _placa.text.trim(),
      'patrimonio': _patrimonio.text.trim(),
      'unidade': _unidade.text.trim(),
      'equipe': _equipe.text.trim(),
      'observacoes': _observacoes.text.trim(),
      'responsavel_id': _responsavelId ?? '',
      'foto_url': _fotoUrl ?? '',
    };
    if (!_ehEdicao) {
      dados['status'] = _status;
    }
    try {
      if (_ehEdicao) {
        await AtivoService.atualizar(widget.ativo!.id, dados);
        // status alterado separadamente na edicao
        if (_status != widget.ativo!.status) {
          await AtivoService.atualizarStatusRemoto(widget.ativo!.id, _status);
        }
      } else {
        await AtivoService.criar(dados);
      }
      if (!mounted) return;
      context.read<SyncProvider>().onMutacaoOffline();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(_ehEdicao ? 'Ativo atualizado' : 'Ativo criado'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(ApiClient.extractMessage(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_ehEdicao ? 'Editar ativo' : 'Novo ativo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codigo,
              decoration: const InputDecoration(
                labelText: 'Codigo interno *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o codigo' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricao,
              decoration: const InputDecoration(
                labelText: 'Descricao *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Informe a descricao'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo *',
                border: OutlineInputBorder(),
              ),
              items: _tipos.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v ?? 'VEICULO'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: _statuses.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? 'DISPONIVEL'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _placa,
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _patrimonio,
                    decoration: const InputDecoration(
                      labelText: 'Patrimonio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subTipo,
              decoration: const InputDecoration(
                labelText: 'Sub-tipo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unidade,
              decoration: const InputDecoration(
                labelText: 'Unidade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _equipe,
              decoration: const InputDecoration(
                labelText: 'Time / Equipe',
                hintText: 'Milho, Soja, Agronomia...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _FotoPicker(
              fotoUrl: _fotoUrl,
              enviando: _enviandoFoto,
              onSelecionar: _selecionarFoto,
              onRemover: () => setState(() => _fotoUrl = null),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: ValueKey('resp-${_responsaveis.length}'),
              initialValue: (_responsavelId != null &&
                      _responsaveis.any((u) => u.id == _responsavelId))
                  ? _responsavelId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Responsavel pela aprovacao',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sem responsavel (confirma automatico)'),
                ),
                ..._responsaveis.map((u) => DropdownMenuItem<String?>(
                      value: u.id,
                      child: Text(
                        u.nomeCompleto,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: (v) => setState(() => _responsavelId = v),
            ),
            const SizedBox(height: 6),
            const Text(
              'Se definido, as reservas deste ativo ficam pendentes ate a aprovacao do responsavel.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacoes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observacoes',
                border: OutlineInputBorder(),
              ),
            ),
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
              label: Text(_ehEdicao ? 'Salvar alteracoes' : 'Criar ativo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gdmBlue,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Miniatura do ativo na lista: foto quando houver, senao icone do tipo.
class _AtivoThumb extends StatelessWidget {
  final Ativo ativo;
  const _AtivoThumb({required this.ativo});

  IconData get _icone => ativo.tipoAtivo == 'VEICULO'
      ? Icons.directions_car
      : ativo.tipoAtivo == 'MAQUINA_AGRICOLA'
          ? Icons.agriculture
          : Icons.build;

  @override
  Widget build(BuildContext context) {
    final temFoto = ativo.fotoUrl != null && ativo.fotoUrl!.isNotEmpty;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: temFoto
          ? Image.network(
              AppConstants.mediaUrl(ativo.fotoUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(_icone, color: AppColors.gdmBlue),
            )
          : Icon(_icone, color: AppColors.gdmBlue),
    );
  }
}

/// Selecao/preview da foto do ativo.
class _FotoPicker extends StatelessWidget {
  final String? fotoUrl;
  final bool enviando;
  final VoidCallback onSelecionar;
  final VoidCallback onRemover;

  const _FotoPicker({
    required this.fotoUrl,
    required this.enviando,
    required this.onSelecionar,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoUrl != null && fotoUrl!.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: enviando
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : temFoto
                  ? Image.network(
                      AppConstants.mediaUrl(fotoUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.image_outlined,
                      size: 28, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Foto', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: enviando ? null : onSelecionar,
                icon: const Icon(Icons.upload, size: 16),
                label: Text(temFoto ? 'Trocar foto' : 'Enviar foto'),
              ),
              if (temFoto)
                TextButton.icon(
                  onPressed: enviando ? null : onRemover,
                  icon: const Icon(Icons.close, size: 14, color: Colors.red),
                  label: const Text('Remover foto',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
