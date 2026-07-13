import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Servico de notificacoes locais com suporte a agendamento.
/// No web e no-op (limitacoes do navegador).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'gdm_job_cars';
  static const String _channelName = 'GDM Job Cars';
  static const String _channelDesc =
      'Notificacoes de reservas, lembretes e sincronizacao';

  static Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    // Inicializa timezone
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (_) {
      // fallback se nao encontrar
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static const NotificationDetails _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Mostra uma notificacao imediata.
  static Future<void> showSimple(String title, String body) async {
    if (kIsWeb) return;
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _detalhes,
    );
  }

  /// Agenda uma notificacao para um horario futuro.
  /// Retorna o id usado (util para cancelar depois).
  static Future<int?> agendar({
    required int id,
    required String title,
    required String body,
    required DateTime quando,
    String? payload,
  }) async {
    if (kIsWeb) return null;
    if (quando.isBefore(DateTime.now())) {
      debugPrint('[NOTIF] Horario no passado, ignorando agendamento: $quando');
      return null;
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(quando, tz.local),
        _detalhes,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('[NOTIF] Agendada #$id para $quando: $title');
      return id;
    } catch (e) {
      debugPrint('[NOTIF] Erro ao agendar: $e');
      return null;
    }
  }

  /// Cancela uma notificacao agendada.
  static Future<void> cancelar(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  /// Cancela todas as notificacoes pendentes.
  static Future<void> cancelarTodas() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  /// Lista as notificacoes pendentes (uteis para debug).
  static Future<List<PendingNotificationRequest>> listarPendentes() async {
    if (kIsWeb) return [];
    return await _plugin.pendingNotificationRequests();
  }
}
