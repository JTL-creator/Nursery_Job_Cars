import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/solicitacao_cadastro.dart';
import '../../../data/services/cadastro_service.dart';
import '../../widgets/gdm_button.dart';
import '../../widgets/gdm_text_field.dart';

class SolicitarCadastroScreen extends StatefulWidget {
  const SolicitarCadastroScreen({super.key});

  @override
  State<SolicitarCadastroScreen> createState() =>
      _SolicitarCadastroScreenState();
}

class _SolicitarCadastroScreenState extends State<SolicitarCadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _matricula = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _unidade = TextEditingController();
  final _justificativa = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nome.dispose();
    _matricula.dispose();
    _email.dispose();
    _telefone.dispose();
    _unidade.dispose();
    _justificativa.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await CadastroService.criarSolicitacao(SolicitacaoCadastro(
        nomeCompleto: _nome.text.trim(),
        matricula: _matricula.text.trim(),
        email: _email.text.trim(),
        telefone: _telefone.text.trim(),
        unidadeLotacao: _unidade.text.trim(),
        justificativa: _justificativa.text.trim(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitacao enviada! Aguarde aprovacao do administrador.'),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.extractMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar cadastro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GdmTextField(
                controller: _nome,
                label: 'Nome completo *',
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatorio' : null,
              ),
              const SizedBox(height: 12),
              GdmTextField(
                controller: _matricula,
                label: 'Matricula *',
                prefixIcon: Icons.badge_outlined,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatorio' : null,
              ),
              const SizedBox(height: 12),
              GdmTextField(
                controller: _email,
                label: 'Email *',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatorio' : null,
              ),
              const SizedBox(height: 12),
              GdmTextField(
                controller: _telefone,
                label: 'Telefone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              GdmTextField(
                controller: _unidade,
                label: 'Unidade de lotacao',
                prefixIcon: Icons.business_outlined,
              ),
              const SizedBox(height: 12),
              GdmTextField(
                controller: _justificativa,
                label: 'Justificativa',
                hint: 'Descreva brevemente por que precisa de acesso',
                prefixIcon: Icons.note_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              GdmButton(
                onPressed: _enviar,
                label: 'Enviar solicitacao',
                loading: _loading,
                icon: Icons.send,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
