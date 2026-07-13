import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/placa_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ativo.dart';
import '../../../data/models/reserva.dart';
import '../../../data/services/ativo_service.dart';
import '../../../data/services/reserva_service.dart';
import '../../widgets/gdm_button.dart';
import '../../widgets/gdm_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/plate_scanner.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _processando = false;
  Ativo? _ativoEncontrado;
  String? _placaLida;
  String? _mensagemErro;
  List<Reserva> _reservas = [];

  Future<void> _processarPlaca(String placa) async {
    if (_processando) return;
    setState(() {
      _processando = true;
      _placaLida = placa;
      _mensagemErro = null;
      _ativoEncontrado = null;
      _reservas = [];
    });

    try {
      final ativo = await AtivoService.buscarPorPlaca(placa);
      if (!mounted) return;

      if (ativo == null) {
        setState(() {
          _mensagemErro =
              'Nenhum veiculo encontrado com a placa "${PlacaUtils.formatar(placa)}".';
          _processando = false;
        });
        return;
      }

      // Busca reservas ativas do usuario para este veiculo.
      List<Reserva> ativas = [];
      try {
        final todas = await ReservaService.minhasReservas();
        ativas =
            todas.where((r) => r.ativoId == ativo.id && r.estaAtiva).toList();
      } catch (_) {/* segue sem reservas */}

      if (!mounted) return;
      setState(() {
        _ativoEncontrado = ativo;
        _reservas = ativas;
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

  /// Reserva pronta para iniciar o check-list de retirada (status CONFIRMADA).
  Reserva? get _reservaRetirada {
    for (final r in _reservas) {
      if (r.podeIniciar) return r;
    }
    return null;
  }

  /// Reserva pronta para o check-list de devolucao (status EM_USO).
  Reserva? get _reservaDevolucao {
    for (final r in _reservas) {
      if (r.podeConcluir) return r;
    }
    return null;
  }

  void _escanearNovamente() {
    setState(() {
      _ativoEncontrado = null;
      _placaLida = null;
      _mensagemErro = null;
      _reservas = [];
    });
  }

  void _abrirChecklist(Reserva reserva, String etapa) {
    context.push('/checklist-form', extra: {
      'reserva': reserva,
      'etapa': etapa,
    });
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
          // Leitor de placa (OCR) ou resultado
          if (_ativoEncontrado == null && _mensagemErro == null) ...[
            if (_processando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: LoadingIndicator()),
              )
            else
              PlateScanner(
                onPlaca: _processarPlaca,
                legenda: 'Aponte a camera para a placa do veiculo',
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
                    'Veiculo nao encontrado',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mensagemErro!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (_placaLida != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Placa lida: ${PlacaUtils.formatar(_placaLida)}',
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  GdmButton(
                    onPressed: _escanearNovamente,
                    label: 'Ler outra placa',
                    icon: Icons.center_focus_strong,
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
            // Acao principal: check-list conforme a reserva ativa do usuario.
            if (_reservaRetirada != null)
              GdmButton(
                onPressed: () => _abrirChecklist(_reservaRetirada!, 'RETIRADA'),
                label: 'Iniciar check-list (Retirada)',
                icon: Icons.assignment_turned_in,
                expand: true,
              )
            else if (_reservaDevolucao != null)
              GdmButton(
                onPressed: () =>
                    _abrirChecklist(_reservaDevolucao!, 'DEVOLUCAO'),
                label: 'Concluir check-list (Devolucao)',
                icon: Icons.assignment_return,
                expand: true,
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Voce nao tem reserva ativa para este veiculo. '
                        'Faca uma reserva para registrar o check-list.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_ativoEncontrado!.status == 'DISPONIVEL') ...[
                const SizedBox(height: 8),
                GdmButton(
                  onPressed: _irParaReserva,
                  label: 'Reservar este veiculo',
                  icon: Icons.bookmark_add,
                  variant: GdmButtonVariant.secondary,
                  expand: true,
                ),
              ],
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _escanearNovamente,
              icon: const Icon(Icons.center_focus_strong, size: 16),
              label: const Text('Ler outra placa'),
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
