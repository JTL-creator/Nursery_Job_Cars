import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gdm_button.dart';
import '../../widgets/gdm_card.dart';
import '../../widgets/gdm_logo.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final u = auth.user;
    final isDark = theme.mode == ThemeMode.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GdmCard(
            child: Row(
              children: [
                const GdmLogo(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u?.nomeCompleto ?? '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gdmLime,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          auth.perfil ?? '—',
                          style: const TextStyle(
                            color: AppColors.gdmBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(u?.email ?? '—',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Matricula: ${u?.matricula ?? "—"}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Unidade: ${u?.unidadeLotacao ?? "—"}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GdmCard(
            title: 'Preferencias',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Modo escuro'),
              subtitle: const Text('Reduz o cansaco visual em ambientes escuros'),
              value: isDark,
              activeThumbColor: AppColors.gdmLime,
              onChanged: (_) => theme.toggle(),
            ),
          ),
          const SizedBox(height: 12),
          const GdmCard(
            title: 'Sobre',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Aplicativo:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Spacer(),
                    Text(AppConstants.appName,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text('Versao:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Spacer(),
                    Text(AppConstants.appVersion,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GdmButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            label: 'Sair',
            icon: Icons.logout,
            variant: GdmButtonVariant.danger,
            expand: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
