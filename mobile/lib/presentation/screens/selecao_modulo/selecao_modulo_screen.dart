import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/module_provider.dart';

/// Tela exibida logo apos o login para o usuario escolher entre
/// o modulo de Veiculos ou o de Maquinas.
class SelecaoModuloScreen extends StatelessWidget {
  const SelecaoModuloScreen({super.key});

  void _selecionar(BuildContext context, AppModule m) async {
    HapticFeedback.selectionClick();
    await context.read<ModuleProvider>().selecionar(m);
    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firstName = (auth.user?.nomeCompleto.split(' ').first) ?? 'Usuario';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gdmBlue, AppColors.gdmBlue2],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout,
                        color: Colors.white70, size: 18),
                    label: const Text('Sair',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ola, $firstName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'O que voce quer gerenciar agora?',
                  style: TextStyle(color: AppColors.gdmLime, fontSize: 14),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ModuloCard(
                        icon: Icons.directions_car,
                        titulo: 'Veiculos',
                        descricao: 'Carros e demais veiculos da frota',
                        onTap: () => _selecionar(context, AppModule.veiculos),
                      ),
                      const SizedBox(height: 20),
                      _ModuloCard(
                        icon: Icons.agriculture,
                        titulo: 'Maquinas',
                        descricao: 'Maquinas agricolas e implementos',
                        onTap: () => _selecionar(context, AppModule.maquinas),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Voce podera trocar de modulo a qualquer momento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuloCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  const _ModuloCard({
    required this.icon,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.gdmLime.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 34, color: AppColors.gdmBlue),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gdmBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gdmBlue),
            ],
          ),
        ),
      ),
    );
  }
}
