// lib/models/evento.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fecha;

  Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
  });

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': Timestamp.fromDate(fecha),
      'createdAt': Timestamp.now(),
    };
  }

  // Crear desde Map de Firebase
  factory Evento.fromMap(Map<String, dynamic> map, String docId) {
    return Evento(
      id: docId,
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      fecha: (map['fecha'] as Timestamp).toDate(),
    );
  }

  // Crear desde DocumentSnapshot
  factory Evento.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Evento.fromMap(data, doc.id);
  }

  // Método para copiar con cambios
  Evento copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    DateTime? fecha,
  }) {
    return Evento(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
    );
  }

  @override
  String toString() {
    return 'Evento{id: $id, titulo: $titulo, descripcion: $descripcion, fecha: $fecha}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Evento &&
        other.id == id &&
        other.titulo == titulo &&
        other.descripcion == descripcion &&
        other.fecha == fecha;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        titulo.hashCode ^
        descripcion.hashCode ^
        fecha.hashCode;
  }
}
