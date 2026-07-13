import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/storage/offline_cache_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gdm_button.dart';
import '../../widgets/gdm_card.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  List<Map<String, dynamic>> _pendentes = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _pendentes = OfflineCacheService.listPendingChecklists();
    });
  }

  Future<void> _sincronizar() async {
    final sync = context.read<SyncProvider>();
    final conn = context.read<ConnectivityProvider>();

    if (!conn.online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Voce esta offline. Conecte-se a internet primeiro.'),
        ),
      );
      return;
    }

    final r = await sync.sincronizar();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: r.totalSucesso
            ? Colors.green.shade700
            : (r.enviados > 0 ? Colors.orange.shade700 : Colors.red.shade700),
        content: Text(r.houveSync
            ? '${r.enviados} enviado(s), ${r.falhas} falha(s)'
            : 'Nenhum pendente para sincronizar.'),
      ),
    );

    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final conn = context.watch<ConnectivityProvider>();
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronizacao'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _carregar(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status geral
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gdmBlue, AppColors.gdmBlue2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          conn.online ? Icons.cloud_done : Icons.cloud_off,
                          color: conn.online
                              ? AppColors.gdmLime
                              : Colors.red.shade300,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conn.online ? 'Online' : 'Offline',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${sync.pendentes} check-list(s) aguardando envio',
                      style: const TextStyle(
                        color: AppColors.gdmLime,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (sync.ultimoSync != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ultimo sync: ${fmt.format(sync.ultimoSync!)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Botao sincronizar
              GdmButton(
                onPressed: sync.sincronizando ? null : _sincronizar,
                label: sync.sincronizando
                    ? 'Sincronizando...'
                    : 'Sincronizar agora',
                loading: sync.sincronizando,
                icon: Icons.sync,
                expand: true,
              ),
              const SizedBox(height: 16),

              // Lista de pendentes
              if (_pendentes.isEmpty)
                const GdmCard(
                  child: EmptyState(
                    icon: Icons.cloud_done_outlined,
                    title: 'Tudo sincronizado!',
                    description: 'Nenhum check-list pendente de envio.',
                  ),
                )
              else
                ..._pendentes.map((p) => _PendenteCard(pendente: p, fmt: fmt)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendenteCard extends StatelessWidget {
  final Map<String, dynamic> pendente;
  final DateFormat fmt;
  const _PendenteCard({required this.pendente, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final etapa = pendente['etapa'] as String? ?? '';
    final criadoEm = DateTime.tryParse(pendente['criado_em_local'] ?? '');
    final tentativas = pendente['tentativas'] as int? ?? 0;
    final ultimoErro = pendente['ultimo_erro'] as String?;
    final itens = pendente['itens'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GdmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: etapa == 'RETIRADA'
                        ? Colors.blue.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    etapa == 'RETIRADA'
                        ? Icons.upload
                        : Icons.download,
                    color: etapa == 'RETIRADA'
                        ? Colors.blue.shade700
                        : Colors.green.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-list de $etapa',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (criadoEm != null)
                        Text(
                          'Preenchido em ${fmt.format(criadoEm)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (tentativas > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$tentativas tent.',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.list_alt, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${itens.length} itens preenchidos',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            if (ultimoErro != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ultimoErro,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
