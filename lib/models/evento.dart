// lib/models/evento.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String uid;
  final String categoriaId; // Nueva propiedad
  final int? duracionMinutos; // Duración estimada (opcional)
  final String? ubicacion; // Ubicación (opcional)

  // NUEVOS CAMPOS PARA NOTIFICACIONES
  final bool notificacionActiva;
  final int minutosAntes; // Minutos antes del evento para notificar
  final List<String> tiposNotificacion; // ['recordatorio', 'inicio', 'fin']
  final DateTime? ultimaNotificacion; // Última vez que se envió notificación
  final bool notificacionEnviada; // Si ya se envió la notificación principal

  Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.uid,
    this.categoriaId = 'otros', // Por defecto "Otros"
    this.duracionMinutos,
    this.ubicacion,
    // VALORES POR DEFECTO PARA NOTIFICACIONES
    this.notificacionActiva = true,
    this.minutosAntes = 15, // Por defecto 15 minutos antes
    this.tiposNotificacion = const [
      'recordatorio',
    ], // Solo recordatorio por defecto
    this.ultimaNotificacion,
    this.notificacionEnviada = false,
  });

  // Getter para fecha y hora final (si tiene duración)
  DateTime get fechaFin {
    if (duracionMinutos != null) {
      return fecha.add(Duration(minutes: duracionMinutos!));
    }
    return fecha.add(const Duration(hours: 1)); // Por defecto 1 hora
  }

  // NUEVO: Obtener fecha/hora cuando debe enviarse la notificación
  DateTime get fechaNotificacion {
    return fecha.subtract(Duration(minutes: minutosAntes));
  }

  // NUEVO: Verificar si debe enviarse notificación ahora
  bool get debeNotificarAhora {
    if (!notificacionActiva || notificacionEnviada) return false;

    final ahora = DateTime.now();
    final fechaNotif = fechaNotificacion;

    // Notificar si estamos dentro de un margen de 1 minuto de la fecha programada
    return ahora.isAfter(fechaNotif.subtract(Duration(seconds: 30))) &&
        ahora.isBefore(fechaNotif.add(Duration(seconds: 30))) &&
        fecha.isAfter(ahora); // Solo si el evento no ha pasado
  }

  // NUEVO: Verificar si debe notificar inicio del evento
  bool get debeNotificarInicio {
    if (!notificacionActiva || !tiposNotificacion.contains('inicio'))
      return false;

    final ahora = DateTime.now();
    // Notificar cuando falten 2 minutos o menos para el inicio
    return ahora.isAfter(fecha.subtract(Duration(minutes: 2))) &&
        ahora.isBefore(fecha.add(Duration(minutes: 1))) &&
        !estaEnCurso;
  }

  // NUEVO: Verificar si debe notificar fin del evento
  bool get debeNotificarFin {
    if (!notificacionActiva || !tiposNotificacion.contains('fin')) return false;

    final ahora = DateTime.now();
    final fin = fechaFin;
    // Notificar cuando el evento termine
    return ahora.isAfter(fin.subtract(Duration(minutes: 1))) &&
        ahora.isBefore(fin.add(Duration(minutes: 5)));
  }

  // Verificar si el evento está en curso
  bool get estaEnCurso {
    final ahora = DateTime.now();
    return ahora.isAfter(fecha) && ahora.isBefore(fechaFin);
  }

  // Verificar si el evento ya terminó
  bool get yaTermino {
    return DateTime.now().isAfter(fechaFin);
  }

  // Verificar si el evento es próximo (próximas 2 horas)
  bool get esProximo {
    final ahora = DateTime.now();
    final dosHorasDespues = ahora.add(const Duration(hours: 2));
    return fecha.isAfter(ahora) && fecha.isBefore(dosHorasDespues);
  }

  // NUEVO: Obtener texto descriptivo del tiempo de notificación
  String get textoTiempoNotificacion {
    if (minutosAntes == 0) return 'Al momento del evento';
    if (minutosAntes < 60) return '$minutosAntes minutos antes';

    final horas = minutosAntes ~/ 60;
    final minutos = minutosAntes % 60;

    if (minutos == 0) {
      return horas == 1 ? '1 hora antes' : '$horas horas antes';
    } else {
      return '${horas}h ${minutos}m antes';
    }
  }

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': Timestamp.fromDate(fecha),
      'categoriaId': categoriaId,
      'duracionMinutos': duracionMinutos,
      'ubicacion': ubicacion,
      'createdAt': Timestamp.now(),
      'uid': uid,
      // NUEVOS CAMPOS EN FIREBASE
      'notificacionActiva': notificacionActiva,
      'minutosAntes': minutosAntes,
      'tiposNotificacion': tiposNotificacion,
      'ultimaNotificacion': ultimaNotificacion != null
          ? Timestamp.fromDate(ultimaNotificacion!)
          : null,
      'notificacionEnviada': notificacionEnviada,
    };
  }

  // Crear desde Map de Firebase
  factory Evento.fromMap(Map<String, dynamic> map, String docId) {
    return Evento(
      id: docId,
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      fecha: (map['fecha'] as Timestamp).toDate(),
      uid: map['uid'] ?? '',
      categoriaId: map['categoriaId'] ?? 'otros',
      duracionMinutos: map['duracionMinutos'],
      ubicacion: map['ubicacion'],
      // NUEVOS CAMPOS DESDE FIREBASE
      notificacionActiva: map['notificacionActiva'] ?? true,
      minutosAntes: map['minutosAntes'] ?? 15,
      tiposNotificacion: List<String>.from(
        map['tiposNotificacion'] ?? ['recordatorio'],
      ),
      ultimaNotificacion: map['ultimaNotificacion'] != null
          ? (map['ultimaNotificacion'] as Timestamp).toDate()
          : null,
      notificacionEnviada: map['notificacionEnviada'] ?? false,
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
    String? uid,
    String? categoriaId,
    int? duracionMinutos,
    String? ubicacion,
    bool? notificacionActiva,
    int? minutosAntes,
    List<String>? tiposNotificacion,
    DateTime? ultimaNotificacion,
    bool? notificacionEnviada,
  }) {
    return Evento(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      uid: uid ?? this.uid,
      categoriaId: categoriaId ?? this.categoriaId,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      ubicacion: ubicacion ?? this.ubicacion,
      notificacionActiva: notificacionActiva ?? this.notificacionActiva,
      minutosAntes: minutosAntes ?? this.minutosAntes,
      tiposNotificacion: tiposNotificacion ?? this.tiposNotificacion,
      ultimaNotificacion: ultimaNotificacion ?? this.ultimaNotificacion,
      notificacionEnviada: notificacionEnviada ?? this.notificacionEnviada,
    );
  }

  // NUEVO: Marcar notificación como enviada
  Evento marcarNotificacionEnviada() {
    return copyWith(
      notificacionEnviada: true,
      ultimaNotificacion: DateTime.now(),
    );
  }

  // NUEVO: Resetear estado de notificación (útil si se edita el evento)
  Evento resetearNotificacion() {
    return copyWith(notificacionEnviada: false, ultimaNotificacion: null);
  }

  // Verificar si se superpone con otro evento (para detección de conflictos)
  bool seSuperponeConEvento(Evento otroEvento) {
    final inicioEste = fecha;
    final finEste = fechaFin;
    final inicioOtro = otroEvento.fecha;
    final finOtro = otroEvento.fechaFin;

    // Verificar superposición
    return inicioEste.isBefore(finOtro) && finEste.isAfter(inicioOtro);
  }

  // Obtener tiempo restante hasta el evento
  Duration tiempoRestante() {
    final ahora = DateTime.now();
    if (fecha.isAfter(ahora)) {
      return fecha.difference(ahora);
    }
    return Duration.zero;
  }

  // Formatear tiempo restante como texto
  String tiempoRestanteTexto() {
    final tiempo = tiempoRestante();
    if (tiempo == Duration.zero) return 'Ya comenzó';

    if (tiempo.inDays > 0) {
      return '${tiempo.inDays}d ${tiempo.inHours % 24}h';
    } else if (tiempo.inHours > 0) {
      return '${tiempo.inHours}h ${tiempo.inMinutes % 60}m';
    } else {
      return '${tiempo.inMinutes}m';
    }
  }

  @override
  String toString() {
    return 'Evento{id: $id, titulo: $titulo, descripcion: $descripcion, fecha: $fecha, categoria: $categoriaId, notificacion: $notificacionActiva}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Evento &&
        other.id == id &&
        other.titulo == titulo &&
        other.descripcion == descripcion &&
        other.fecha == fecha &&
        other.categoriaId == categoriaId &&
        other.notificacionActiva == notificacionActiva;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        titulo.hashCode ^
        descripcion.hashCode ^
        fecha.hashCode ^
        categoriaId.hashCode ^
        notificacionActiva.hashCode;
  }
}
