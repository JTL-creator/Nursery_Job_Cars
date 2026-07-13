import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/portaria_verificacao.dart';
import '../../../data/services/portaria_service.dart';
import '../../widgets/gdm_button.dart';
import '../../widgets/gdm_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/plate_scanner.dart';

/// Tela da portaria (vigilante): le a placa do veiculo, confere se ele esta
/// liberado para sair (reserva aprovada + check-list de retirada + horario) e
/// permite registrar a movimentacao de SAIDA/ENTRADA.
class PortariaScreen extends StatefulWidget {
  const PortariaScreen({super.key});

  @override
  State<PortariaScreen> createState() => _PortariaScreenState();
}

class _PortariaScreenState extends State<PortariaScreen> {
  PortariaVerificacao? _resultado;
  bool _verificando = false;
  bool _registrando = false;
  String? _erro;

  Future<void> _verificar(String placa) async {
    setState(() {
      _verificando = true;
      _erro = null;
      _resultado = null;
    });
    try {
      final res = await PortariaService.verificar(placa);
      if (!mounted) return;
      setState(() {
        _resultado = res;
        _verificando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = ApiClient.extractMessage(e);
        _verificando = false;
      });
    }
  }

  void _novaLeitura() {
    setState(() {
      _resultado = null;
      _erro = null;
    });
  }

  Future<void> _registrar(String tipo, {required bool liberado}) async {
    final res = _resultado;
    if (res == null || res.ativoId == null) return;

    // Saida bloqueada: exige confirmacao explicita do vigilante.
    if (tipo == 'SAIDA' && !liberado) {
      final confirma = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Saida NAO autorizada'),
          content: const Text(
            'Este veiculo nao esta liberado para sair. Deseja registrar a '
            'saida mesmo assim? A ocorrencia ficara registrada como nao '
            'autorizada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Registrar assim mesmo'),
            ),
          ],
        ),
      );
      if (confirma != true) return;
    }

    setState(() => _registrando = true);
    try {
      await PortariaService.registrarMovimentacao(
        ativoId: res.ativoId!,
        reservaId: res.reservaId,
        tipo: tipo,
        placa: res.placa,
        liberado: liberado,
        motivo: liberado ? null : res.motivos.join(' | '),
      );
      if (!mounted) return;
      setState(() => _registrando = false);
      final ok = tipo == 'ENTRADA' || liberado;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? AppColors.success : AppColors.danger,
          content: Text(
            tipo == 'SAIDA'
                ? (liberado
                    ? 'Saida registrada com sucesso.'
                    : 'Saida NAO autorizada registrada.')
                : 'Entrada registrada com sucesso.',
          ),
        ),
      );
      _novaLeitura();
    } catch (e) {
      if (!mounted) return;
      setState(() => _registrando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(ApiClient.extractMessage(e)),
        ),
      );
    }
  }

  Future<void> _abrirHistorico() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _HistoricoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _verificando
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: LoadingIndicator()),
            )
          : (_resultado == null ? _buildLeitura() : _buildResultado()),
    );
  }

  Widget _buildLeitura() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GdmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.gdmBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Conferencia de saida',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Aponte a camera para a placa do veiculo para conferir se ele '
                'esta liberado para sair da unidade.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PlateScanner(
          onPlaca: _verificar,
          legenda: 'Aponte a camera para a placa do veiculo',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _abrirHistorico,
          icon: const Icon(Icons.history),
          label: const Text('Historico de movimentacoes'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.gdmBlue),
        ),
        if (_erro != null) ...[
          const SizedBox(height: 12),
          GdmCard(
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(child: Text(_erro!)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultado() {
    final res = _resultado!;

    if (!res.encontrado) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusBanner(
            liberado: false,
            titulo: 'Veiculo nao encontrado',
            subtitulo: 'Placa ${res.placa}',
          ),
          const SizedBox(height: 12),
          GdmCard(
            child: Column(
              children: res.motivos
                  .map((m) => _MotivoLinha(texto: m, ok: false))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          GdmButton(
            onPressed: _novaLeitura,
            label: 'Nova leitura',
            icon: Icons.center_focus_strong,
            expand: true,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusBanner(
          liberado: res.liberado,
          titulo: res.liberado ? 'LIBERADO PARA SAIR' : 'SAIDA BLOQUEADA',
          subtitulo:
              '${res.ativoCodigo ?? ''}  •  ${res.ativoPlaca ?? res.placa}',
        ),
        const SizedBox(height: 12),

        // Conferencias
        GdmCard(
          title: 'Conferencias',
          child: Column(
            children: [
              _MotivoLinha(
                texto: 'Reserva aprovada (confirmada)',
                ok: res.reservaAprovada,
              ),
              _MotivoLinha(
                texto: 'Check-list de retirada realizado',
                ok: res.checklistRetirada,
              ),
              _MotivoLinha(
                texto: 'Dentro do horario autorizado',
                ok: res.dentroJanela,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Dados do veiculo
        GdmCard(
          title: 'Veiculo',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoLinha('Descricao', res.ativoDescricao ?? '-'),
              _InfoLinha('Placa', res.ativoPlaca ?? res.placa),
              if ((res.unidade ?? '').isNotEmpty)
                _InfoLinha('Unidade', res.unidade!),
              if ((res.responsavelNome ?? '').isNotEmpty)
                _InfoLinha('Responsavel', res.responsavelNome!),
            ],
          ),
        ),

        // Dados da reserva
        if (res.reservaId != null) ...[
          const SizedBox(height: 12),
          GdmCard(
            title: 'Reserva',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLinha('Condutor', res.usuarioNome ?? '-'),
                _InfoLinha('Status', res.reservaStatus ?? '-'),
                _InfoLinha(
                  'Periodo',
                  '${_fmtData(res.inicio)} ate ${_fmtData(res.fim)}',
                ),
                if ((res.motivoReserva ?? '').isNotEmpty)
                  _InfoLinha('Motivo', res.motivoReserva!),
              ],
            ),
          ),
        ],

        // Motivos de bloqueio
        if (!res.liberado && res.motivos.isNotEmpty) ...[
          const SizedBox(height: 12),
          GdmCard(
            title: 'Por que esta bloqueado',
            child: Column(
              children: res.motivos
                  .map((m) => _MotivoLinha(texto: m, ok: false))
                  .toList(),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Acoes
        if (res.liberado)
          GdmButton(
            onPressed:
                _registrando ? null : () => _registrar('SAIDA', liberado: true),
            label: 'Registrar SAIDA',
            icon: Icons.logout,
            loading: _registrando,
            expand: true,
          )
        else
          GdmButton(
            onPressed: _registrando
                ? null
                : () => _registrar('SAIDA', liberado: false),
            label: 'Registrar saida NAO autorizada',
            icon: Icons.report_gmailerrorred,
            variant: GdmButtonVariant.danger,
            loading: _registrando,
            expand: true,
          ),
        const SizedBox(height: 10),
        GdmButton(
          onPressed:
              _registrando ? null : () => _registrar('ENTRADA', liberado: true),
          label: 'Registrar ENTRADA',
          icon: Icons.login,
          variant: GdmButtonVariant.secondary,
          expand: true,
        ),
        const SizedBox(height: 10),
        GdmButton(
          onPressed: _registrando ? null : _novaLeitura,
          label: 'Nova leitura',
          icon: Icons.center_focus_strong,
          variant: GdmButtonVariant.ghost,
          expand: true,
        ),
      ],
    );
  }
}

String _fmtData(DateTime? d) {
  if (d == null) return '-';
  final l = d.toLocal();
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(l.day)}/${dois(l.month)} ${dois(l.hour)}:${dois(l.minute)}';
}

class _StatusBanner extends StatelessWidget {
  final bool liberado;
  final String titulo;
  final String subtitulo;

  const _StatusBanner({
    required this.liberado,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final cor = liberado ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            liberado ? Icons.check_circle_outline : Icons.block,
            color: Colors.white,
            size: 44,
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MotivoLinha extends StatelessWidget {
  final String texto;
  final bool ok;

  const _MotivoLinha({required this.texto, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? AppColors.success : AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  final String label;
  final String valor;

  const _InfoLinha(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Folha inferior com o historico de movimentacoes da portaria.
class _HistoricoSheet extends StatefulWidget {
  const _HistoricoSheet();

  @override
  State<_HistoricoSheet> createState() => _HistoricoSheetState();
}

class _HistoricoSheetState extends State<_HistoricoSheet> {
  bool _carregando = true;
  String? _erro;
  List<MovimentacaoPortaria> _itens = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final list = await PortariaService.historico(limit: 30);
      if (!mounted) return;
      setState(() {
        _itens = list;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = ApiClient.extractMessage(e);
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Historico de movimentacoes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Expanded(
              child: _carregando
                  ? const Center(child: LoadingIndicator())
                  : _erro != null
                      ? Center(child: Text(_erro!))
                      : _itens.isEmpty
                          ? const Center(
                              child: Text('Nenhuma movimentacao registrada.'),
                            )
                          : ListView.separated(
                              controller: scroll,
                              itemCount: _itens.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final m = _itens[i];
                                final saida = m.tipo == 'SAIDA';
                                final cor = !m.liberado
                                    ? AppColors.danger
                                    : (saida
                                        ? AppColors.warning
                                        : AppColors.success);
                                return ListTile(
                                  leading: Icon(
                                    saida ? Icons.logout : Icons.login,
                                    color: cor,
                                  ),
                                  title: Text(
                                    '${m.tipo}  •  ${m.placa ?? m.ativoCodigo ?? '-'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      m.ativoDescricao ?? '',
                                      if (!m.liberado) 'NAO AUTORIZADA',
                                      if ((m.vigilanteNome ?? '').isNotEmpty)
                                        'Vig.: ${m.vigilanteNome}',
                                    ].where((s) => s.isNotEmpty).join('  •  '),
                                  ),
                                  trailing: Text(
                                    _fmtData(m.criadoEm),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        );
      },
    );
  }
}
