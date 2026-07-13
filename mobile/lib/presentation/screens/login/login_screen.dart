import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gdm_button.dart';
import '../../widgets/gdm_logo.dart';
import '../../widgets/gdm_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _loading = false;
  bool _esconderSenha = true;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.login(_email.text.trim(), _senha.text);
      if (!mounted) return;
      if (auth.isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 4),
            content: const Text(
              'Voce entrou em modo offline. Alguns dados podem estar '
              'desatualizados e serao sincronizados quando houver conexao.',
            ),
          ),
        );
      }
      context.go('/selecionar-modulo');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(ApiClient.extractMessage(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gdmBlue, AppColors.gdmBlue2, AppColors.gdmLime],
            stops: [0.0, 0.55, 1.4],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: GdmLogo()),
                        const SizedBox(height: 14),
                        const Center(
                          child: Text(
                            'GDM Job Cars',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gdmBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Center(
                          child: Text(
                            'Acesse sua conta para continuar',
                            style:
                                TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 28),
                        GdmTextField(
                          controller: _email,
                          label: 'Email',
                          hint: 'seu.email@gdm.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Informe o email'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _senha,
                          obscureText: _esconderSenha,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _esconderSenha
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _esconderSenha = !_esconderSenha),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Informe a senha'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        GdmButton(
                          onPressed: _entrar,
                          label: 'Entrar',
                          loading: _loading,
                          icon: Icons.login,
                          expand: true,
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () => context.go('/solicitar-cadastro'),
                          child: const Text('Solicitar cadastro'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
