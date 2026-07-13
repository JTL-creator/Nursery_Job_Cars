import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ativo.dart';
import '../../../data/models/reserva.dart';
import '../../../data/services/ativo_service.dart';
import '../../../data/services/reserva_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/module_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/gdm_card.dart';
import '../../widgets/skeleton.dart';

class _Kpi {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Kpi(this.icon, this.label, this.value, this.color);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _minhas;
  int? _ativas;
  int? _concluidas;
  int? _ativosCount;
  int? _pendentes;
  bool _loadingKpis = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadKpis());
  }

  Future<void> _loadKpis() async {
    if (!mounted) return;
    setState(() => _loadingKpis = true);
    final module = context.read<ModuleProvider>();
    final auth = context.read<AuthProvider>();
    try {
      final results = await Future.wait<dynamic>([
        ReservaService.minhasReservas(),
        AtivoService.listar(
            categoria: module.temModulo ? module.categoria : null),
        if (auth.podeAprovar)
          ReservaService.aprovacoesPendentes()
        else
          Future<List<Reserva>>.value(const []),
      ]);
      final reservas = (results[0] as List<Reserva>)
          .where((r) =>
              !module.temModulo || module.tiposAtivo.contains(r.tipoAtivo))
          .toList();
      final ativos = results[1] as List<Ativo>;
      final pendentes = results[2] as List<Reserva>;
      if (!mounted) return;
      setState(() {
        _minhas = reservas.length;
        _ativas = reservas
            .where((r) =>
                r.status == 'PENDENTE' ||
                r.status == 'CONFIRMADA' ||
                r.status == 'EM_USO')
            .length;
        _concluidas = reservas.where((r) => r.status == 'CONCLUIDA').length;
        _ativosCount = ativos.length;
        _pendentes = pendentes.length;
        _loadingKpis = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingKpis = false);
    }
  }

  Future<void> _capturarLocalizacao(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Capturando localizacao...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
    final pos = await LocationService.getCurrentPosition();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            pos == null ? Colors.red.shade700 : Colors.green.shade700,
        content: Text(pos == null
            ? 'Localizacao nao disponivel. Verifique as permissoes.'
            : 'Lat: ${pos.latitude.toStringAsFixed(5)}, '
                'Long: ${pos.longitude.toStringAsFixed(5)}'),
      ),
    );
  }

  Future<void> _sincronizar(BuildContext context) async {
    final sync = context.read<SyncProvider>();
    final conn = context.read<ConnectivityProvider>();

    if (!conn.online) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content:
              const Text('Voce esta offline. Conecte-se a internet primeiro.'),
        ),
      );
      return;
    }

    if (sync.pendentes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum dado pendente para sincronizar.')),
      );
      return;
    }

    final r = await sync.sincronizar();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: r.totalSucesso
            ? Colors.green.shade700
            : (r.enviados > 0 ? Colors.orange.shade700 : Colors.red.shade700),
        content: Text('${r.enviados} enviado(s), ${r.falhas} falha(s)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<SyncProvider>();
    final conn = context.watch<ConnectivityProvider>();
    final firstName = (auth.user?.nomeCompleto.split(' ').first) ?? 'Usuario';

    String kv(int? v) => (v ?? 0).toString();
    final kpis = <_Kpi>[
      _Kpi(Icons.event_available, 'Minhas Reservas', kv(_minhas),
          AppColors.gdmLime),
      _Kpi(Icons.timelapse, 'Reservas Ativas', kv(_ativas), AppColors.info),
      if (auth.podeAprovar)
        _Kpi(Icons.fact_check, 'Aprovacoes', kv(_pendentes), AppColors.warning)
      else
        _Kpi(Icons.task_alt, 'Concluidas', kv(_concluidas), AppColors.warning),
      _Kpi(Icons.local_shipping, 'Ativos', kv(_ativosCount), AppColors.success),
    ];

    return RefreshIndicator(
      onRefresh: _loadKpis,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gdmBlue, AppColors.gdmBlue2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ola, $firstName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perfil: ${auth.perfil ?? "—"}',
                    style:
                        const TextStyle(color: AppColors.gdmLime, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        conn.online ? Icons.cloud_done : Icons.cloud_off,
                        size: 14,
                        color: conn.online
                            ? AppColors.gdmLime
                            : Colors.red.shade300,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        conn.online ? 'Online' : 'Offline',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // KPIs
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: kpis.map((k) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: k.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(k.icon, color: k.color, size: 20),
                        ),
                        _loadingKpis
                            ? const Skeleton(
                                child: SkeletonBox(
                                    width: 44, height: 24, radius: 6),
                              )
                            : Text(
                                k.value,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        Text(
                          k.label,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Acoes rapidas
            GdmCard(
              title: 'Acoes rapidas',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _QuickAction(
                    icon: Icons.search,
                    label: 'Disponibilidade',
                    onTap: () => context.go('/disponibilidade'),
                  ),
                  _QuickAction(
                    icon: Icons.qr_code_scanner,
                    label: 'QR Scan',
                    onTap: () => context.go('/qr-scan'),
                  ),
                  _QuickAction(
                    icon: Icons.add_box_outlined,
                    label: 'Nova reserva',
                    onTap: () => context.go('/reservas'),
                  ),
                  if (auth.podeAprovar)
                    _QuickAction(
                      icon: Icons.fact_check_outlined,
                      label: 'Aprovacoes',
                      onTap: () => context.push('/aprovacoes'),
                    ),
                  if (auth.perfil == 'ADMINISTRADOR')
                    _QuickAction(
                      icon: Icons.inventory_2_outlined,
                      label: 'Gerenciar ativos',
                      onTap: () => context.push('/admin-ativos'),
                    ),
                  if (auth.perfil == 'ADMINISTRADOR')
                    _QuickAction(
                      icon: Icons.checklist,
                      label: 'Check-lists',
                      onTap: () => context.push('/admin-templates'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Ferramentas operacionais (Sync + GPS visiveis!)
            GdmCard(
              title: 'Ferramentas',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: sync.temPendentes
                            ? Colors.orange.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              sync.sincronizando
                                  ? Icons.sync
                                  : Icons.cloud_sync_outlined,
                              color: sync.temPendentes
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                          if (sync.temPendentes)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${sync.pendentes}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    title: const Text(
                      'Sincronizacao',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      sync.temPendentes
                          ? '${sync.pendentes} item(ns) aguardando envio'
                          : 'Todos os dados sincronizados',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.send, size: 18),
                          color: AppColors.gdmBlue,
                          tooltip: 'Sincronizar agora',
                          onPressed: sync.sincronizando
                              ? null
                              : () => _sincronizar(context),
                        ),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                    onTap: () => context.push('/sync'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    title: const Text(
                      'Localizacao GPS',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Capturar coordenadas atuais',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.gps_fixed,
                        size: 18, color: AppColors.gdmBlue),
                    onTap: () => _capturarLocalizacao(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    title: const Text(
                      'Notificacoes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Lembretes de reservas',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push('/notificacoes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gdmBlue,
        side: const BorderSide(color: AppColors.gdmBlue),
      ),
    );
  }
}
