// lib/services/horario_service.dart - VERSION CON DEBUG Y VALIDACIONES
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/horario.dart';

class HorarioService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Referencia a la colección de horarios
  static CollectionReference get _horariosCollection =>
      _firestore.collection('horarios');

  // Obtener el usuario actual con validación mejorada
  static String? get _currentUserId {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ HorarioService: Usuario no autenticado');
        return null;
      }
      print('✅ HorarioService: Usuario actual: ${user.uid}');
      return user.uid;
    } catch (e) {
      print('❌ HorarioService: Error al obtener usuario actual: $e');
      return null;
    }
  }

  /// Validar que el usuario esté autenticado
  static void _validateUser() {
    if (_currentUserId == null) {
      throw Exception('Usuario no autenticado. Por favor, inicia sesión.');
    }
  }

  /// Crear un nuevo horario
  static Future<String> crearHorario({
    required TipoHorario tipoHorario,
    required String nombre,
  }) async {
    print('🆕 HorarioService: Creando horario $nombre ($tipoHorario)');

    _validateUser();

    try {
      // Desactivar otros horarios activos
      await _desactivarHorariosActivos();

      final horario = HorarioCompleto(
        id: '', // Se asignará automáticamente
        userId: _currentUserId!,
        tipoHorario: tipoHorario,
        nombre: nombre,
        materias: {},
        slots: [],
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        esActivo: true,
      );

      print('📝 Guardando horario en Firestore...');
      final docRef = await _horariosCollection.add(horario.toJson());

      // Actualizar con el ID generado
      await docRef.update({'id': docRef.id});

      print('✅ Horario creado con ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      print('❌ Error al crear horario: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtener el horario activo del usuario
  static Future<HorarioCompleto?> obtenerHorarioActivo() async {
    print('🔍 HorarioService: Buscando horario activo...');

    if (_currentUserId == null) {
      print('⚠️ Usuario no autenticado, retornando null');
      return null;
    }

    try {
      print('📡 Consultando Firestore...');
      final querySnapshot = await _horariosCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('esActivo', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('ℹ️ No se encontró horario activo');
        return null;
      }

      final horario = HorarioCompleto.fromJson(
        querySnapshot.docs.first.data() as Map<String, dynamic>,
      );

      print('✅ Horario activo encontrado: ${horario.id} - ${horario.nombre}');
      print(
        '📊 Materias: ${horario.materias.length}, Slots: ${horario.slots.length}',
      );

      return horario;
    } catch (e, stackTrace) {
      print('❌ Error al obtener horario activo: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtener todos los horarios del usuario
  static Future<List<HorarioCompleto>> obtenerTodosLosHorarios() async {
    print('🔍 HorarioService: Obteniendo todos los horarios...');

    if (_currentUserId == null) {
      print('⚠️ Usuario no autenticado, retornando lista vacía');
      return [];
    }

    try {
      final querySnapshot = await _horariosCollection
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('fechaActualizacion', descending: true)
          .get();

      final horarios = querySnapshot.docs
          .map(
            (doc) =>
                HorarioCompleto.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();

      print('✅ Horarios obtenidos: ${horarios.length}');
      return horarios;
    } catch (e, stackTrace) {
      print('❌ Error al obtener horarios: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Agregar una materia al horario
  static Future<void> agregarMateria({
    required String horarioId,
    required Materia materia,
    required String dia,
    required String hora,
  }) async {
    print(
      '📚 HorarioService: Agregando materia ${materia.nombre} a $dia $hora',
    );
    _validateUser();

    try {
      final horarioRef = _horariosCollection.doc(horarioId);

      await _firestore.runTransaction((transaction) async {
        final horarioSnapshot = await transaction.get(horarioRef);

        if (!horarioSnapshot.exists) {
          throw Exception('Horario no encontrado: $horarioId');
        }

        final horarioData = horarioSnapshot.data() as Map<String, dynamic>;
        final horario = HorarioCompleto.fromJson(horarioData);

        print('📝 Procesando horario: ${horario.nombre}');

        // Agregar la materia
        final nuevasMaterias = Map<String, Materia>.from(horario.materias);
        nuevasMaterias[materia.id] = materia;

        // Agregar o actualizar el slot
        final nuevosSlots = List<SlotHorario>.from(horario.slots);

        // Remover slot existente si existe
        nuevosSlots.removeWhere((s) => s.dia == dia && s.hora == hora);

        // Agregar nuevo slot
        nuevosSlots.add(
          SlotHorario(
            dia: dia,
            hora: hora,
            materiaId: materia.id,
            fechaActualizacion: DateTime.now(),
          ),
        );

        final horarioActualizado = horario.copyWith(
          materias: nuevasMaterias,
          slots: nuevosSlots,
          fechaActualizacion: DateTime.now(),
        );

        transaction.update(horarioRef, horarioActualizado.toJson());
        print('✅ Materia agregada exitosamente');
      });
    } catch (e, stackTrace) {
      print('❌ Error al agregar materia: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Remover una materia del horario
  static Future<void> removerMateria({
    required String horarioId,
    required String dia,
    required String hora,
  }) async {
    print('🗑️ HorarioService: Removiendo materia de $dia $hora');
    _validateUser();

    try {
      final horarioRef = _horariosCollection.doc(horarioId);

      await _firestore.runTransaction((transaction) async {
        final horarioSnapshot = await transaction.get(horarioRef);

        if (!horarioSnapshot.exists) {
          throw Exception('Horario no encontrado: $horarioId');
        }

        final horarioData = horarioSnapshot.data() as Map<String, dynamic>;
        final horario = HorarioCompleto.fromJson(horarioData);

        // Encontrar el slot a remover
        final slotARemover = horario.slots.firstWhere(
          (s) => s.dia == dia && s.hora == hora,
          orElse: () => SlotHorario(dia: dia, hora: hora),
        );

        // Remover slot
        final nuevosSlots = List<SlotHorario>.from(horario.slots);
        nuevosSlots.removeWhere((s) => s.dia == dia && s.hora == hora);

        // Remover materia si ya no se usa
        final nuevasMaterias = Map<String, Materia>.from(horario.materias);
        if (slotARemover.materiaId != null) {
          final materiaEnUso = nuevosSlots.any(
            (s) => s.materiaId == slotARemover.materiaId,
          );
          if (!materiaEnUso) {
            nuevasMaterias.remove(slotARemover.materiaId);
            print(
              '🗑️ Materia ${slotARemover.materiaId} removida completamente',
            );
          }
        }

        final horarioActualizado = horario.copyWith(
          materias: nuevasMaterias,
          slots: nuevosSlots,
          fechaActualizacion: DateTime.now(),
        );

        transaction.update(horarioRef, horarioActualizado.toJson());
        print('✅ Materia removida exitosamente');
      });
    } catch (e, stackTrace) {
      print('❌ Error al remover materia: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Cambiar tipo de horario (limpia todo el horario actual)
  static Future<void> cambiarTipoHorario({
    required String horarioId,
    required TipoHorario nuevoTipo,
  }) async {
    print('🔄 HorarioService: Cambiando tipo de horario a $nuevoTipo');
    _validateUser();

    try {
      final horarioRef = _horariosCollection.doc(horarioId);

      await horarioRef.update({
        'tipoHorario': nuevoTipo.toString(),
        'materias': {},
        'slots': [],
        'fechaActualizacion': DateTime.now().toIso8601String(),
      });

      print('✅ Tipo de horario cambiado exitosamente');
    } catch (e, stackTrace) {
      print('❌ Error al cambiar tipo de horario: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Limpiar todo el horario
  static Future<void> limpiarHorario(String horarioId) async {
    print('🧹 HorarioService: Limpiando horario $horarioId');
    _validateUser();

    try {
      final horarioRef = _horariosCollection.doc(horarioId);

      await horarioRef.update({
        'materias': {},
        'slots': [],
        'fechaActualizacion': DateTime.now().toIso8601String(),
      });

      print('✅ Horario limpiado exitosamente');
    } catch (e, stackTrace) {
      print('❌ Error al limpiar horario: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Activar un horario específico
  static Future<void> activarHorario(String horarioId) async {
    print('🔄 HorarioService: Activando horario $horarioId');
    _validateUser();

    try {
      await _desactivarHorariosActivos();

      final horarioRef = _horariosCollection.doc(horarioId);
      await horarioRef.update({
        'esActivo': true,
        'fechaActualizacion': DateTime.now().toIso8601String(),
      });

      print('✅ Horario activado exitosamente');
    } catch (e, stackTrace) {
      print('❌ Error al activar horario: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Eliminar un horario
  static Future<void> eliminarHorario(String horarioId) async {
    print('🗑️ HorarioService: Eliminando horario $horarioId');
    _validateUser();

    try {
      await _horariosCollection.doc(horarioId).delete();
      print('✅ Horario eliminado exitosamente');
    } catch (e, stackTrace) {
      print('❌ Error al eliminar horario: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Duplicar un horario existente
  static Future<String> duplicarHorario({
    required String horarioId,
    required String nuevoNombre,
  }) async {
    print('📋 HorarioService: Duplicando horario $horarioId -> $nuevoNombre');
    _validateUser();

    try {
      final horarioSnapshot = await _horariosCollection.doc(horarioId).get();

      if (!horarioSnapshot.exists) {
        throw Exception('Horario no encontrado para duplicar: $horarioId');
      }

      final horarioOriginal = HorarioCompleto.fromJson(
        horarioSnapshot.data() as Map<String, dynamic>,
      );

      // Desactivar otros horarios activos
      await _desactivarHorariosActivos();

      final horarioNuevo = horarioOriginal.copyWith(
        id: '', // Se asignará automáticamente
        nombre: nuevoNombre,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        esActivo: true,
      );

      final docRef = await _horariosCollection.add(horarioNuevo.toJson());

      // Actualizar con el ID generado
      await docRef.update({'id': docRef.id});

      print('✅ Horario duplicado con ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      print('❌ Error al duplicar horario: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Stream para escuchar cambios en el horario activo
  static Stream<HorarioCompleto?> streamHorarioActivo() {
    print('📡 HorarioService: Creando stream de horario activo...');

    if (_currentUserId == null) {
      print('⚠️ Usuario no autenticado para stream');
      return Stream.value(null);
    }

    try {
      return _horariosCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('esActivo', isEqualTo: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              print('📡 Stream: No hay horario activo');
              return null;
            }

            final horario = HorarioCompleto.fromJson(
              snapshot.docs.first.data() as Map<String, dynamic>,
            );

            print('📡 Stream: Horario activo actualizado: ${horario.id}');
            return horario;
          })
          .handleError((error, stackTrace) {
            print('❌ Error en stream de horario: $error');
            print('📍 Stack trace: $stackTrace');
          });
    } catch (e, stackTrace) {
      print('❌ Error al crear stream: $e');
      print('📍 Stack trace: $stackTrace');
      return Stream.value(null);
    }
  }

  /// Método privado para desactivar horarios activos
  static Future<void> _desactivarHorariosActivos() async {
    if (_currentUserId == null) {
      print('⚠️ No se pueden desactivar horarios: usuario no autenticado');
      return;
    }

    try {
      print('🔄 Desactivando horarios activos...');

      final querySnapshot = await _horariosCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('esActivo', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('ℹ️ No hay horarios activos para desactivar');
        return;
      }

      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'esActivo': false,
          'fechaActualizacion': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      print('✅ ${querySnapshot.docs.length} horarios desactivados');
    } catch (e, stackTrace) {
      print('❌ Error al desactivar horarios activos: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtener estadísticas del horario
  static Future<Map<String, dynamic>> obtenerEstadisticas(
    String horarioId,
  ) async {
    print('📊 HorarioService: Obteniendo estadísticas de $horarioId');
    _validateUser();

    try {
      final horarioSnapshot = await _horariosCollection.doc(horarioId).get();

      if (!horarioSnapshot.exists) {
        throw Exception('Horario no encontrado para estadísticas: $horarioId');
      }

      final horario = HorarioCompleto.fromJson(
        horarioSnapshot.data() as Map<String, dynamic>,
      );

      final totalSlots = horario.slots.length;
      final slotsOcupados = horario.slots
          .where((s) => s.materiaId != null)
          .length;
      final totalMaterias = horario.materias.length;

      final estadisticas = {
        'totalSlots': totalSlots,
        'slotsOcupados': slotsOcupados,
        'slotsVacios': totalSlots - slotsOcupados,
        'totalMaterias': totalMaterias,
        'porcentajeCompletado': totalSlots > 0
            ? (slotsOcupados / totalSlots * 100).round()
            : 0,
      };

      print('📊 Estadísticas calculadas: $estadisticas');
      return estadisticas;
    } catch (e, stackTrace) {
      print('❌ Error al obtener estadísticas: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }
}
