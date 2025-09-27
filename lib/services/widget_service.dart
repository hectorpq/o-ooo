// lib/services/widget_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/horario_provider.dart';
import '../models/evento.dart';
import '../models/horario.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.appmobilav/widget',
  );

  /// Inicializar el servicio de widgets
  static Future<void> initialize() async {
    try {
      print('🔧 Inicializando WidgetService...');
      await _channel.invokeMethod('initialize');
      print('✅ WidgetService inicializado correctamente');
    } catch (e) {
      print('⚠️ Error inicializando WidgetService: $e');
      // No lanzar error para no interrumpir la app
    }
  }

  /// Actualizar el widget con la información actual
  static Future<void> updateWidget({
    HorarioProvider? horarioProvider,
    List<Evento>? eventos,
  }) async {
    try {
      print('🔄 Actualizando widget...');

      // Preparar datos del widget
      final widgetData = await _prepareWidgetData(
        horarioProvider: horarioProvider,
        eventos: eventos,
      );

      // Enviar datos al widget nativo
      await _channel.invokeMethod('updateWidget', widgetData);

      print('✅ Widget actualizado correctamente');
    } catch (e) {
      print('⚠️ Error actualizando widget: $e');
      // No lanzar error para no interrumpir la app
    }
  }

  /// Programar actualizaciones periódicas del widget
  static Future<void> schedulePeriodicUpdates() async {
    try {
      print('⏰ Programando actualizaciones periódicas del widget...');

      await _channel.invokeMethod('schedulePeriodicUpdates', {
        'intervalMinutes': 30, // Actualizar cada 30 minutos
      });

      print('✅ Actualizaciones periódicas programadas');
    } catch (e) {
      print('⚠️ Error programando actualizaciones: $e');
    }
  }

  /// Limpiar el widget (cuando se cierre sesión)
  static Future<void> clearWidget() async {
    try {
      print('🧹 Limpiando widget...');

      await _channel.invokeMethod('clearWidget');

      print('✅ Widget limpiado');
    } catch (e) {
      print('⚠️ Error limpiando widget: $e');
    }
  }

  /// Preparar los datos que se enviarán al widget
  static Future<Map<String, dynamic>> _prepareWidgetData({
    HorarioProvider? horarioProvider,
    List<Evento>? eventos,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Información básica
    final widgetData = <String, dynamic>{
      'lastUpdate': now.millisecondsSinceEpoch,
      'currentTime': _formatTime(now),
      'currentDate': _formatDate(now),
      'dayOfWeek': _getDayOfWeek(now.weekday),
    };

    // Agregar información de horarios si está disponible
    if (horarioProvider != null) {
      widgetData.addAll(await _getHorarioData(horarioProvider, now));
    }

    // Agregar eventos próximos si están disponibles
    if (eventos != null && eventos.isNotEmpty) {
      widgetData.addAll(_getEventosData(eventos, today));
    }

    return widgetData;
  }

  /// Obtener datos de horarios
  static Future<Map<String, dynamic>> _getHorarioData(
    HorarioProvider horarioProvider,
    DateTime now,
  ) async {
    try {
      if (!horarioProvider.tieneHorarioActivo) {
        return {'hasSchedule': false, 'scheduleStatus': 'Sin horario activo'};
      }

      // Obtener estadísticas del horario
      final estadisticas = horarioProvider.obtenerEstadisticas();
      final totalSlots = estadisticas['slotsOcupados'] as int;
      final totalMaterias = estadisticas['totalMaterias'] as int;

      // Buscar materia actual basada en día y hora
      final diaActual = _getDiaSemana(now.weekday);
      final horaActual = _getHoraSlot(now);

      final materiaActual = horarioProvider.obtenerMateria(
        diaActual,
        horaActual,
      );

      // Buscar próxima materia (esto requeriría lógica adicional)
      final proximaMateria = _buscarProximaMateria(horarioProvider, now);

      return {
        'hasSchedule': totalSlots > 0,
        'totalClassesToday': _contarClasesHoy(horarioProvider, now),
        'totalMaterias': totalMaterias,
        'currentSubject': materiaActual?.nombre ?? '',
        'currentSubjectAula': materiaActual?.aula ?? '',
        'currentSubjectProfesor': materiaActual?.profesor ?? '',
        'nextSubject': proximaMateria?.nombre ?? '',
        'nextSubjectTime': proximaMateria != null
            ? _getProximaHora(proximaMateria, horarioProvider, now)
            : '',
        'scheduleStatus': _getScheduleStatus(
          materiaActual,
          proximaMateria,
          now,
        ),
      };
    } catch (e) {
      print('⚠️ Error obteniendo datos de horario: $e');
    }

    return {'hasSchedule': false, 'scheduleStatus': 'Sin clases hoy'};
  }

  /// Obtener datos de eventos
  static Map<String, dynamic> _getEventosData(
    List<Evento> eventos,
    DateTime today,
  ) {
    try {
      // Filtrar eventos de hoy y próximos
      final eventosHoy = eventos.where((evento) {
        final eventDate = DateTime(
          evento.fecha.year,
          evento.fecha.month,
          evento.fecha.day,
        );
        return eventDate == today;
      }).toList();

      // Eventos próximos (siguientes 7 días)
      final eventosProximos = eventos.where((evento) {
        final eventDate = DateTime(
          evento.fecha.year,
          evento.fecha.month,
          evento.fecha.day,
        );
        return eventDate.isAfter(today) &&
            eventDate.isBefore(today.add(const Duration(days: 7)));
      }).toList();

      // Ordenar por fecha
      eventosHoy.sort((a, b) => a.fecha.compareTo(b.fecha));
      eventosProximos.sort((a, b) => a.fecha.compareTo(b.fecha));

      // Próximo evento de hoy
      String proximoEventoHoy = '';
      String proximoEventoHoyHora = '';
      if (eventosHoy.isNotEmpty) {
        final proximoEvento = eventosHoy.first;
        proximoEventoHoy = proximoEvento.titulo;
        proximoEventoHoyHora = _formatTime(proximoEvento.fecha);
      }

      return {
        'hasEvents': eventos.isNotEmpty,
        'eventsToday': eventosHoy.length,
        'eventsUpcoming': eventosProximos.length,
        'nextEventToday': proximoEventoHoy,
        'nextEventTodayTime': proximoEventoHoyHora,
        'nextUpcomingEvent': eventosProximos.isNotEmpty
            ? eventosProximos.first.titulo
            : '',
        'nextUpcomingEventDate': eventosProximos.isNotEmpty
            ? _formatDate(eventosProximos.first.fecha)
            : '',
      };
    } catch (e) {
      print('⚠️ Error obteniendo datos de eventos: $e');
      return {'hasEvents': false, 'eventsToday': 0, 'eventsUpcoming': 0};
    }
  }

  /// Obtener estado del horario
  static String _getScheduleStatus(
    Materia? materiaActual,
    Materia? proximaMateria,
    DateTime now,
  ) {
    if (materiaActual != null) {
      return 'En clase: ${materiaActual.nombre}';
    } else if (proximaMateria != null) {
      return 'Próxima: ${proximaMateria.nombre}';
    } else {
      final hour = now.hour;
      if (hour < 7) {
        return 'Muy temprano';
      } else if (hour > 22) {
        return 'Muy tarde';
      } else {
        return 'Sin clases';
      }
    }
  }

  /// Obtener día de la semana en formato string
  static String _getDiaSemana(int weekday) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return dias[weekday - 1];
  }

  /// Convertir hora actual a slot de horario (aproximado)
  static String _getHoraSlot(DateTime now) {
    final hour = now.hour;
    // Mapear a slots típicos de horario escolar
    if (hour >= 7 && hour < 8) return '07:00';
    if (hour >= 8 && hour < 9) return '08:00';
    if (hour >= 9 && hour < 10) return '09:00';
    if (hour >= 10 && hour < 11) return '10:00';
    if (hour >= 11 && hour < 12) return '11:00';
    if (hour >= 12 && hour < 13) return '12:00';
    if (hour >= 13 && hour < 14) return '13:00';
    if (hour >= 14 && hour < 15) return '14:00';
    if (hour >= 15 && hour < 16) return '15:00';
    if (hour >= 16 && hour < 17) return '16:00';
    if (hour >= 17 && hour < 18) return '17:00';
    if (hour >= 18 && hour < 19) return '18:00';
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  /// Buscar próxima materia (simplificado)
  static Materia? _buscarProximaMateria(
    HorarioProvider provider,
    DateTime now,
  ) {
    if (!provider.tieneHorarioActivo) return null;

    try {
      final dia = _getDiaSemana(now.weekday);
      final horaActual = now.hour;

      // Buscar en las próximas horas del día
      for (int hora = horaActual + 1; hora <= 18; hora++) {
        final slot = '${hora.toString().padLeft(2, '0')}:00';
        final materia = provider.obtenerMateria(dia, slot);
        if (materia != null) return materia;
      }

      return null;
    } catch (e) {
      print('Error buscando próxima materia: $e');
      return null;
    }
  }

  /// Contar clases de hoy
  static int _contarClasesHoy(HorarioProvider provider, DateTime now) {
    if (!provider.tieneHorarioActivo) return 0;

    try {
      final dia = _getDiaSemana(now.weekday);
      int contador = 0;

      // Verificar slots típicos del día
      final horas = [
        '07:00',
        '08:00',
        '09:00',
        '10:00',
        '11:00',
        '12:00',
        '13:00',
        '14:00',
        '15:00',
        '16:00',
        '17:00',
        '18:00',
      ];

      for (final hora in horas) {
        if (provider.tieneMateria(dia, hora)) {
          contador++;
        }
      }

      return contador;
    } catch (e) {
      print('Error contando clases: $e');
      return 0;
    }
  }

  /// Obtener hora de próxima materia
  static String _getProximaHora(
    Materia proximaMateria,
    HorarioProvider provider,
    DateTime now,
  ) {
    // Esta función requeriría más lógica para determinar exactamente cuándo es la próxima clase
    // Por simplicidad, retornamos una aproximación
    final horaActual = now.hour;
    final proximaHora = horaActual + 1;
    return '${proximaHora.toString().padLeft(2, '0')}:00';
  }

  /// Formatear tiempo a 12 horas
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Formatear tiempo a 24 horas (removido - no se usa más)

  /// Formatear fecha
  static String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  /// Obtener día de la semana
  static String _getDayOfWeek(int weekday) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[weekday - 1];
  }

  /// Método para manejar clics desde el widget
  static void setupWidgetClickHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'widgetClicked':
          print('📱 Widget clickeado - abriendo app');
          // Aquí podrías navegar a una pantalla específica
          break;
        case 'refreshRequested':
          print('🔄 Actualización solicitada desde widget');
          // Aquí podrías forzar una actualización
          break;
        default:
          print('⚠️ Método desconocido desde widget: ${call.method}');
      }
    });
  }

  /// Verificar si los widgets están soportados en este dispositivo
  static Future<bool> isWidgetSupported() async {
    try {
      final result = await _channel.invokeMethod('isSupported');
      return result as bool? ?? false;
    } catch (e) {
      print('⚠️ Error verificando soporte de widgets: $e');
      return false;
    }
  }

  /// Obtener información del widget
  static Future<Map<String, dynamic>?> getWidgetInfo() async {
    try {
      final result = await _channel.invokeMethod('getWidgetInfo');
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      print('⚠️ Error obteniendo info del widget: $e');
      return null;
    }
  }

  /// Forzar actualización inmediata del widget
  static Future<void> forceUpdate({
    HorarioProvider? horarioProvider,
    List<Evento>? eventos,
  }) async {
    print('⚡ Forzando actualización del widget...');
    await updateWidget(horarioProvider: horarioProvider, eventos: eventos);
  }
}
