import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/models/ativo.dart';
import '../data/models/reserva.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/login/login_screen.dart';
import '../presentation/screens/solicitar_cadastro/solicitar_cadastro_screen.dart';
import '../presentation/screens/selecao_modulo/selecao_modulo_screen.dart';
import '../presentation/screens/main_shell.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/disponibilidade/disponibilidade_screen.dart';
import '../presentation/screens/nova_reserva/nova_reserva_screen.dart';
import '../presentation/screens/reservas/reservas_screen.dart';
import '../presentation/screens/aprovacoes/aprovacoes_screen.dart';
import '../presentation/screens/admin_ativos/admin_ativos_screen.dart';
import '../presentation/screens/admin_templates/admin_templates_screen.dart';
import '../presentation/screens/checklists/checklists_screen.dart';
import '../presentation/screens/checklist_form/checklist_form_screen.dart';
import '../presentation/screens/qr_scan/qr_scan_screen.dart';
import '../presentation/screens/perfil/perfil_screen.dart';
import '../presentation/screens/sync/sync_screen.dart';
import '../presentation/screens/notificacoes/notificacoes_screen.dart';

GoRouter appRouter(BuildContext context) {
  final auth = context.read<AuthProvider>();

  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (ctx, state) {
      if (auth.loading) return null;
      final loc = state.matchedLocation;
      final isLoggingIn = loc == '/login' ||
          loc == '/solicitar-cadastro' ||
          loc == '/onboarding' ||
          loc == '/';
      if (!auth.isAuthenticated && !isLoggingIn) return '/login';
      if (auth.isAuthenticated && (loc == '/login' || loc == '/')) {
        return '/selecionar-modulo';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/solicitar-cadastro',
        builder: (_, __) => const SolicitarCadastroScreen(),
      ),
      GoRoute(
        path: '/selecionar-modulo',
        builder: (_, __) => const SelecaoModuloScreen(),
      ),
      GoRoute(
        path: '/nova-reserva',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body:
                  Center(child: Text('Selecione um ativo na disponibilidade')),
            );
          }
          return NovaReservaScreen(
            ativo: extra['ativo'] as Ativo,
            inicio: extra['inicio'] as DateTime,
            fim: extra['fim'] as DateTime,
          );
        },
      ),
      GoRoute(
        path: '/checklist-form',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Reserva nao informada')),
            );
          }
          return ChecklistFormScreen(
            reserva: extra['reserva'] as Reserva,
            etapa: extra['etapa'] as String,
          );
        },
      ),
      GoRoute(path: '/sync', builder: (_, __) => const SyncScreen()),
      GoRoute(
        path: '/aprovacoes',
        builder: (_, __) => const AprovacoesScreen(),
      ),
      GoRoute(
        path: '/admin-ativos',
        builder: (_, __) => const AdminAtivosScreen(),
      ),
      GoRoute(
        path: '/admin-templates',
        builder: (_, __) => const AdminTemplatesScreen(),
      ),
      GoRoute(
        path: '/notificacoes',
        builder: (_, __) => const NotificacoesScreen(),
      ),
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/disponibilidade',
            builder: (_, __) => const DisponibilidadeScreen(),
          ),
          GoRoute(
            path: '/reservas',
            builder: (_, __) => const ReservasScreen(),
          ),
          GoRoute(
            path: '/checklists',
            builder: (_, __) => const ChecklistsScreen(),
          ),
          GoRoute(path: '/qr-scan', builder: (_, __) => const QrScanScreen()),
          GoRoute(path: '/perfil', builder: (_, __) => const PerfilScreen()),
        ],
      ),
    ],
  );
}
