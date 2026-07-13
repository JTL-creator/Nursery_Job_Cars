import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'onboarding/onboarding_screen.dart';
import '../widgets/gdm_logo.dart';
import '../widgets/loading_indicator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    final auth = context.read<AuthProvider>();

    // Aguarda o bootstrap terminar (max 6s)
    int tentativas = 0;
    while (auth.loading && tentativas < 30) {
      await Future.delayed(const Duration(milliseconds: 200));
      tentativas++;
    }

    if (!mounted) return;
    if (auth.isAuthenticated) {
      context.go('/selecionar-modulo');
    } else {
      bool onboardingOk = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        onboardingOk = prefs.getBool(OnboardingScreen.prefKey) ?? false;
      } catch (_) {}
      if (!mounted) return;
      context.go(onboardingOk ? '/login' : '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GdmLogo(size: 80),
            SizedBox(height: 24),
            LoadingIndicator(),
            SizedBox(height: 12),
            Text('Carregando...'),
          ],
        ),
      ),
    );
  }
}
