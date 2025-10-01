// lib/providers/event_provider.dart
import 'dart:async';
import 'package:agenda_ai/services/widget_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class EventProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'eventos';

  List<Evento> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Variable para controlar la suscripción en tiempo real
  StreamSubscription<QuerySnapshot>? _eventsSubscription;

  // Getters
  List<Evento> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Referencia a la colección
  CollectionReference get _eventsCollection =>
      _firestore.collection(_collection);

  // Escuchar cambios de usuario y reiniciar la suscripción
  void listenToUserChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      stopListening();
      if (user != null) {
        listenToEvents();
      } else {
        _events = [];
        notifyListeners();
      }
    });
  }

  // Cargar eventos desde Firebase SOLO del usuario actual
  Future<void> loadEvents() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _events = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final querySnapshot = await _eventsCollection
          .where('uid', isEqualTo: user.uid)
          .orderBy('fecha', descending: false)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: Firestore no respondió en 10 segundos');
            },
          );

      _events = querySnapshot.docs
          .map((doc) => Evento.fromSnapshot(doc))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar eventos: $e';
      notifyListeners();
    }
  }

  // CORREGIDO: Agregar un evento a Firebase sin duplicación
  Future<void> addEvent(Evento event) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Asociar el evento al usuario actual
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final eventoConUid = event.copyWith(uid: user.uid);
      final docRef = await _eventsCollection.add(eventoConUid.toMap());

      // REMOVIDO: _events.add(eventoConId);
      // El listener en tiempo real se encarga de actualizar la lista automáticamente

      // PROGRAMAR NOTIFICACIONES si están activas
      if (eventoConUid.notificacionActiva) {
        // Crear evento con ID para las notificaciones
        final eventoConId = eventoConUid.copyWith(id: docRef.id);
        await _programarNotificacionesEvento(eventoConId);

        // Mostrar confirmación inmediata SOLO de que se programó
        await NotificationService.mostrarNotificacionInmediata(
          title: '✅ Evento creado',
          body: 'Se programó recordatorio para "${eventoConUid.titulo}"',
        );
      }
      //codigo para actualizar el widgetcuando creas evento
      await WidgetService.updateWidget();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al crear evento: $e';
      notifyListeners();
      rethrow;
    }
  }

  // MEJORADO: Actualizar un evento en Firebase con reprogramación de notificaciones
  Future<void> updateEvent(String id, Evento updatedEvent) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Cancelar notificaciones existentes del evento
      await NotificationService.cancelarNotificacionesEvento(id);

      await _eventsCollection.doc(id).update(updatedEvent.toMap());

      // El listener en tiempo real se encargará de actualizar la lista local
      // Pero reprogramamos notificaciones inmediatamente
      final eventoActualizado = updatedEvent.copyWith(id: id);
      if (eventoActualizado.notificacionActiva) {
        await _programarNotificacionesEvento(eventoActualizado);
      }
      await WidgetService.updateWidget();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al actualizar evento: $e';
      notifyListeners();
      rethrow;
    }
  }

  // MEJORADO: Eliminar un evento de Firebase cancelando sus notificaciones
  Future<void> deleteEvent(String id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Cancelar notificaciones del evento antes de eliminar
      await NotificationService.cancelarNotificacionesEvento(id);

      await _eventsCollection.doc(id).delete();

      // El listener en tiempo real se encargará de actualizar la lista local
      await WidgetService.updateWidget();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al eliminar evento: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Método privado mejorado para programar todas las notificaciones de un evento
  Future<void> _programarNotificacionesEvento(Evento evento) async {
    try {
      if (!evento.notificacionActiva) return;

      // Solo programar si la notificación es en el futuro
      final fechaNotificacion = evento.fechaNotificacion;
      if (fechaNotificacion.isBefore(DateTime.now())) {
        print(
          '⚠️ No se puede programar notificación en el pasado para ${evento.titulo}',
        );
        return;
      }

      // Programar notificación de recordatorio
      await NotificationService.programarNotificacionEvento(evento);
      print(
        '🔔 Notificación de recordatorio programada para ${evento.titulo} el $fechaNotificacion',
      );

      // Programar notificación de inicio si está configurada
      if (evento.tiposNotificacion?.contains('inicio') == true) {
        await NotificationService.programarNotificacionInicio(evento);
        print('🚀 Notificación de inicio programada para ${evento.titulo}');
      }
    } catch (e) {
      print('❌ Error al programar notificaciones: $e');
    }
  }

  // Actualizar configuración de notificaciones de un evento específico
  Future<void> actualizarNotificacionEvento(
    String eventoId, {
    bool? activa,
    int? minutosAntes,
    List<String>? tipos,
  }) async {
    try {
      final index = _events.indexWhere((e) => e.id == eventoId);
      if (index == -1) {
        _errorMessage = 'Evento no encontrado';
        notifyListeners();
        return;
      }

      final evento = _events[index];

      // Cancelar notificaciones existentes
      await NotificationService.cancelarNotificacionesEvento(eventoId);

      // Crear evento actualizado
      final eventoActualizado = evento.copyWith(
        notificacionActiva: activa ?? evento.notificacionActiva,
        minutosAntes: minutosAntes ?? evento.minutosAntes,
        tiposNotificacion: tipos ?? evento.tiposNotificacion,
        notificacionEnviada:
            false, // Resetear para que pueda notificar de nuevo
      );

      // Programar nuevas notificaciones si están activas
      if (eventoActualizado.notificacionActiva) {
        await _programarNotificacionesEvento(eventoActualizado);
      }

      // Actualizar en Firebase (el listener se encarga de actualizar localmente)
      await _eventsCollection.doc(eventoId).update(eventoActualizado.toMap());

      print(
        '✅ Configuración de notificaciones actualizada para ${evento.titulo}',
      );
    } catch (e) {
      print('❌ Error al actualizar notificación: $e');
      _errorMessage = 'Error al actualizar notificación: $e';
      notifyListeners();
    }
  }

  // Alternar estado de notificación de un evento
  Future<void> toggleNotificacion(String eventoId) async {
    try {
      final index = _events.indexWhere((e) => e.id == eventoId);
      if (index != -1) {
        final evento = _events[index];
        final nuevoEstado = !evento.notificacionActiva;

        await actualizarNotificacionEvento(eventoId, activa: nuevoEstado);

        if (nuevoEstado) {
          print('🔔 Notificación activada para ${evento.titulo}');
        } else {
          print('🔕 Notificación desactivada para ${evento.titulo}');
        }
      }
    } catch (e) {
      print('❌ Error al alternar notificación: $e');
      _errorMessage = 'Error al actualizar notificación: $e';
      notifyListeners();
    }
  }

  // Actualizar minutos antes de notificación
  Future<void> updateMinutosAntes(String eventoId, int nuevosMinutos) async {
    try {
      await actualizarNotificacionEvento(eventoId, minutosAntes: nuevosMinutos);

      final evento = getById(eventoId);
      if (evento != null) {
        print(
          '⏰ Tiempo de notificación actualizado a $nuevosMinutos minutos para ${evento.titulo}',
        );
      }
    } catch (e) {
      print('❌ Error al actualizar minutos antes: $e');
      _errorMessage = 'Error al actualizar tiempo de notificación: $e';
      notifyListeners();
    }
  }

  // Marcar notificación como enviada
  Future<void> marcarNotificacionEnviada(String eventoId) async {
    try {
      final index = _events.indexWhere((e) => e.id == eventoId);
      if (index != -1) {
        final evento = _events[index];
        final eventoActualizado = evento.copyWith(notificacionEnviada: true);

        // Actualizar en Firebase
        await _eventsCollection.doc(eventoId).update(eventoActualizado.toMap());
        // El listener actualizará la lista local automáticamente

        print('✅ Notificación marcada como enviada para ${evento.titulo}');
      }
    } catch (e) {
      print('❌ Error al marcar notificación: $e');
    }
  }

  // Verificar eventos que deben notificar ahora
  Future<void> verificarNotificacionesPendientes() async {
    try {
      for (final evento in _events) {
        if (evento.debeNotificarAhora) {
          await NotificationService.mostrarNotificacionInmediata(
            title: 'Recordatorio: ${evento.titulo}',
            body: 'Tu evento comenzará en ${evento.minutosAntes} minutos',
            payload: evento.id,
          );

          // Marcar como enviada
          await marcarNotificacionEnviada(evento.id);
        }
      }
    } catch (e) {
      print('❌ Error al verificar notificaciones: $e');
    }
  }

  // Obtener eventos que necesitan notificación pronto
  List<Evento> get eventosConNotificacionProxima {
    final ahora = DateTime.now();
    final enUnaHora = ahora.add(const Duration(hours: 1));

    return _events.where((evento) {
      if (!evento.notificacionActiva || evento.notificacionEnviada)
        return false;
      final fechaNotif = evento.fechaNotificacion;
      return fechaNotif.isAfter(ahora) && fechaNotif.isBefore(enUnaHora);
    }).toList();
  }

  // Obtener evento por id
  Evento? getById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // Obtener eventos de un día específico
  List<Evento> getEventsByDate(DateTime date) {
    return _events
        .where(
          (e) =>
              e.fecha.year == date.year &&
              e.fecha.month == date.month &&
              e.fecha.day == date.day,
        )
        .toList();
  }

  // Agrupar eventos por fecha para el calendario
  Map<DateTime, List<Evento>> get eventsGroupedByDate {
    final Map<DateTime, List<Evento>> map = {};
    for (var e in _events) {
      final day = DateTime(e.fecha.year, e.fecha.month, e.fecha.day);
      if (!map.containsKey(day)) {
        map[day] = [];
      }
      map[day]!.add(e);
    }
    return map;
  }

  // Stream para escuchar cambios en tiempo real
  Stream<List<Evento>> get eventsStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _eventsCollection
        .where('uid', isEqualTo: user.uid)
        .orderBy('fecha', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Evento.fromSnapshot(doc)).toList(),
        );
  }

  // CORREGIDO: Escuchar cambios en tiempo real con control de suscripción
  void listenToEvents() {
    try {
      // Cancelar suscripción anterior si existe
      _eventsSubscription?.cancel();

      // Crear nueva suscripción SOLO para el usuario actual
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _events = [];
        notifyListeners();
        return;
      }

      _eventsSubscription = _eventsCollection
          .where('uid', isEqualTo: user.uid)
          .orderBy('fecha', descending: false)
          .snapshots()
          .listen(
            (snapshot) {
              // Actualizar la lista completa desde Firebase
              _events = snapshot.docs
                  .map((doc) => Evento.fromSnapshot(doc))
                  .toList();
              notifyListeners();
              print(
                '🔥 Eventos actualizados en tiempo real: ${_events.length}',
              );
            },
            onError: (error) {
              _errorMessage = 'Error al escuchar eventos: $error';
              notifyListeners();
              print('❌ Error en tiempo real: $error');
            },
          );

      print('🎧 Escucha de eventos en tiempo real iniciada');
    } catch (e) {
      print('❌ Error al iniciar escucha: $e');
      _errorMessage = 'Error al iniciar sincronización: $e';
      notifyListeners();
    }
  }

  // Detener la escucha en tiempo real
  void stopListening() {
    try {
      _eventsSubscription?.cancel();
      _eventsSubscription = null;
      print('🔇 Escucha de eventos detenida');
    } catch (e) {
      print('❌ Error al detener escucha: $e');
    }
  }

  // Limpiar errores
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    print('🧹 Limpiando EventProvider...');
    stopListening();
    super.dispose();
  }
}
