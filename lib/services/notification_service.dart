import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/evento.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Inicializar timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Manejar cuando el usuario toca la notificación
        print('Notificación tocada: ${details.payload}');
      },
    );

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    await Permission.notification.request();

    // Para Android 13+ también necesitas este permiso
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  // NUEVA FUNCIÓN: Programar notificación para un evento específico
  static Future<void> programarNotificacionEvento(Evento evento) async {
    if (!evento.notificacionActiva) return;

    final now = DateTime.now();
    final fechaNotificacion = evento.fechaNotificacion;

    // Solo programar si la fecha de notificación es en el futuro
    if (fechaNotificacion.isBefore(now)) {
      print('La fecha de notificación ya pasó: $fechaNotificacion');
      return;
    }

    // Convertir a timezone local
    final scheduledDate = tz.TZDateTime.from(fechaNotificacion, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'eventos_channel',
      'Eventos',
      channelDescription: 'Notificaciones de eventos programados',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      evento.id.hashCode, // ID único basado en el ID del evento
      '🔔 ${evento.titulo}',
      'Tu evento comenzará en ${evento.minutosAntes} minutos${evento.ubicacion != null ? ' en ${evento.ubicacion}' : ''}',
      scheduledDate,
      notificationDetails,
      payload: evento.id,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    print('✅ Notificación programada para: $fechaNotificacion');
    print('   Evento: ${evento.titulo}');
    print('   ID: ${evento.id.hashCode}');
  }

  // NUEVA FUNCIÓN: Programar notificación de inicio del evento
  static Future<void> programarNotificacionInicio(Evento evento) async {
    if (!evento.notificacionActiva ||
        !evento.tiposNotificacion.contains('inicio'))
      return;

    final now = DateTime.now();

    // Notificar exactamente cuando comience el evento
    if (evento.fecha.isBefore(now)) return;

    final scheduledDate = tz.TZDateTime.from(evento.fecha, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'eventos_inicio_channel',
      'Inicio de Eventos',
      channelDescription: 'Notificaciones cuando los eventos comienzan',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      (evento.id + '_inicio').hashCode,
      '🚀 ${evento.titulo} - ¡Ya comenzó!',
      'Tu evento ha comenzado${evento.ubicacion != null ? ' en ${evento.ubicacion}' : ''}',
      scheduledDate,
      notificationDetails,
      payload: '${evento.id}_inicio',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    print('✅ Notificación de inicio programada para: ${evento.fecha}');
  }

  // NUEVA FUNCIÓN: Cancelar todas las notificaciones de un evento
  static Future<void> cancelarNotificacionesEvento(String eventoId) async {
    await _notifications.cancel(eventoId.hashCode);
    await _notifications.cancel((eventoId + '_inicio').hashCode);
    print('❌ Notificaciones canceladas para evento: $eventoId');
  }

  // NUEVA FUNCIÓN: Cancelar todas las notificaciones
  static Future<void> cancelarTodasLasNotificaciones() async {
    await _notifications.cancelAll();
    print('❌ Todas las notificaciones canceladas');
  }

  // NUEVA FUNCIÓN: Ver notificaciones pendientes (para debug)
  static Future<void> mostrarNotificacionesPendientes() async {
    final pendingNotifications = await _notifications
        .pendingNotificationRequests();
    print('📋 Notificaciones pendientes: ${pendingNotifications.length}');

    for (final notification in pendingNotifications) {
      print('   - ID: ${notification.id}');
      print('     Título: ${notification.title}');
      print('     Cuerpo: ${notification.body}');
      print('     Payload: ${notification.payload}');
      print('');
    }
  }

  // Función para mostrar notificación inmediata (la que ya tenías)
  static Future<void> mostrarNotificacionInmediata({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'inmediata_channel',
      'Notificaciones Inmediatas',
      channelDescription: 'Notificaciones que se muestran al instante',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
