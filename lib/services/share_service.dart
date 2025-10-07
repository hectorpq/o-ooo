// lib/services/share_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../models/evento.dart';
import '../models/horario.dart';

enum OpcionImportar {
  sobrescribir, // Sobrescribe el horario activo
  crearNuevo, // Crea un nuevo horario
  cancelar, // No importa
}

class ShareService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _currentUserId => _auth.currentUser?.uid;

  // ==================== COMPARTIR EVENTO ====================

  /// Guarda un evento en Firestore para compartir y retorna el ID
  static Future<String> compartirEvento(Evento evento) async {
    try {
      print('📤 Compartiendo evento: ${evento.titulo}');

      final docRef = await _firestore.collection('eventos_compartidos').add({
        'titulo': evento.titulo,
        'descripcion': evento.descripcion,
        'fecha': Timestamp.fromDate(evento.fecha),
        'categoriaId': evento.categoriaId,
        'duracionMinutos': evento.duracionMinutos,
        'ubicacion': evento.ubicacion,
        'notificacionActiva': evento.notificacionActiva,
        'minutosAntes': evento.minutosAntes,
        'tiposNotificacion': evento.tiposNotificacion,
        'creadoPor': evento.uid,
        'fechaCompartido': Timestamp.now(),
        'tipo': 'evento',
      });

      print('✅ Evento compartido con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error al compartir evento: $e');
      throw Exception('Error al compartir evento: $e');
    }
  }

  /// Genera un link para compartir evento
  static String generarLinkEvento(String shareId) {
    // TODO: Reemplaza con tu dominio o Firebase Dynamic Links
    return 'https://agendaai.app/share/evento/$shareId';
  }

  /// Comparte evento mediante link o apps nativas
  static Future<void> compartirEventoPorLink(Evento evento) async {
    try {
      final shareId = await compartirEvento(evento);
      final link = generarLinkEvento(shareId);

      final mensaje =
          '''
📅 ${evento.titulo}

${evento.descripcion}

${evento.ubicacion != null ? '📍 ${evento.ubicacion}\n' : ''}🕐 ${_formatearFecha(evento.fecha)}

Importa este evento a tu agenda:
$link
      '''
              .trim();

      await Share.share(mensaje, subject: 'Evento: ${evento.titulo}');
      print('✅ Evento compartido por link');
    } catch (e) {
      print('❌ Error al compartir evento por link: $e');
      throw Exception('Error al compartir evento: $e');
    }
  }

  /// Importa un evento compartido desde un ID
  static Future<Evento?> importarEvento(String shareId) async {
    if (_currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      print('📥 Importando evento con ID: $shareId');

      final doc = await _firestore
          .collection('eventos_compartidos')
          .doc(shareId)
          .get();

      if (!doc.exists) {
        print('❌ Evento no encontrado');
        return null;
      }

      final data = doc.data()!;

      final evento = Evento(
        id: '', // Se generará al guardar
        titulo: data['titulo'] ?? 'Evento sin título',
        descripcion: data['descripcion'] ?? '',
        fecha: (data['fecha'] as Timestamp).toDate(),
        uid: _currentUserId!, // Usuario que importa
        categoriaId: data['categoriaId'] ?? 'otros',
        duracionMinutos: data['duracionMinutos'],
        ubicacion: data['ubicacion'],
        notificacionActiva: data['notificacionActiva'] ?? true,
        minutosAntes: data['minutosAntes'] ?? 15,
        tiposNotificacion: List<String>.from(
          data['tiposNotificacion'] ?? ['recordatorio'],
        ),
      );

      print('✅ Evento importado: ${evento.titulo}');
      return evento;
    } catch (e) {
      print('❌ Error al importar evento: $e');
      throw Exception('Error al importar evento: $e');
    }
  }

  // ==================== COMPARTIR HORARIO ====================

  /// Guarda un horario completo para compartir
  static Future<String> compartirHorario(HorarioCompleto horario) async {
    try {
      print('📤 Compartiendo horario: ${horario.nombre}');

      final docRef = await _firestore.collection('horarios_compartidos').add({
        'tipoHorario': horario.tipoHorario.toString(),
        'nombre': horario.nombre,
        'materias': horario.materias.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'slots': horario.slots.map((slot) => slot.toJson()).toList(),
        'creadoPor': horario.userId,
        'fechaCompartido': Timestamp.now(),
        'tipo': 'horario',
        'estadisticas': {
          'totalMaterias': horario.materias.length,
          'totalSlots': horario.slots.length,
        },
      });

      print('✅ Horario compartido con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error al compartir horario: $e');
      throw Exception('Error al compartir horario: $e');
    }
  }

  /// Genera link para compartir horario
  static String generarLinkHorario(String shareId) {
    return 'https://agendaai.app/share/horario/$shareId';
  }

  /// Comparte horario mediante link o apps nativas
  static Future<void> compartirHorarioPorLink(HorarioCompleto horario) async {
    try {
      final shareId = await compartirHorario(horario);
      final link = generarLinkHorario(shareId);

      final cantidadMaterias = horario.materias.length;
      final cantidadSlots = horario.slots
          .where((s) => s.materiaId != null)
          .length;

      final mensaje =
          '''
📚 ${horario.nombre}

Tipo: ${_nombreTipoHorario(horario.tipoHorario)}
Materias: $cantidadMaterias
Clases programadas: $cantidadSlots

Importa este horario a tu agenda:
$link
      '''
              .trim();

      await Share.share(mensaje, subject: 'Horario: ${horario.nombre}');
      print('✅ Horario compartido por link');
    } catch (e) {
      print('❌ Error al compartir horario por link: $e');
      throw Exception('Error al compartir horario: $e');
    }
  }

  /// Importa un horario compartido (sin guardarlo aún)
  static Future<HorarioCompleto?> obtenerHorarioCompartido(
    String shareId,
  ) async {
    if (_currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      print('📥 Obteniendo horario compartido con ID: $shareId');

      final doc = await _firestore
          .collection('horarios_compartidos')
          .doc(shareId)
          .get();

      if (!doc.exists) {
        print('❌ Horario no encontrado');
        return null;
      }

      final data = doc.data()!;

      // Convertir materias
      final materiasMap = <String, Materia>{};
      if (data['materias'] != null) {
        final materiasData = data['materias'] as Map<String, dynamic>;
        materiasData.forEach((key, value) {
          materiasMap[key] = Materia.fromJson(value as Map<String, dynamic>);
        });
      }

      // Convertir slots
      final slotsList = <SlotHorario>[];
      if (data['slots'] != null) {
        final slotsData = data['slots'] as List;
        slotsList.addAll(
          slotsData.map(
            (slot) => SlotHorario.fromJson(slot as Map<String, dynamic>),
          ),
        );
      }

      final horario = HorarioCompleto(
        id: '', // Se asignará al guardar
        userId: _currentUserId!,
        tipoHorario: TipoHorario.values.firstWhere(
          (e) => e.toString() == data['tipoHorario'],
          orElse: () => TipoHorario.escolar,
        ),
        nombre: data['nombre'] ?? 'Horario importado',
        materias: materiasMap,
        slots: slotsList,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        esActivo: false,
      );

      print('✅ Horario obtenido: ${horario.nombre}');
      print('   Materias: ${horario.materias.length}');
      print('   Slots: ${horario.slots.length}');

      return horario;
    } catch (e) {
      print('❌ Error al obtener horario compartido: $e');
      throw Exception('Error al obtener horario: $e');
    }
  }

  /// Importa un horario con opción de sobrescribir o crear nuevo
  static Future<String> importarHorario({
    required String shareId,
    required OpcionImportar opcion,
    String? nombrePersonalizado,
    String? horarioIdASobrescribir,
  }) async {
    if (_currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      print('📥 Importando horario...');
      print('   Opción: $opcion');

      // Obtener el horario compartido
      final horarioCompartido = await obtenerHorarioCompartido(shareId);

      if (horarioCompartido == null) {
        throw Exception('No se pudo obtener el horario compartido');
      }

      String horarioId;

      switch (opcion) {
        case OpcionImportar.sobrescribir:
          if (horarioIdASobrescribir == null) {
            throw Exception('Se requiere horarioId para sobrescribir');
          }

          print(
            '🔄 Sobrescribiendo horario existente: $horarioIdASobrescribir',
          );

          // Actualizar el horario existente
          await _firestore
              .collection('horarios')
              .doc(horarioIdASobrescribir)
              .update({
                'materias': horarioCompartido.materias.map(
                  (key, value) => MapEntry(key, value.toJson()),
                ),
                'slots': horarioCompartido.slots
                    .map((s) => s.toJson())
                    .toList(),
                'tipoHorario': horarioCompartido.tipoHorario.toString(),
                'nombre': nombrePersonalizado ?? horarioCompartido.nombre,
                'fechaActualizacion': DateTime.now().toIso8601String(),
              });

          horarioId = horarioIdASobrescribir;
          print('✅ Horario sobrescrito exitosamente');
          break;

        case OpcionImportar.crearNuevo:
          print('🆕 Creando nuevo horario');

          // Desactivar otros horarios activos
          final horariosActivos = await _firestore
              .collection('horarios')
              .where('userId', isEqualTo: _currentUserId)
              .where('esActivo', isEqualTo: true)
              .get();

          final batch = _firestore.batch();
          for (final doc in horariosActivos.docs) {
            batch.update(doc.reference, {
              'esActivo': false,
              'fechaActualizacion': DateTime.now().toIso8601String(),
            });
          }
          await batch.commit();

          // Crear nuevo horario
          final nuevoHorario = horarioCompartido.copyWith(
            nombre:
                nombrePersonalizado ??
                '${horarioCompartido.nombre} (importado)',
            esActivo: true,
          );

          final docRef = await _firestore
              .collection('horarios')
              .add(nuevoHorario.toJson());

          await docRef.update({'id': docRef.id});

          horarioId = docRef.id;
          print('✅ Nuevo horario creado: $horarioId');
          break;

        case OpcionImportar.cancelar:
          throw Exception('Importación cancelada por el usuario');
      }

      return horarioId;
    } catch (e) {
      print('❌ Error al importar horario: $e');
      throw Exception('Error al importar horario: $e');
    }
  }

  // ==================== GENERAR DATOS PARA QR ====================

  /// Genera string JSON para QR de evento
  static String generarQREvento(String shareId) {
    return jsonEncode({
      'tipo': 'evento',
      'shareId': shareId,
      'app': 'agenda_ai',
      'version': '1.0',
    });
  }

  /// Genera string JSON para QR de horario
  static String generarQRHorario(String shareId) {
    return jsonEncode({
      'tipo': 'horario',
      'shareId': shareId,
      'app': 'agenda_ai',
      'version': '1.0',
    });
  }

  /// Procesa datos escaneados de QR
  static Map<String, dynamic>? procesarQRData(String qrData) {
    try {
      final data = jsonDecode(qrData);

      // Verificar que sea de nuestra app
      if (data['app'] != 'agenda_ai') {
        print('⚠️ QR no es de la app Agenda AI');
        return null;
      }

      print('✅ QR procesado: ${data['tipo']} - ${data['shareId']}');

      return {
        'tipo': data['tipo'],
        'shareId': data['shareId'],
        'version': data['version'] ?? '1.0',
      };
    } catch (e) {
      print('❌ Error al procesar QR: $e');
      return null;
    }
  }

  // ==================== VERIFICAR DISPONIBILIDAD ====================

  /// Verifica si un evento/horario compartido existe
  static Future<bool> verificarDisponibilidad({
    required String shareId,
    required String tipo,
  }) async {
    try {
      final coleccion = tipo == 'evento'
          ? 'eventos_compartidos'
          : 'horarios_compartidos';

      final doc = await _firestore.collection(coleccion).doc(shareId).get();

      return doc.exists;
    } catch (e) {
      print('❌ Error al verificar disponibilidad: $e');
      return false;
    }
  }

  // ==================== UTILIDADES ====================

  static String _formatearFecha(DateTime fecha) {
    final meses = [
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

    final mes = meses[fecha.month - 1];
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '${fecha.day} $mes ${fecha.year} - $hora:$minuto';
  }

  static String _nombreTipoHorario(TipoHorario tipo) {
    switch (tipo) {
      case TipoHorario.escolar:
        return 'Escolar';
      case TipoHorario.colegio:
        return 'Colegio';
      case TipoHorario.universidad:
        return 'Universidad';
    }
  }
}
