import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ativo.dart';
import '../../../data/services/ativo_service.dart';
import '../../widgets/gdm_button.dart';
import '../../widgets/gdm_card.dart';
import '../../widgets/loading_indicator.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _processando = false;
  Ativo? _ativoEncontrado;
  String? _codigoLido;
  String? _mensagemErro;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processarCodigo(String codigo) async {
    if (_processando) return;
    setState(() {
      _processando = true;
      _codigoLido = codigo;
      _mensagemErro = null;
      _ativoEncontrado = null;
    });

    await _controller.stop();

    try {
      final ativo = await AtivoService.buscarPorCodigo(codigo);
      if (!mounted) return;

      if (ativo == null) {
        setState(() {
          _mensagemErro = 'Nenhum ativo encontrado com codigo "$codigo".';
          _processando = false;
        });
        return;
      }

      setState(() {
        _ativoEncontrado = ativo;
        _processando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagemErro = ApiClient.extractMessage(e);
        _processando = false;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _processarCodigo(code.trim());
  }

  Future<void> _entradaManual() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Entrada manual'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Codigo do ativo',
            hintText: 'Ex.: VEIC-001',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(dialogCtx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (res != null && res.isNotEmpty) _processarCodigo(res);
  }

  Future<void> _escanearNovamente() async {
    setState(() {
      _ativoEncontrado = null;
      _codigoLido = null;
      _mensagemErro = null;
    });
    await _controller.start();
  }

  void _irParaReserva() {
    if (_ativoEncontrado == null) return;
    final inicio = DateTime.now().add(const Duration(minutes: 30));
    final fim = inicio.add(const Duration(hours: 8));
    context.push('/nova-reserva', extra: {
      'ativo': _ativoEncontrado!,
      'inicio': inicio,
      'fim': fim,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scanner ou resultado
          if (_ativoEncontrado == null && _mensagemErro == null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 300,
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                  ),
                  // Frame de mira
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gdmLime, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  if (_processando)
                    Container(
                      color: Colors.black54,
                      child: const Center(child: LoadingIndicator()),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aponte para o QR Code do ativo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _controller.toggleTorch(),
                    icon: const Icon(Icons.flashlight_on_outlined),
                    label: const Text('Lanterna'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _entradaManual,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Manual'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gdmBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Erro: codigo nao encontrado
          if (_mensagemErro != null) ...[
            GdmCard(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline,
                        size: 32, color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ativo nao encontrado',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mensagemErro!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (_codigoLido != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Codigo lido: $_codigoLido',
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  GdmButton(
                    onPressed: _escanearNovamente,
                    label: 'Escanear outro',
                    icon: Icons.qr_code_scanner,
                    expand: true,
                  ),
                ],
              ),
            ),
          ],

          // Ativo encontrado: confirmacao e reserva
          if (_ativoEncontrado != null) ...[
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
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.gdmLime,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: AppColors.gdmBlue, size: 32),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ativo identificado!',
                    style: TextStyle(
                      color: AppColors.gdmLime,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ativoEncontrado!.codigoInterno,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GdmCard(
              title: 'Detalhes do ativo',
              child: Column(
                children: [
                  _InfoRow(
                    icon: _ativoEncontrado!.tipoAtivo == 'VEICULO'
                        ? Icons.directions_car
                        : Icons.agriculture,
                    label: 'Tipo',
                    value: _ativoEncontrado!.tipoLabel,
                  ),
                  _InfoRow(
                    icon: Icons.description_outlined,
                    label: 'Descricao',
                    value: _ativoEncontrado!.descricao,
                  ),
                  if (_ativoEncontrado!.placa != null)
                    _InfoRow(
                      icon: Icons.confirmation_number,
                      label: 'Placa',
                      value: _ativoEncontrado!.placa!,
                    ),
                  if (_ativoEncontrado!.unidade != null)
                    _InfoRow(
                      icon: Icons.business,
                      label: 'Unidade',
                      value: _ativoEncontrado!.unidade!,
                    ),
                  _InfoRow(
                    icon: Icons.circle,
                    label: 'Status',
                    value: _ativoEncontrado!.status,
                    valueColor: _ativoEncontrado!.status == 'DISPONIVEL'
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_ativoEncontrado!.status == 'DISPONIVEL')
              GdmButton(
                onPressed: _irParaReserva,
                label: 'Reservar este ativo',
                icon: Icons.bookmark_add,
                expand: true,
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este ativo nao esta disponivel para reserva no momento.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _escanearNovamente,
              icon: const Icon(Icons.qr_code_scanner, size: 16),
              label: const Text('Escanear outro'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
