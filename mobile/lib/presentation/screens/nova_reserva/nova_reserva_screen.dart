import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ativo.dart';
import '../../../data/services/reserva_service.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/gdm_button.dart';
import '../../widgets/gdm_card.dart';
import '../../widgets/gdm_text_field.dart';

class NovaReservaScreen extends StatefulWidget {
  final Ativo ativo;
  final DateTime inicio;
  final DateTime fim;

  const NovaReservaScreen({
    super.key,
    required this.ativo,
    required this.inicio,
    required this.fim,
  });

  @override
  State<NovaReservaScreen> createState() => _NovaReservaScreenState();
}

class _NovaReservaScreenState extends State<NovaReservaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivo = TextEditingController();
  final _observacoes = TextEditingController();
  bool _enviando = false;

  final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void dispose() {
    _motivo.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _enviando = true);
    try {
      final reserva = await ReservaService.criar(
        ativoId: widget.ativo.id,
        inicio: widget.inicio,
        fim: widget.fim,
        motivo: _motivo.text.trim(),
        observacoes: _observacoes.text.trim(),
      );
      if (!mounted) return;
      // Atualiza o contador de pendentes (caso tenha sido salvo offline).
      context.read<SyncProvider>().onMutacaoOffline();
      final pendente = reserva.status == 'PENDENTE';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              pendente ? Colors.orange.shade800 : Colors.green.shade700,
          content: Text(pendente
              ? 'Reserva enviada! Aguardando aprovacao do responsavel.'
              : 'Reserva confirmada! ID: ${reserva.id.substring(0, 8)}...'),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 800));
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

  @override
  Widget build(BuildContext context) {
    final horas = widget.fim.difference(widget.inicio).inHours;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova reserva'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card do ativo
              GdmCard(
                title: 'Ativo selecionado',
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.gdmLime.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.ativo.tipoAtivo == 'VEICULO'
                            ? Icons.directions_car
                            : Icons.agriculture,
                        color: AppColors.gdmBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.ativo.codigoInterno,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(widget.ativo.descricao,
                              style: const TextStyle(fontSize: 13)),
                          if (widget.ativo.placa != null)
                            Text('Placa: ${widget.ativo.placa}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          Text(widget.ativo.tipoLabel,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Card do periodo
              GdmCard(
                title: 'Periodo',
                child: Column(
                  children: [
                    _PeriodoRow(
                      icon: Icons.play_circle_outline,
                      label: 'Inicio',
                      value: _fmt.format(widget.inicio),
                    ),
                    const SizedBox(height: 8),
                    _PeriodoRow(
                      icon: Icons.stop_circle_outlined,
                      label: 'Fim',
                      value: _fmt.format(widget.fim),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duracao'),
                        Text('$horas horas',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Card de detalhes
              GdmCard(
                title: 'Detalhes da reserva',
                child: Column(
                  children: [
                    GdmTextField(
                      controller: _motivo,
                      label: 'Motivo da reserva *',
                      hint: 'Ex.: Visita tecnica - Fazenda Sao Joao',
                      prefixIcon: Icons.assignment_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o motivo'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    GdmTextField(
                      controller: _observacoes,
                      label: 'Observacoes',
                      hint: 'Informacoes adicionais (opcional)',
                      prefixIcon: Icons.note_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              GdmButton(
                onPressed: _confirmar,
                label: 'Confirmar reserva',
                loading: _enviando,
                icon: Icons.check_circle,
                expand: true,
              ),
              const SizedBox(height: 8),
              GdmButton(
                onPressed: () => context.pop(),
                label: 'Cancelar',
                variant: GdmButtonVariant.ghost,
                expand: true,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A reserva sera confirmada automaticamente. '
                        'Voce devera fazer o check-list de retirada antes de usar o ativo.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PeriodoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gdmBlue),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value),
      ],
    );
  }
}
