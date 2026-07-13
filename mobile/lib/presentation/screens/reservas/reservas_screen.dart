import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/reserva.dart';
import '../../../data/services/reserva_service.dart';
import '../../providers/module_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gdm_card.dart';
import '../../widgets/pending_sync_chip.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_badge.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _carregando = false;
  List<Reserva> _todas = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final list = await ReservaService.minhasReservas();
      setState(() => _todas = list);
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

  List<Reserva> _filtrar(String aba, List<Reserva> base) {
    switch (aba) {
      case 'ativas':
        return base
            .where((r) =>
                r.status == 'PENDENTE' ||
                r.status == 'CONFIRMADA' ||
                r.status == 'EM_USO')
            .toList();
      case 'concluidas':
        return base.where((r) => r.status == 'CONCLUIDA').toList();
      case 'canceladas':
        return base
            .where((r) =>
                r.status == 'CANCELADA' ||
                r.status == 'REJEITADA' ||
                r.status == 'EXPIRADA')
            .toList();
      default:
        return base;
    }
  }

  Future<void> _executarAcao(
    String acao,
    Reserva r,
    Future<Reserva> Function() fn,
  ) async {
    try {
      await fn();
      if (!mounted) return;
      context.read<SyncProvider>().onMutacaoOffline();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text('Reserva $acao com sucesso'),
        ),
      );
      _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(ApiClient.extractMessage(e)),
        ),
      );
    }
  }

  Future<void> _confirmar(
      String titulo, String texto, VoidCallback acao) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok == true) acao();
  }

  @override
  Widget build(BuildContext context) {
    final module = context.watch<ModuleProvider>();
    // Mostra apenas as reservas de ativos do modulo selecionado.
    final base = module.temModulo
        ? _todas.where((r) => module.tiposAtivo.contains(r.tipoAtivo)).toList()
        : _todas;
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Todas'),
              Tab(text: 'Ativas'),
              Tab(text: 'Concluidas'),
              Tab(text: 'Canceladas'),
            ],
          ),
        ),
        Expanded(
          child: _carregando
              ? const ListSkeleton()
              : TabBarView(
                  controller: _tab,
                  children: [
                    _ListaReservas(
                        reservas: base,
                        onAcao: _executarAcao,
                        onConfirm: _confirmar,
                        onRefresh: _carregar),
                    _ListaReservas(
                        reservas: _filtrar('ativas', base),
                        onAcao: _executarAcao,
                        onConfirm: _confirmar,
                        onRefresh: _carregar),
                    _ListaReservas(
                        reservas: _filtrar('concluidas', base),
                        onAcao: _executarAcao,
                        onConfirm: _confirmar,
                        onRefresh: _carregar),
                    _ListaReservas(
                        reservas: _filtrar('canceladas', base),
                        onAcao: _executarAcao,
                        onConfirm: _confirmar,
                        onRefresh: _carregar),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ListaReservas extends StatelessWidget {
  final List<Reserva> reservas;
  final Future<void> Function(String, Reserva, Future<Reserva> Function())
      onAcao;
  final Future<void> Function(String, String, VoidCallback) onConfirm;
  final Future<void> Function() onRefresh;

  const _ListaReservas({
    required this.reservas,
    required this.onAcao,
    required this.onConfirm,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (reservas.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'Nenhuma reserva nesta categoria',
              description: 'Vai em Disponibilidade para criar uma reserva.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: reservas.length,
        itemBuilder: (_, i) {
          final r = reservas[i];
          return _ReservaCard(reserva: r, onAcao: onAcao, onConfirm: onConfirm);
        },
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final Reserva reserva;
  final Future<void> Function(String, Reserva, Future<Reserva> Function())
      onAcao;
  final Future<void> Function(String, String, VoidCallback) onConfirm;

  const _ReservaCard({
    required this.reserva,
    required this.onAcao,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM HH:mm');
    final horas =
        reserva.dataHoraFim.difference(reserva.dataHoraInicio).inHours;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GdmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icone + ativo + status
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.gdmLime.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    reserva.tipoAtivo == 'VEICULO'
                        ? Icons.directions_car
                        : reserva.tipoAtivo == 'MAQUINA_AGRICOLA'
                            ? Icons.agriculture
                            : Icons.inventory_2,
                    color: AppColors.gdmBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reserva.codigoInterno ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        reserva.ativoDescricao ?? '',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (reserva.placa != null)
                        Text('Placa: ${reserva.placa}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                StatusBadge(status: reserva.status),
              ],
            ),
            if (reserva.pendenteSync) ...[
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: PendingSyncChip(),
              ),
            ],
            const Divider(height: 18),

            // Periodo
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${fmt.format(reserva.dataHoraInicio)} -> ${fmt.format(reserva.dataHoraFim)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text('${horas}h',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),

            if (reserva.motivo != null && reserva.motivo!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.assignment_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(reserva.motivo!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87)),
                  ),
                ],
              ),
            ],

            // Acoes por status
            if (reserva.podeIniciar ||
                reserva.podeConcluir ||
                reserva.podeCancelar) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (reserva.podeIniciar)
                    ElevatedButton.icon(
                      onPressed: () {
                        // Sprint 3: vai abrir o check-list de RETIRADA
                        context.push('/checklist-form', extra: {
                          'reserva': reserva,
                          'etapa': 'RETIRADA',
                        });
                      },
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Iniciar uso'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gdmLime,
                        foregroundColor: AppColors.gdmBlue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (reserva.podeConcluir)
                    ElevatedButton.icon(
                      onPressed: () {
                        // Vai abrir o check-list de DEVOLUCAO
                        context.push('/checklist-form', extra: {
                          'reserva': reserva,
                          'etapa': 'DEVOLUCAO',
                        });
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Concluir uso'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (reserva.podeCancelar)
                    OutlinedButton.icon(
                      onPressed: () => onConfirm(
                        'Cancelar reserva',
                        'Confirma o cancelamento? Esta acao nao pode ser desfeita.',
                        () => onAcao('cancelada', reserva,
                            () => ReservaService.cancelar(reserva.id)),
                      ),
                      icon:
                          const Icon(Icons.close, size: 16, color: Colors.red),
                      label: const Text('Cancelar',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
