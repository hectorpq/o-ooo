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

  // Flag para controlar si el widget está disponible
  static bool _isWidgetAvailable = false;

  /// Inicializar el servicio de widgets
  static Future<void> initialize() async {
    try {
      print('🔧 Inicializando WidgetService...');

      // Intentar inicializar solo si el canal está disponible
      try {
        await _channel.invokeMethod('initialize');
        _isWidgetAvailable = true;
        print('✅ WidgetService inicializado correctamente');
      } on MissingPluginException {
        _isWidgetAvailable = false;
        print('ℹ️ Widget nativo no implementado - funcionando sin widget');
      } on PlatformException catch (e) {
        _isWidgetAvailable = false;
        print('⚠️ Error de plataforma en widget: $e');
      }
    } catch (e) {
      _isWidgetAvailable = false;
      print('⚠️ Error inicializando WidgetService: $e');
    }
  }

  /// Actualizar el widget con la información actual
  static Future<void> updateWidget({
    HorarioProvider? horarioProvider,
    List<Evento>? eventos,
  }) async {
    // Si el widget no está disponible, no hacer nada
    if (!_isWidgetAvailable) {
      print('ℹ️ Widget no disponible - saltando actualización');
      return;
    }

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
    } on MissingPluginException {
      _isWidgetAvailable = false;
      print('ℹ️ Widget no implementado - deshabilitando actualizaciones');
    } catch (e) {
      print('⚠️ Error actualizando widget: $e');
    }
  }

  /// Programar actualizaciones periódicas del widget
  static Future<void> schedulePeriodicUpdates() async {
    // Si el widget no está disponible, no hacer nada
    if (!_isWidgetAvailable) {
      print('ℹ️ Widget no disponible - saltando programación periódica');
      return;
    }

    try {
      print('⏰ Programando actualizaciones periódicas del widget...');

      await _channel.invokeMethod('schedulePeriodicUpdates', {
        'intervalMinutes': 30, // Actualizar cada 30 minutos
      });

      print('✅ Actualizaciones periódicas programadas');
    } on MissingPluginException {
      _isWidgetAvailable = false;
      print(
        'ℹ️ Widget no implementado - no se pueden programar actualizaciones',
      );
    } catch (e) {
      print('! Error programando actualizaciones: $e');
    }
  }

  /// Limpiar el widget (cuando se cierre sesión)
  static Future<void> clearWidget() async {
    if (!_isWidgetAvailable) {
      print('ℹ️ Widget no disponible - no necesita limpieza');
      return;
    }

    try {
      print('🧹 Limpiando widget...');
      await _channel.invokeMethod('clearWidget');
      print('✅ Widget limpiado');
    } on MissingPluginException {
      _isWidgetAvailable = false;
      print('ℹ️ Widget no implementado - no necesita limpieza');
    } catch (e) {
      print('⚠️ Error limpiando widget: $e');
    }
  }

  /// Preparar los datos que se enviarían al widget (VERSIÓN CORREGIDA)
  static Future<Map<String, dynamic>> _prepareWidgetData({
    HorarioProvider? horarioProvider,
    List<Evento>? eventos,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Información básica que espera el widget de Android
    final widgetData = <String, dynamic>{
      'eventsToday': 0,
      'nextEventToday': '',
      'nextEventTodayTime': '',
      'scheduleStatus': 'Sin clases',
      'currentSubject': '',
      'lastUpdate': now.millisecondsSinceEpoch,
    };

    // Agregar información de horarios si está disponible
    if (horarioProvider != null && horarioProvider.tieneHorarioActivo) {
      final horarioData = await _getHorarioData(horarioProvider, now);

      // Mapear a los nombres que espera Android
      widgetData['scheduleStatus'] =
          horarioData['scheduleStatus'] ?? 'Sin clases';
      widgetData['currentSubject'] = horarioData['currentSubject'] ?? '';

      print(
        'Datos de horario para widget: ${horarioData['scheduleStatus']}, ${horarioData['currentSubject']}',
      );
    }

    // Agregar eventos de hoy si están disponibles
    if (eventos != null && eventos.isNotEmpty) {
      final eventosData = _getEventosData(eventos, today);

      // Mapear a los nombres que espera Android
      widgetData['eventsToday'] = eventosData['eventsToday'] ?? 0;
      widgetData['nextEventToday'] = eventosData['nextEventToday'] ?? '';
      widgetData['nextEventTodayTime'] =
          eventosData['nextEventTodayTime'] ?? '';

      print(
        'Datos de eventos para widget: ${eventosData['eventsToday']} eventos, próximo: ${eventosData['nextEventToday']}',
      );
    }

    print('Datos finales enviados al widget: $widgetData');
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

      // Buscar próxima materia
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
      return {'hasSchedule': false, 'scheduleStatus': 'Error en horario'};
    }
  }

  /// Obtener datos de eventos
  static Map<String, dynamic> _getEventosData(
    List<Evento> eventos,
    DateTime today,
  ) {
    try {
      // Filtrar eventos de hoy
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
      final weekday = now.weekday;

      // Si es fin de semana
      if (weekday == 6 || weekday == 7) {
        return 'Fin de semana';
      }

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

  /// Convertir hora actual a slot de horario
  static String _getHoraSlot(DateTime now) {
    final hour = now.hour;
    final minute = now.minute;

    // Mapear a slots típicos según la hora actual
    if (hour >= 7 && hour < 8) return '7:30 - 8:20 (M1)';
    if (hour >= 8 && hour < 9) return '8:25 - 9:15 (M2)';
    if (hour >= 9 && hour < 10) return '9:20 - 10:10 (M3)';
    if (hour >= 10 && hour < 11) return '10:15 - 11:05 (M4)';
    if (hour >= 11 && hour < 12) return '11:15 - 12:05 (M5)';
    if (hour >= 12 && hour < 13) return '12:10 - 13:00 (M6)';
    if (hour >= 13 && hour < 14) return '13:10 - 14:00 (T1)';
    if (hour >= 14 && hour < 15) return '14:05 - 14:55 (T2)';
    if (hour >= 15 && hour < 16) return '15:00 - 15:50 (T3)';
    if (hour >= 16 && hour < 17) return '16:00 - 16:50 (T4)';
    if (hour >= 17 && hour < 18) return '16:55 - 17:45 (T5)';
    if (hour >= 18 && hour < 19) return '17:50 - 18:40 (T6)';
    if (hour >= 19 && hour < 20) return '18:45 - 19:35 (N1)';
    if (hour >= 20 && hour < 21) return '19:40 - 20:30 (N2)';
    if (hour >= 21 && hour < 22) return '20:35 - 21:25 (N3)';
    if (hour >= 22 && hour < 23) return '21:30 - 22:20 (N4)';

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Buscar próxima materia
  static Materia? _buscarProximaMateria(
    HorarioProvider provider,
    DateTime now,
  ) {
    if (!provider.tieneHorarioActivo) return null;

    try {
      final horario = provider.horarioActivo!;
      final diaActual = _getDiaSemana(now.weekday);
      final horaActual = now.hour;

      // Lista de horarios universitarios en orden
      final horariosUniversitarios = [
        '7:30 - 8:20 (M1)',
        '8:25 - 9:15 (M2)',
        '9:20 - 10:10 (M3)',
        '10:15 - 11:05 (M4)',
        '11:15 - 12:05 (M5)',
        '12:10 - 13:00 (M6)',
        '13:10 - 14:00 (T1)',
        '14:05 - 14:55 (T2)',
        '15:00 - 15:50 (T3)',
        '16:00 - 16:50 (T4)',
        '16:55 - 17:45 (T5)',
        '17:50 - 18:40 (T6)',
        '18:45 - 19:35 (N1)',
        '19:40 - 20:30 (N2)',
        '20:35 - 21:25 (N3)',
        '21:30 - 22:20 (N4)',
      ];

      // Buscar próximas materias hoy
      for (final horarioSlot in horariosUniversitarios) {
        // Obtener la hora de inicio del slot
        final horaInicio = _extraerHoraInicio(horarioSlot);
        if (horaInicio > horaActual) {
          final materia = provider.obtenerMateria(diaActual, horarioSlot);
          if (materia != null) return materia;
        }
      }

      return null;
    } catch (e) {
      print('Error buscando próxima materia: $e');
      return null;
    }
  }

  /// Extraer hora de inicio de un slot
  static int _extraerHoraInicio(String slot) {
    try {
      final partes = slot.split(' - ');
      if (partes.isNotEmpty) {
        final horaPartes = partes[0].split(':');
        if (horaPartes.isNotEmpty) {
          return int.parse(horaPartes[0]);
        }
      }
    } catch (e) {
      print('Error extrayendo hora de $slot: $e');
    }
    return 0;
  }

  /// Contar clases de hoy
  static int _contarClasesHoy(HorarioProvider provider, DateTime now) {
    if (!provider.tieneHorarioActivo) return 0;

    try {
      final dia = _getDiaSemana(now.weekday);
      final horario = provider.horarioActivo!;

      return horario.slots
          .where((slot) => slot.dia == dia && slot.materiaId != null)
          .length;
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
    // Buscar el slot de la próxima materia
    try {
      final horario = provider.horarioActivo!;
      final dia = _getDiaSemana(now.weekday);

      final slot = horario.slots.firstWhere(
        (s) => s.dia == dia && s.materiaId == proximaMateria.id,
        orElse: () => SlotHorario(dia: dia, hora: ''),
      );

      if (slot.hora.isNotEmpty) {
        // Extraer solo la hora de inicio
        final partes = slot.hora.split(' - ');
        return partes.isNotEmpty ? partes[0] : '';
      }
    } catch (e) {
      print('Error obteniendo hora de próxima materia: $e');
    }

    return 'Próximamente';
  }

  /// Formatear tiempo a 12 horas
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Formatear fecha
  static String _formatDate(DateTime date) {
    const months = [
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

  /// Configurar manejador de clics del widget
  static void setupWidgetClickHandler() {
    if (!_isWidgetAvailable) return;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'widgetClicked':
          print('📱 Widget clickeado - abriendo app');
          break;
        case 'refreshRequested':
          print('🔄 Actualización solicitada desde widget');
          break;
        default:
          print('⚠️ Método desconocido desde widget: ${call.method}');
      }
    });
  }

  /// Verificar si los widgets están soportados
  static Future<bool> isWidgetSupported() async {
    return _isWidgetAvailable;
  }

  /// Obtener información del widget
  static Future<Map<String, dynamic>?> getWidgetInfo() async {
    if (!_isWidgetAvailable) {
      return {'available': false, 'reason': 'Widget no implementado'};
    }

    try {
      final result = await _channel.invokeMethod('getWidgetInfo');
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      print('⚠️ Error obteniendo info del widget: $e');
      return {'available': false, 'error': e.toString()};
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

  /// Obtener estado actual del servicio
  static Map<String, dynamic> getServiceStatus() {
    return {
      'isAvailable': _isWidgetAvailable,
      'channelName': 'com.example.appmobilav/widget',
      'status': _isWidgetAvailable ? 'Conectado' : 'No disponible',
    };
  }
}
