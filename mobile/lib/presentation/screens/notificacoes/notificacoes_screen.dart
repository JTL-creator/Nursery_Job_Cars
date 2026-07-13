import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gdm_card.dart';

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  List<PendingNotificationRequest> _pendentes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final list = await NotificationService.listarPendentes();
      setState(() => _pendentes = list);
    } catch (e) {
      debugPrint('[NOTIF] Erro ao listar: $e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  Future<void> _testar() async {
    await NotificationService.showSimple(
      'Teste de notificacao',
      'Se voce esta vendo isso, as notificacoes estao funcionando!',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Notificacao de teste enviada!'),
        ),
      );
    }
  }

  Future<void> _solicitarPermissao() async {
    await NotificationService.requestPermission();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissao solicitada')),
      );
    }
  }

  Future<void> _cancelarTodas() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar lembretes'),
        content: const Text(
          'Isso cancelara todos os lembretes agendados. '
          'Voce nao recebera mais avisos de reservas pendentes. Tem certeza?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nao'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar todos'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await NotificationService.cancelarTodas();
      _carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lembretes cancelados')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificacoes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card de info
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
                    const Row(
                      children: [
                        Icon(Icons.notifications_active,
                            color: AppColors.gdmLime),
                        SizedBox(width: 8),
                        Text(
                          'Lembretes ativos',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      kIsWeb
                          ? 'Web (limitado)'
                          : '${_pendentes.length} lembrete(s) agendado(s)',
                      style: const TextStyle(
                        color: AppColors.gdmLime,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (kIsWeb)
                GdmCard(
                  child: Column(
                    children: [
                      Icon(Icons.web,
                          size: 40, color: Colors.orange.shade700),
                      const SizedBox(height: 8),
                      const Text(
                        'Notificacoes no Web sao limitadas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'O agendamento e ideal no app Android. '
                        'No navegador, apenas notificacoes imediatas funcionam.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else ...[
                // Acoes
                GdmCard(
                  title: 'Acoes',
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notifications_active_outlined,
                            color: Colors.blue),
                        title: const Text('Habilitar permissao'),
                        subtitle: const Text('Necessario para receber lembretes'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _solicitarPermissao,
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notifications_paused,
                            color: Colors.green),
                        title: const Text('Testar notificacao'),
                        subtitle: const Text('Envia uma notificacao imediata'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _testar,
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notifications_off,
                            color: Colors.red),
                        title: const Text('Cancelar todos os lembretes'),
                        subtitle: const Text('Remove todos os agendamentos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _cancelarTodas,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Lista de pendentes
                if (_carregando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_pendentes.isEmpty)
                  const GdmCard(
                    child: EmptyState(
                      icon: Icons.notifications_none,
                      title: 'Nenhum lembrete agendado',
                      description:
                          'Quando voce criar reservas, os lembretes aparecerao aqui.',
                    ),
                  )
                else
                  GdmCard(
                    title: 'Lembretes agendados (${_pendentes.length})',
                    child: Column(
                      children: _pendentes
                          .map((p) => _NotifTile(notif: p))
                          .toList(),
                    ),
                  ),
              ],

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Para cada reserva criada, agendamos 3 lembretes: '
                        '1h antes do inicio, 30min antes do fim, e no fim exato.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final PendingNotificationRequest notif;
  const _NotifTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.notifications;
    Color color = AppColors.gdmBlue;
    final t = notif.title ?? '';
    if (t.contains('proxima')) {
      icon = Icons.access_time;
      color = Colors.blue.shade700;
    } else if (t.contains('devolucao') || t.contains('Hora')) {
      icon = Icons.notifications_active;
      color = Colors.orange.shade700;
    } else if (t.contains('encerrada')) {
      icon = Icons.warning;
      color = Colors.red.shade700;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title ?? '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (notif.body != null)
                  Text(
                    notif.body!,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  'ID: ${notif.id}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
