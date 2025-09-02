// lib/providers/event_provider.dart
import 'dart:async'; // ✨ NUEVO: Importar para StreamSubscription
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventProvider with ChangeNotifier {
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'eventos';

  List<Evento> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ✨ NUEVO: Variable para controlar la suscripción en tiempo real
  StreamSubscription<QuerySnapshot>? _eventsSubscription;

  // Getters
  List<Evento> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Referencia a la colección
  CollectionReference get _eventsCollection =>
      _firestore.collection(_collection);

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

  // Agregar un evento a Firebase
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
      // Crear el evento con el ID real de Firebase
      final eventoConId = eventoConUid.copyWith(id: docRef.id);
      // Agregar a la lista local
      _events.add(eventoConId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al crear evento: $e';
      notifyListeners();
      rethrow; // Re-lanzar el error para que lo manejes en la UI
    }
  }

  // Actualizar un evento en Firebase
  Future<void> updateEvent(String id, Evento updatedEvent) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _eventsCollection.doc(id).update(updatedEvent.toMap());

      // Actualizar en la lista local
      final index = _events.indexWhere((e) => e.id == id);
      if (index != -1) {
        _events[index] = updatedEvent.copyWith(id: id);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al actualizar evento: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Eliminar un evento de Firebase
  Future<void> deleteEvent(String id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _eventsCollection.doc(id).delete();

      // Eliminar de la lista local
      _events.removeWhere((e) => e.id == id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al eliminar evento: $e';
      notifyListeners();
      rethrow;
    }
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
    return _eventsCollection
        .orderBy('fecha', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Evento.fromSnapshot(doc)).toList(),
        );
  }

  // ✨ MEJORADO: Escuchar cambios en tiempo real con control de suscripción
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

  // ✨ NUEVO: Detener la escucha en tiempo real
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

  // ✨ NUEVO: Sobrescribir dispose para limpiar recursos
  @override
  void dispose() {
    print('🧹 Limpiando EventProvider...');
    stopListening();
    super.dispose();
    // Ejemplo en MainScreen:
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<EventProvider>().listenToUserChanges();
    // });
  }
}
