import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/services/placa_utils.dart';
import '../../core/theme/app_colors.dart';
import 'loading_indicator.dart';

/// Widget reutilizavel de leitura de placa por camera + OCR (Google ML Kit).
/// Mostra a previa da camera com uma mira e um botao para capturar/ler a placa.
/// Chama [onPlaca] com a placa normalizada (ex.: "ABC1D23") quando reconhecida.
class PlateScanner extends StatefulWidget {
  final void Function(String placa) onPlaca;
  final String legenda;

  const PlateScanner({
    super.key,
    required this.onPlaca,
    this.legenda = 'Aponte a camera para a placa do veiculo',
  });

  @override
  State<PlateScanner> createState() => _PlateScannerState();
}

class _PlateScannerState extends State<PlateScanner>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final TextRecognizer _recognizer = TextRecognizer();
  bool _inicializando = true;
  bool _lendo = false;
  String? _erroCamera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciarCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _recognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _iniciarCamera();
    }
  }

  Future<void> _iniciarCamera() async {
    setState(() {
      _inicializando = true;
      _erroCamera = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Nenhuma camera disponivel');
      }
      final traseira = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        traseira,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _controller = ctrl;
        _inicializando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroCamera =
            'Nao foi possivel acessar a camera. Verifique as permissoes.';
        _inicializando = false;
      });
    }
  }

  Future<void> _lerPlaca() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _lendo) return;
    setState(() => _lendo = true);
    try {
      final foto = await ctrl.takePicture();
      final input = InputImage.fromFilePath(foto.path);
      final resultado = await _recognizer.processImage(input);

      final linhas = <String>[];
      for (final bloco in resultado.blocks) {
        for (final linha in bloco.lines) {
          linhas.add(linha.text);
        }
      }
      final placa = PlacaUtils.extrairDeLinhas(linhas);

      if (!mounted) return;
      if (placa == null) {
        setState(() => _lendo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade700,
            content: const Text(
              'Nao foi possivel identificar a placa. Aproxime e tente novamente.',
            ),
          ),
        );
        return;
      }
      setState(() => _lendo = false);
      widget.onPlaca(placa);
    } catch (e) {
      if (!mounted) return;
      setState(() => _lendo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: const Text('Falha ao ler a imagem. Tente novamente.'),
        ),
      );
    }
  }

  Future<void> _entradaManual() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Digitar placa'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Placa do veiculo',
            hintText: 'Ex.: ABC1D23',
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
    if (res != null && res.trim().isNotEmpty) {
      widget.onPlaca(PlacaUtils.normalizar(res));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_inicializando)
                  const Center(child: LoadingIndicator())
                else if (_erroCamera != null)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _erroCamera!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  )
                else if (_controller != null)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.previewSize?.height ?? 300,
                        height: _controller!.value.previewSize?.width ?? 300,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  ),
                // Mira retangular (formato de placa)
                if (_erroCamera == null && !_inicializando)
                  Container(
                    width: 240,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gdmLime, width: 3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                if (_lendo)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: LoadingIndicator()),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.legenda,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: (_inicializando || _erroCamera != null || _lendo)
              ? null
              : _lerPlaca,
          icon: const Icon(Icons.center_focus_strong),
          label: const Text('Ler placa'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: AppColors.gdmBlue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _entradaManual,
          icon: const Icon(Icons.keyboard),
          label: const Text('Digitar placa manualmente'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.gdmBlue),
        ),
      ],
    );
  }
}
