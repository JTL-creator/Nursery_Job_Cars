import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import '../../data/services/reserva_service.dart';
import '../providers/auth_provider.dart';
import '../providers/module_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/sync_badge.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _tabs = <String>[
    '/home',
    '/disponibilidade',
    '/reservas',
    '/qr-scan',
    '/perfil',
  ];

  bool _ultimaMensagemMostrada = false;
  int _pendentes = 0;

  @override
  void initState() {
    super.initState();
    // Mostra snackbar quando sync termina
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sync = context.read<SyncProvider>();
      sync.addListener(_handleSyncMessage);
      _verificarAprovacoesPendentes();
    });
  }

  Future<void> _verificarAprovacoesPendentes() async {
    final auth = context.read<AuthProvider>();
    if (!auth.podeAprovar) return;
    try {
      final pend = await ReservaService.aprovacoesPendentes();
      if (mounted) setState(() => _pendentes = pend.length);
      if (pend.isNotEmpty) {
        await NotificationService.showSimple(
          'Aprovacoes pendentes',
          'Voce tem ${pend.length} reserva(s) aguardando aprovacao.',
        );
      }
    } catch (_) {/* silencioso */}
  }

  @override
  void dispose() {
    try {
      context.read<SyncProvider>().removeListener(_handleSyncMessage);
    } catch (_) {}
    super.dispose();
  }

  void _handleSyncMessage() {
    final sync = context.read<SyncProvider>();
    final msg = sync.ultimaMensagem;
    if (msg != null && !sync.sincronizando && !_ultimaMensagemMostrada) {
      _ultimaMensagemMostrada = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: sync.pendentes == 0
                ? Colors.green.shade700
                : Colors.orange.shade700,
            content: Text(msg),
            duration: const Duration(seconds: 3),
          ),
        );
        sync.limparMensagem();
        Future.delayed(const Duration(seconds: 1), () {
          _ultimaMensagemMostrada = false;
        });
      });
    }
  }

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final module = context.watch<ModuleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(module.temModulo ? 'GDM • ${module.label}' : 'GDM Job Cars'),
        actions: [
          if (module.temModulo)
            IconButton(
              tooltip: 'Trocar modulo',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => context.go('/selecionar-modulo'),
            ),
          if (auth.podeAprovar)
            Badge(
              isLabelVisible: _pendentes > 0,
              label: Text('$_pendentes'),
              offset: const Offset(-4, 4),
              child: IconButton(
                tooltip: 'Aprovacoes pendentes',
                icon: const Icon(Icons.fact_check_outlined),
                onPressed: () async {
                  await context.push('/aprovacoes');
                  _verificarAprovacoesPendentes();
                },
              ),
            ),
          const SyncBadge(),
          IconButton(
            tooltip: 'Alternar tema',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => theme.toggle(),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<ModuleProvider>().limpar();
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (i) {
          HapticFeedback.selectionClick();
          context.go(_tabs[i]);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Disponib.'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined), label: 'Reservas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'QR Scan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}
