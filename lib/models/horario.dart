// lib/models/horario.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoHorario { escolar, colegio, universidad }

class Materia {
  final String id;
  final String nombre;
  final String profesor;
  final String aula;
  final String colorHex; // Guardamos el color como string hex
  final DateTime? fechaCreacion;

  Materia({
    required this.id,
    required this.nombre,
    required this.profesor,
    required this.aula,
    required this.colorHex,
    this.fechaCreacion,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'profesor': profesor,
      'aula': aula,
      'colorHex': colorHex,
      'fechaCreacion': fechaCreacion?.toIso8601String(),
    };
  }

  // Crear desde Map de Firestore
  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      profesor: json['profesor'] ?? 'Sin profesor',
      aula: json['aula'] ?? 'Sin aula',
      colorHex: json['colorHex'] ?? '#2196F3', // Azul por defecto
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : null,
    );
  }

  Materia copyWith({
    String? id,
    String? nombre,
    String? profesor,
    String? aula,
    String? colorHex,
    DateTime? fechaCreacion,
  }) {
    return Materia(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      profesor: profesor ?? this.profesor,
      aula: aula ?? this.aula,
      colorHex: colorHex ?? this.colorHex,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

class SlotHorario {
  final String dia;
  final String hora;
  final String? materiaId; // Referencia al ID de la materia
  final DateTime? fechaActualizacion;

  SlotHorario({
    required this.dia,
    required this.hora,
    this.materiaId,
    this.fechaActualizacion,
  });

  Map<String, dynamic> toJson() {
    return {
      'dia': dia,
      'hora': hora,
      'materiaId': materiaId,
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  factory SlotHorario.fromJson(Map<String, dynamic> json) {
    return SlotHorario(
      dia: json['dia'] ?? '',
      hora: json['hora'] ?? '',
      materiaId: json['materiaId'],
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'])
          : null,
    );
  }
}

class HorarioCompleto {
  final String id;
  final String userId;
  final TipoHorario tipoHorario;
  final String nombre; // Nombre del horario (ej: "Semestre 2024-1")
  final Map<String, Materia> materias; // Map de ID -> Materia
  final List<SlotHorario> slots; // Lista de todos los slots
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool esActivo; // Si es el horario actualmente en uso

  HorarioCompleto({
    required this.id,
    required this.userId,
    required this.tipoHorario,
    required this.nombre,
    required this.materias,
    required this.slots,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.esActivo = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tipoHorario': tipoHorario.toString(),
      'nombre': nombre,
      'materias': materias.map((key, value) => MapEntry(key, value.toJson())),
      'slots': slots.map((slot) => slot.toJson()).toList(),
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
      'esActivo': esActivo,
    };
  }

  factory HorarioCompleto.fromJson(Map<String, dynamic> json) {
    // Convertir materias
    final materiasMap = <String, Materia>{};
    if (json['materias'] != null) {
      final materiasData = json['materias'] as Map<String, dynamic>;
      materiasData.forEach((key, value) {
        materiasMap[key] = Materia.fromJson(value as Map<String, dynamic>);
      });
    }

    // Convertir slots
    final slotsList = <SlotHorario>[];
    if (json['slots'] != null) {
      final slotsData = json['slots'] as List;
      slotsList.addAll(
        slotsData.map(
          (slot) => SlotHorario.fromJson(slot as Map<String, dynamic>),
        ),
      );
    }

    return HorarioCompleto(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      tipoHorario: TipoHorario.values.firstWhere(
        (e) => e.toString() == json['tipoHorario'],
        orElse: () => TipoHorario.escolar,
      ),
      nombre: json['nombre'] ?? 'Horario sin nombre',
      materias: materiasMap,
      slots: slotsList,
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaActualizacion: DateTime.parse(json['fechaActualizacion']),
      esActivo: json['esActivo'] ?? false,
    );
  }

  HorarioCompleto copyWith({
    String? id,
    String? userId,
    TipoHorario? tipoHorario,
    String? nombre,
    Map<String, Materia>? materias,
    List<SlotHorario>? slots,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool? esActivo,
  }) {
    return HorarioCompleto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tipoHorario: tipoHorario ?? this.tipoHorario,
      nombre: nombre ?? this.nombre,
      materias: materias ?? this.materias,
      slots: slots ?? this.slots,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      esActivo: esActivo ?? this.esActivo,
    );
  }
}
