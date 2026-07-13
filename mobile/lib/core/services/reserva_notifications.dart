import 'package:flutter/foundation.dart';
import '../../data/models/reserva.dart';
import 'notification_service.dart';

/// Helper para agendar notificacoes de uma reserva.
/// Usa hash do id da reserva para gerar IDs unicos.
class ReservaNotifications {
  /// Agenda lembretes para uma reserva nova.
  /// 
  /// Lembretes:
  /// - 1h antes do inicio: "Sua reserva comeca em 1h"
  /// - 30min antes do fim: "Sua reserva termina em 30min - hora da devolucao"
  /// - No fim exato: "Reserva encerrada - faca a devolucao"
  static Future<void> agendarParaReserva(Reserva r) async {
    final agora = DateTime.now();
    final inicio = r.dataHoraInicio;
    final fim = r.dataHoraFim;
    final ativo = r.codigoInterno ?? 'ativo';

    final baseId = r.id.hashCode.abs() % 1000000;

    // 1. Aviso de inicio (1h antes)
    final avisoInicio = inicio.subtract(const Duration(hours: 1));
    if (avisoInicio.isAfter(agora)) {
      await NotificationService.agendar(
        id: baseId + 1,
        title: '⏰ Reserva proxima',
        body: 'Sua reserva do $ativo comeca em 1 hora '
              '(${_fmtHora(inicio)}).',
        quando: avisoInicio,
        payload: 'reserva:${r.id}',
      );
    }

    // 2. Lembrete de devolucao (30min antes do fim)
    final avisoDevolucao = fim.subtract(const Duration(minutes: 30));
    if (avisoDevolucao.isAfter(agora)) {
      await NotificationService.agendar(
        id: baseId + 2,
        title: '🔔 Hora da devolucao',
        body: 'Sua reserva do $ativo termina em 30 minutos. '
              'Prepare a devolucao!',
        quando: avisoDevolucao,
        payload: 'reserva:${r.id}',
      );
    }

    // 3. Aviso no fim exato
    if (fim.isAfter(agora)) {
      await NotificationService.agendar(
        id: baseId + 3,
        title: '⚠️ Reserva encerrada',
        body: 'O periodo da sua reserva do $ativo terminou. '
              'Faca o check-list de devolucao.',
        quando: fim,
        payload: 'reserva:${r.id}',
      );
    }

    debugPrint('[NOTIF] Lembretes agendados para reserva ${r.id}');
  }

  /// Cancela todos os lembretes de uma reserva (em caso de cancelamento).
  static Future<void> cancelarParaReserva(String reservaId) async {
    final baseId = reservaId.hashCode.abs() % 1000000;
    await NotificationService.cancelar(baseId + 1);
    await NotificationService.cancelar(baseId + 2);
    await NotificationService.cancelar(baseId + 3);
    debugPrint('[NOTIF] Lembretes cancelados para reserva $reservaId');
  }

  static String _fmtHora(DateTime d) =>
      '${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
}
