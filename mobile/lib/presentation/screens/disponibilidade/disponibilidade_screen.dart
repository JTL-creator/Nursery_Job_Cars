import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ativo.dart';
import '../../../data/services/ativo_service.dart';
import '../../providers/module_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gdm_button.dart';
import '../../widgets/gdm_card.dart';
import '../../widgets/loading_indicator.dart';

class DisponibilidadeScreen extends StatefulWidget {
  const DisponibilidadeScreen({super.key});

  @override
  State<DisponibilidadeScreen> createState() => _DisponibilidadeScreenState();
}

class _DisponibilidadeScreenState extends State<DisponibilidadeScreen> {
  DateTime _inicio = DateTime.now().add(const Duration(hours: 1));
  DateTime _fim = DateTime.now().add(const Duration(hours: 9));
  String? _tipoSelecionado;
  List<Ativo> _ativos = [];
  bool _carregando = false;
  bool _jaConsultou = false;

  final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  Future<void> _selecionarData(bool ehInicio) async {
    final base = ehInicio ? _inicio : _fim;
    final data = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (data == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (hora == null || !mounted) return;

    final dt =
        DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    setState(() {
      if (ehInicio) {
        _inicio = dt;
        if (_fim.isBefore(_inicio.add(const Duration(hours: 1)))) {
          _fim = _inicio.add(const Duration(hours: 8));
        }
      } else {
        _fim = dt;
      }
    });
  }

  Future<void> _consultar() async {
    if (_fim.difference(_inicio).inHours < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periodo minimo: 1 hora')),
      );
      return;
    }
    setState(() {
      _carregando = true;
      _jaConsultou = true;
    });
    try {
      final module = context.read<ModuleProvider>();
      final list = await AtivoService.disponibilidade(
        inicio: _inicio,
        fim: _fim,
        tipoAtivo: _tipoSelecionado,
        categoria: _tipoSelecionado == null ? module.categoria : null,
      );
      setState(() => _ativos = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.extractMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _reservar(Ativo a) {
    context.push('/nova-reserva', extra: {
      'ativo': a,
      'inicio': _inicio,
      'fim': _fim,
    });
  }

  @override
  Widget build(BuildContext context) {
    final module = context.watch<ModuleProvider>();
    final ehMaquinas = module.modulo == AppModule.maquinas;
    return RefreshIndicator(
      onRefresh: _consultar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gdmBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(module.icone, size: 18, color: AppColors.gdmBlue),
                  const SizedBox(width: 8),
                  Text('Modulo: ${module.label}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GdmCard(
              title: 'Periodo',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('Inicio'),
                    subtitle: Text(_fmt.format(_inicio)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: () => _selecionarData(true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.stop_circle_outlined),
                    title: const Text('Fim'),
                    subtitle: Text(_fmt.format(_fim)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: () => _selecionarData(false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (ehMaquinas)
              GdmCard(
                title: 'Tipo',
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todas'),
                      selected: _tipoSelecionado == null,
                      onSelected: (_) =>
                          setState(() => _tipoSelecionado = null),
                    ),
                    ChoiceChip(
                      label: const Text('Maq. Agricola'),
                      selected: _tipoSelecionado == 'MAQUINA_AGRICOLA',
                      onSelected: (_) =>
                          setState(() => _tipoSelecionado = 'MAQUINA_AGRICOLA'),
                    ),
                    ChoiceChip(
                      label: const Text('Implemento'),
                      selected: _tipoSelecionado == 'IMPLEMENTO',
                      onSelected: (_) =>
                          setState(() => _tipoSelecionado = 'IMPLEMENTO'),
                    ),
                  ],
                ),
              ),
            if (ehMaquinas) const SizedBox(height: 12),
            GdmButton(
              onPressed: _consultar,
              label: 'Consultar disponibilidade',
              loading: _carregando,
              icon: Icons.search,
              expand: true,
            ),
            const SizedBox(height: 16),
            if (_carregando)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: LoadingIndicator()),
              )
            else if (!_jaConsultou)
              const GdmCard(
                child: EmptyState(
                  icon: Icons.tune,
                  title: 'Defina o periodo e consulte',
                  description: 'Os ativos disponiveis aparecerao aqui.',
                ),
              )
            else if (_ativos.isEmpty)
              const GdmCard(
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'Nenhum ativo encontrado',
                  description: 'Tente outro periodo ou tipo de ativo.',
                ),
              )
            else
              ..._ativos.map(
                  (a) => _AtivoCard(ativo: a, onReservar: () => _reservar(a))),
          ],
        ),
      ),
    );
  }
}

class _AtivoCard extends StatelessWidget {
  final Ativo ativo;
  final VoidCallback onReservar;
  const _AtivoCard({required this.ativo, required this.onReservar});

  @override
  Widget build(BuildContext context) {
    final disponivel = ativo.disponivel ?? true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GdmCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (disponivel ? AppColors.gdmLime : Colors.grey)
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                ativo.tipoAtivo == 'VEICULO'
                    ? Icons.directions_car
                    : ativo.tipoAtivo == 'MAQUINA_AGRICOLA'
                        ? Icons.agriculture
                        : Icons.build,
                color: disponivel ? AppColors.gdmBlue : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ativo.codigoInterno,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(ativo.descricao, style: const TextStyle(fontSize: 13)),
                  if (ativo.placa != null)
                    Text('Placa: ${ativo.placa}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (ativo.unidade != null)
                    Text(ativo.unidade!,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: disponivel
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      disponivel ? 'Disponivel' : 'Indisponivel no periodo',
                      style: TextStyle(
                        color: disponivel
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (disponivel)
              GdmButton(
                onPressed: onReservar,
                label: 'Reservar',
                icon: Icons.bookmark_add,
              ),
          ],
        ),
      ),
    );
  }
}
