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
  bool _ultimaMensagemMostrada = false;
  int _pendentes = 0;

  /// Abas do menu inferior, dependentes do perfil.
  /// - Vigilante: fluxo focado (Portaria + Perfil).
  /// - Administrador: abas completas + Portaria.
  /// - Demais perfis: abas completas.
  List<({String path, IconData icon, String label})> _tabsPara({
    required bool isVigilante,
    required bool podePortaria,
  }) {
    if (isVigilante) {
      return [
        (path: '/portaria', icon: Icons.shield_outlined, label: 'Portaria'),
        (path: '/perfil', icon: Icons.person_outline, label: 'Perfil'),
      ];
    }
    return [
      (path: '/home', icon: Icons.home_outlined, label: 'Home'),
      (path: '/disponibilidade', icon: Icons.search, label: 'Disponib.'),
      (
        path: '/reservas',
        icon: Icons.calendar_month_outlined,
        label: 'Reservas'
      ),
      (path: '/qr-scan', icon: Icons.center_focus_strong, label: 'Placa'),
      if (podePortaria)
        (path: '/portaria', icon: Icons.shield_outlined, label: 'Portaria'),
      (path: '/perfil', icon: Icons.person_outline, label: 'Perfil'),
    ];
  }

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

  int _currentIndex(
    BuildContext context,
    List<({String path, IconData icon, String label})> tabs,
  ) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = tabs.indexWhere((t) => loc.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final module = context.watch<ModuleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = _tabsPara(
      isVigilante: auth.isVigilante,
      podePortaria: auth.podePortaria,
    );

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
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex(context, tabs),
        onTap: (i) {
          HapticFeedback.selectionClick();
          context.go(tabs[i].path);
        },
        items: [
          for (final t in tabs)
            BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}
