// lib/providers/event_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento.dart';

class EventProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'eventos';

  List<Evento> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Evento> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Referencia a la colección
  CollectionReference get _eventsCollection =>
      _firestore.collection(_collection);

  // Cargar eventos desde Firebase
  Future<void> loadEvents() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final querySnapshot = await _eventsCollection
          .orderBy('fecha', descending: false)
          .get();

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

      // Crear el evento en Firebase
      final docRef = await _eventsCollection.add(event.toMap());

      // Crear el evento con el ID real de Firebase
      final eventoConId = event.copyWith(id: docRef.id);

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

  // Escuchar cambios en tiempo real
  void listenToEvents() {
    eventsStream.listen(
      (eventos) {
        _events = eventos;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error al escuchar eventos: $error';
        notifyListeners();
      },
    );
  }

  // Limpiar errores
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Método para testing - NO USAR EN PRODUCCIÓN
  Future<void> loadDummyEvents() async {
    final dummyEvents = [
      Evento(
        id: '',
        titulo: 'Reunión de proyecto',
        descripcion: 'Revisión semanal del progreso',
        fecha: DateTime.now(),
      ),
      Evento(
        id: '',
        titulo: 'Examen de Matemáticas',
        descripcion: 'Capítulo 5 y 6',
        fecha: DateTime.now().add(const Duration(days: 1)),
      ),
      Evento(
        id: '',
        titulo: 'Tarea de Historia',
        descripcion: 'Investigar la Revolución Francesa',
        fecha: DateTime.now().add(const Duration(days: 2)),
      ),
    ];

    for (var evento in dummyEvents) {
      await addEvent(evento);
    }
  }
}
