// lib/providers/event_provider.dart
import 'package:flutter/material.dart';
import '../models/evento.dart';

class EventProvider with ChangeNotifier {
  final List<Evento> _events = [];

  // Obtener todos los eventos
  List<Evento> get events => List.unmodifiable(_events);

  // Agregar un evento
  void addEvent(Evento event) {
    _events.add(event);
    notifyListeners();
  }

  // Actualizar un evento por id
  void updateEvent(String id, Evento updatedEvent) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      _events[index] = updatedEvent;
      notifyListeners();
    }
  }

  // Eliminar un evento por id
  void deleteEvent(String id) {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
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

  // Cargar eventos de prueba para testing
  void loadDummyEvents() {
    _events.clear();
    _events.addAll([
      Evento(
        id: '1',
        titulo: 'Reunión de proyecto',
        descripcion: 'Revisión semanal del progreso',
        fecha: DateTime.now(),
      ),
      Evento(
        id: '2',
        titulo: 'Examen de Matemáticas',
        descripcion: 'Capítulo 5 y 6',
        fecha: DateTime.now().add(const Duration(days: 1)),
      ),
      Evento(
        id: '3',
        titulo: 'Tarea de Historia',
        descripcion: 'Investigar la Revolución Francesa',
        fecha: DateTime.now().add(const Duration(days: 2)),
      ),
    ]);
    notifyListeners();
  }
}
