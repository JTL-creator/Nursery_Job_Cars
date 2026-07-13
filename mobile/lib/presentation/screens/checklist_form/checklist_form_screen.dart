import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/placa_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/checklist_template.dart';
import '../../../data/models/reserva.dart';
import '../../../data/services/checklist_service.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/gdm_button.dart';
import '../../widgets/gdm_card.dart';
import '../../widgets/leitor_placa_sheet.dart';
import '../../widgets/loading_indicator.dart';

class ChecklistFormScreen extends StatefulWidget {
  final Reserva reserva;
  final String etapa;

  const ChecklistFormScreen({
    super.key,
    required this.reserva,
    required this.etapa,
  });

  @override
  State<ChecklistFormScreen> createState() => _ChecklistFormScreenState();
}

class _ChecklistFormScreenState extends State<ChecklistFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localCtrl = TextEditingController();
  final _respCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  ChecklistTemplate? _template;
  bool _carregando = true;
  bool _enviando = false;

  final Map<String, dynamic> _valores = {};
  final Map<String, String> _fotos = {};
  Position? _posicao;

  // Conferencia de placa (opcional): compara o veiculo fisico com a reserva.
  String? _placaLida;
  bool? _placaConfere;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _localCtrl.dispose();
    _respCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final tpl = await ChecklistService.obterTemplate(
        reservaId: widget.reserva.id,
        etapa: widget.etapa,
        tipoAtivoFallback: widget.reserva.tipoAtivo,
      );
      _capturarGps();
      setState(() {
        _template = tpl;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Template indisponivel: ${ApiClient.extractMessage(e)}')),
        );
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _capturarGps() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _posicao = pos;
        _valores['gps_lat'] = pos.latitude;
        _valores['gps_long'] = pos.longitude;
      });
    }
  }

  Future<void> _conferirPlaca() async {
    final placa = await showLeitorPlacaSheet(
      context,
      titulo: 'Conferir placa do veiculo',
    );
    if (placa == null || !mounted) return;
    final lida = PlacaUtils.normalizar(placa);
    final esperada = PlacaUtils.normalizar(widget.reserva.placa);
    setState(() {
      _placaLida = placa;
      _placaConfere = esperada.isNotEmpty && lida == esperada;
    });
  }

  Future<void> _tirarFoto(String chave) async {
    try {
      final picker = ImagePicker();
      final src = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (src == null) return;

      final file = await picker.pickImage(
        source: src,
        maxWidth: 1280,
        imageQuality: 75,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$b64';
      setState(() {
        _fotos[chave] = dataUrl;
        _valores[chave] = dataUrl;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao capturar imagem: $e')),
        );
      }
    }
  }

  String _tituloEtapa() => widget.etapa == 'RETIRADA'
      ? 'Check-list de Retirada'
      : 'Check-list de Devolucao';

  bool _ehFoto(ChecklistTemplateItem item) =>
      item.chaveItem.startsWith('foto_') ||
      item.descricao.toLowerCase().contains('foto');

  bool _ehGps(ChecklistTemplateItem item) => item.chaveItem.startsWith('gps_');

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_template == null) return;

    final faltando = <String>[];
    for (final it in _template!.itens) {
      if (!it.obrigatorio) continue;
      final v = _valores[it.chaveItem];
      if (v == null || (v is String && v.isEmpty)) {
        faltando.add(it.descricao);
      }
    }
    if (faltando.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Preencha os campos obrigatorios: ${faltando.join(", ")}'),
        ),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      final itensPayload = _template!.itens.map((it) {
        final v = _valores[it.chaveItem];
        return {
          'chave_item': it.chaveItem,
          'descricao_item': it.descricao,
          if (it.tipoCampo == 'numero' && v != null)
            'valor_numero': v is num ? v : double.tryParse(v.toString()),
          if (it.tipoCampo == 'booleano' && v != null)
            'valor_booleano': v == true || v == 'true',
          if (it.tipoCampo != 'numero' &&
              it.tipoCampo != 'booleano' &&
              v != null)
            'valor_texto': v.toString(),
          'obrigatorio': it.obrigatorio,
          'ordem': it.ordem,
        };
      }).toList();

      // Tenta online primeiro, fallback offline automatico
      final enviadoOnline = await ChecklistService.criarComFallbackOffline(
        reservaId: widget.reserva.id,
        etapa: widget.etapa,
        itens: itensPayload,
        local: _localCtrl.text.trim().isEmpty ? null : _localCtrl.text.trim(),
        responsavel:
            _respCtrl.text.trim().isEmpty ? null : _respCtrl.text.trim(),
        observacoes: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      );

      if (!mounted) return;

      if (enviadoOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(widget.etapa == 'RETIRADA'
                ? 'Retirada registrada! Reserva agora esta EM USO.'
                : 'Devolucao registrada! Reserva CONCLUIDA com sucesso.'),
          ),
        );
      } else {
        // Avisa o SyncProvider e mostra mensagem offline
        context.read<SyncProvider>().onChecklistSalvoOffline();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4),
            content: const Text(
              'Sem conexao. Check-list salvo offline. '
              'Sera enviado automaticamente quando a internet voltar.',
            ),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.go('/reservas');
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
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _buildCampo(ChecklistTemplateItem item) {
    if (_ehFoto(item)) return _buildCampoFoto(item);
    if (_ehGps(item)) return _buildCampoGps(item);
    switch (item.tipoCampo) {
      case 'numero':
        return _buildCampoNumero(item);
      case 'booleano':
        return _buildCampoBooleano(item);
      case 'selecao':
        return _buildCampoSelecao(item);
      default:
        return _buildCampoTexto(item);
    }
  }

  Widget _campoBase(String label, bool obrig, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(
            text: label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            children: obrig
                ? [
                    const TextSpan(
                        text: ' *', style: TextStyle(color: Colors.red))
                  ]
                : null,
          )),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildCampoTexto(ChecklistTemplateItem item) => _campoBase(
        item.descricao,
        item.obrigatorio,
        TextFormField(
          maxLines: item.descricao.toLowerCase().contains('obs') ? 3 : 1,
          onChanged: (v) => _valores[item.chaveItem] = v,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      );

  Widget _buildCampoNumero(ChecklistTemplateItem item) => _campoBase(
        item.descricao,
        item.obrigatorio,
        TextFormField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => _valores[item.chaveItem] = double.tryParse(v),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.numbers),
          ),
        ),
      );

  Widget _buildCampoBooleano(ChecklistTemplateItem item) {
    final atual = _valores[item.chaveItem] == true;
    return _campoBase(
      item.descricao,
      item.obrigatorio,
      Row(
        children: [
          ChoiceChip(
            label: const Text('Sim'),
            selected: atual,
            selectedColor: Colors.green.shade200,
            onSelected: (_) => setState(() => _valores[item.chaveItem] = true),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Nao'),
            selected: _valores[item.chaveItem] == false,
            selectedColor: Colors.red.shade200,
            onSelected: (_) => setState(() => _valores[item.chaveItem] = false),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoSelecao(ChecklistTemplateItem item) {
    final opcoes = item.opcoes ?? [];
    final atual = _valores[item.chaveItem]?.toString();
    return _campoBase(
      item.descricao,
      item.obrigatorio,
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: opcoes
            .map((o) => ChoiceChip(
                  label: Text(o),
                  selected: atual == o,
                  selectedColor: AppColors.gdmLime,
                  onSelected: (_) =>
                      setState(() => _valores[item.chaveItem] = o),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCampoFoto(ChecklistTemplateItem item) {
    final foto = _fotos[item.chaveItem];
    return _campoBase(
      item.descricao,
      item.obrigatorio,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (foto != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                base64Decode(foto.split(',').last),
                height: 180,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 36, color: Colors.grey),
                  SizedBox(height: 6),
                  Text('Nenhuma foto', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          GdmButton(
            onPressed: () => _tirarFoto(item.chaveItem),
            label: foto == null ? 'Tirar / escolher foto' : 'Trocar foto',
            icon: Icons.camera_alt,
            variant: foto == null
                ? GdmButtonVariant.primary
                : GdmButtonVariant.secondary,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCampoGps(ChecklistTemplateItem item) {
    final v = _valores[item.chaveItem];
    return _campoBase(
      item.descricao,
      false,
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: v != null ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.my_location,
                color: v != null ? Colors.green.shade700 : Colors.grey,
                size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                v != null ? v.toString() : 'Aguardando GPS...',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (v == null)
              TextButton(
                onPressed: _capturarGps,
                child: const Text('Tentar novamente'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: Text(_tituloEtapa()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _carregando
          ? const Center(child: LoadingIndicator())
          : _template == null
              ? const Center(child: Text('Template nao encontrado'))
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.gdmBlue, AppColors.gdmBlue2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.etapa == 'RETIRADA'
                                    ? 'Retirada'
                                    : 'Devolucao',
                                style: const TextStyle(
                                  color: AppColors.gdmLime,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.reserva.codigoInterno ?? '—',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.reserva.ativoDescricao ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Periodo: ${fmt.format(widget.reserva.dataHoraInicio)} -> ${fmt.format(widget.reserva.dataHoraFim)}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if ((widget.reserva.placa ?? '').isNotEmpty) ...[
                          _ConferenciaPlaca(
                            placaReservada: widget.reserva.placa!,
                            placaLida: _placaLida,
                            confere: _placaConfere,
                            onConferir: _conferirPlaca,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_posicao != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.gps_fixed,
                                    color: Colors.green.shade700, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'GPS: ${_posicao!.latitude.toStringAsFixed(5)}, ${_posicao!.longitude.toStringAsFixed(5)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        GdmCard(
                          title: 'Dados gerais',
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _localCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Local',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.place_outlined),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _respCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Responsavel',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _obsCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Observacoes gerais',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GdmCard(
                          title: 'Itens do check-list',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children:
                                _template!.itens.map(_buildCampo).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GdmButton(
                          onPressed: _enviar,
                          label: widget.etapa == 'RETIRADA'
                              ? 'Confirmar retirada'
                              : 'Confirmar devolucao',
                          loading: _enviando,
                          icon: Icons.check_circle,
                          expand: true,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }
}

/// Card de conferencia de placa: compara o veiculo fisico (via OCR) com a
/// placa da reserva. Nao bloqueia o envio; serve como conferencia visual.
class _ConferenciaPlaca extends StatelessWidget {
  final String placaReservada;
  final String? placaLida;
  final bool? confere;
  final Future<void> Function() onConferir;

  const _ConferenciaPlaca({
    required this.placaReservada,
    required this.placaLida,
    required this.confere,
    required this.onConferir,
  });

  @override
  Widget build(BuildContext context) {
    return GdmCard(
      title: 'Conferencia de placa',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined,
                  size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Placa reservada: ${PlacaUtils.formatar(placaReservada)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (confere == null)
            OutlinedButton.icon(
              onPressed: onConferir,
              icon: const Icon(Icons.center_focus_strong, size: 18),
              label: const Text('Conferir placa do veiculo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gdmBlue,
              ),
            )
          else if (confere == true)
            _ResultadoConferencia(
              cor: Colors.green,
              icone: Icons.check_circle,
              texto: 'Placa conferida: ${PlacaUtils.formatar(placaLida)}',
            )
          else ...[
            _ResultadoConferencia(
              cor: Colors.red,
              icone: Icons.warning_amber_rounded,
              texto: 'Placa lida (${PlacaUtils.formatar(placaLida)}) difere '
                  'da reservada (${PlacaUtils.formatar(placaReservada)}).',
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onConferir,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Conferir novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gdmBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultadoConferencia extends StatelessWidget {
  final MaterialColor cor;
  final IconData icone;
  final String texto;

  const _ResultadoConferencia({
    required this.cor,
    required this.icone,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cor.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 12, color: cor.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
