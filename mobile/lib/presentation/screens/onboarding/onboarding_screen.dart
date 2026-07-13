import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/gdm_logo.dart';

class _Slide {
  final IconData icon;
  final String titulo;
  final String descricao;
  const _Slide(this.icon, this.titulo, this.descricao);
}

/// Onboarding exibido no primeiro acesso ao app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const prefKey = 'onboarding_concluido';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _slides = <_Slide>[
    _Slide(
      Icons.event_available_outlined,
      'Reserve com facilidade',
      'Veiculos e maquinas agricolas em poucos toques, com disponibilidade em tempo real.',
    ),
    _Slide(
      Icons.fact_check_outlined,
      'Aprovacao inteligente',
      'As reservas de ativos com responsavel passam por uma aprovacao rapida, direto no app.',
    ),
    _Slide(
      Icons.offline_bolt_outlined,
      'Check-list e modo offline',
      'Faca check-lists de retirada e devolucao mesmo sem internet. Tudo sincroniza depois.',
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _concluir() async {
    HapticFeedback.mediumImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(OnboardingScreen.prefKey, true);
    } catch (_) {}
    if (mounted) context.go('/login');
  }

  void _proximo() {
    HapticFeedback.selectionClick();
    if (_page < _slides.length - 1) {
      _pc.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _concluir();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ultima = _page == _slides.length - 1;
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
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _concluir,
                  child: const Text('Pular',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _slides.length,
                  itemBuilder: (_, i) {
                    final s = _slides[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (i == 0) ...[
                            const GdmLogo(size: 88),
                            const SizedBox(height: 28),
                          ],
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              color: AppColors.gdmLime.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(s.icon,
                                size: 64, color: AppColors.gdmLime),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            s.titulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            s.descricao,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Indicadores
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final ativo = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: ativo ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ativo ? AppColors.gdmLime : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _proximo,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gdmLime,
                      foregroundColor: AppColors.gdmBlue,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(ultima ? 'Comecar' : 'Proximo'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
