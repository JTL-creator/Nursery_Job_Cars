import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/reserva.dart';
import '../../../data/services/reserva_service.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gdm_card.dart';
import '../../widgets/skeleton.dart';

/// Tela do responsavel/admin para aprovar ou rejeitar reservas pendentes.
class AprovacoesScreen extends StatefulWidget {
  const AprovacoesScreen({super.key});

  @override
  State<AprovacoesScreen> createState() => _AprovacoesScreenState();
}

class _AprovacoesScreenState extends State<AprovacoesScreen> {
  List<Reserva> _pendentes = [];
  bool _carregando = true;
  final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final list = await ReservaService.aprovacoesPendentes();
      if (mounted) setState(() => _pendentes = list);
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

  Future<void> _aprovar(Reserva r) async {
    HapticFeedback.mediumImpact();
    try {
      await ReservaService.aprovar(r.id);
      if (!mounted) return;
      context.read<SyncProvider>().onMutacaoOffline();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: const Text('Reserva aprovada'),
        ),
      );
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.extractMessage(e))),
        );
      }
    }
  }

  Future<void> _rejeitar(Reserva r) async {
    final motivo = await _pedirMotivo();
    if (motivo == null) return; // cancelou
    HapticFeedback.selectionClick();
    try {
      await ReservaService.rejeitar(r.id, motivo: motivo);
      if (!mounted) return;
      context.read<SyncProvider>().onMutacaoOffline();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: const Text('Reserva rejeitada'),
        ),
      );
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.extractMessage(e))),
        );
      }
    }
  }

  Future<String?> _pedirMotivo() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar reserva'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Motivo da rejeicao (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aprovacoes pendentes')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _carregando
            ? const ListSkeleton()
            : _pendentes.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      GdmCard(
                        child: EmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'Nenhuma aprovacao pendente',
                          description:
                              'Reservas aguardando sua aprovacao aparecerao aqui.',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendentes.length,
                    itemBuilder: (_, i) => _AprovacaoCard(
                      reserva: _pendentes[i],
                      fmt: _fmt,
                      onAprovar: () => _aprovar(_pendentes[i]),
                      onRejeitar: () => _rejeitar(_pendentes[i]),
                    ),
                  ),
      ),
    );
  }
}

class _AprovacaoCard extends StatelessWidget {
  final Reserva reserva;
  final DateFormat fmt;
  final VoidCallback onAprovar;
  final VoidCallback onRejeitar;

  const _AprovacaoCard({
    required this.reserva,
    required this.fmt,
    required this.onAprovar,
    required this.onRejeitar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GdmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  reserva.tipoAtivo == 'VEICULO'
                      ? Icons.directions_car
                      : Icons.agriculture,
                  color: AppColors.gdmBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reserva.tituloAtivo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _linha(Icons.person_outline, 'Solicitante',
                reserva.usuarioNome ?? '—'),
            _linha(Icons.play_circle_outline, 'Inicio',
                fmt.format(reserva.dataHoraInicio.toLocal())),
            _linha(Icons.stop_circle_outlined, 'Fim',
                fmt.format(reserva.dataHoraFim.toLocal())),
            if (reserva.motivo != null && reserva.motivo!.isNotEmpty)
              _linha(Icons.notes, 'Motivo', reserva.motivo!),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRejeitar,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rejeitar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAprovar,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprovar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: Text(valor, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
