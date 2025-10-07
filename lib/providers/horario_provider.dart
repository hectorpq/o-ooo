// lib/providers/horario_provider.dart - OPTIMIZADO
import 'package:flutter/material.dart';
import '../models/horario.dart';
import '../services/horario_service.dart';
import '../services/widget_service.dart';
import '../services/share_service.dart';

class HorarioProvider extends ChangeNotifier {
  HorarioCompleto? _horarioActivo;
  List<HorarioCompleto> _todosLosHorarios = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  HorarioCompleto? get horarioActivo => _horarioActivo;
  List<HorarioCompleto> get todosLosHorarios => _todosLosHorarios;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get tieneHorarioActivo => _horarioActivo != null;

  /// Inicializar el provider cargando el horario activo
  Future<void> inicializar() async {
    print('🕐 HorarioProvider: Iniciando inicialización...');
    _setLoading(true);

    try {
      print('🕐 HorarioProvider: Cargando horario activo...');
      await cargarHorarioActivo();

      print('🕐 HorarioProvider: Cargando todos los horarios...');
      await cargarTodosLosHorarios();

      _clearError();
      print('✅ HorarioProvider: Inicialización completada exitosamente');

      if (_horarioActivo != null) {
        print(
          '📋 Horario activo encontrado: ${_horarioActivo!.nombre} (${_horarioActivo!.tipoHorario})',
        );
      } else {
        print('📋 No se encontró horario activo');
      }
    } catch (e, stackTrace) {
      print('❌ HorarioProvider: Error en inicialización: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al inicializar horarios: $e');
    } finally {
      _setLoading(false);
      print('🔄 HorarioProvider: Finalizando inicialización');
    }
  }

  /// Cargar el horario activo
  Future<void> cargarHorarioActivo() async {
    try {
      print('🔍 Buscando horario activo...');
      _horarioActivo = await HorarioService.obtenerHorarioActivo();

      if (_horarioActivo != null) {
        print('✅ Horario activo cargado: ${_horarioActivo!.id}');
      } else {
        print('ℹ️ No se encontró horario activo');
      }

      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ Error al cargar horario activo: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al cargar horario activo: $e');
      rethrow;
    }
  }

  /// Cargar todos los horarios del usuario
  Future<void> cargarTodosLosHorarios() async {
    try {
      print('🔍 Cargando todos los horarios...');
      _todosLosHorarios = await HorarioService.obtenerTodosLosHorarios();
      print('✅ Horarios cargados: ${_todosLosHorarios.length}');
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ Error al cargar horarios: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al cargar horarios: $e');
    }
  }

  /// Crear un nuevo horario
  Future<bool> crearHorario({
    required TipoHorario tipoHorario,
    required String nombre,
  }) async {
    print('🆕 Creando horario: $nombre ($tipoHorario)');
    _setLoading(true);

    try {
      final horarioId = await HorarioService.crearHorario(
        tipoHorario: tipoHorario,
        nombre: nombre,
      );

      print('✅ Horario creado con ID: $horarioId');

      await cargarHorarioActivo();
      _clearError();
      return true;
    } catch (e, stackTrace) {
      print('❌ Error al crear horario: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al crear horario: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Agregar materia al horario activo
  Future<bool> agregarMateria({
    required String nombre,
    required String profesor,
    required String aula,
    required Color color,
    required String dia,
    required String hora,
  }) async {
    if (_horarioActivo == null) {
      print('❌ No hay horario activo para agregar materia');
      _setError('No hay horario activo');
      return false;
    }

    print('📚 Agregando materia: $nombre ($dia $hora)');

    try {
      final materia = Materia(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: nombre,
        profesor: profesor,
        aula: aula,
        colorHex: '#${color.value.toRadixString(16).padLeft(8, '0')}',
        fechaCreacion: DateTime.now(),
      );

      await HorarioService.agregarMateria(
        horarioId: _horarioActivo!.id,
        materia: materia,
        dia: dia,
        hora: hora,
      );

      print('✅ Materia agregada exitosamente');
      await cargarHorarioActivo();
      await WidgetService.updateWidget(horarioProvider: this);

      _clearError();
      return true;
    } catch (e, stackTrace) {
      print('❌ Error al agregar materia: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al agregar materia: $e');
      return false;
    }
  }

  /// Remover materia del horario
  Future<bool> removerMateria({
    required String dia,
    required String hora,
  }) async {
    if (_horarioActivo == null) {
      print('❌ No hay horario activo para remover materia');
      _setError('No hay horario activo');
      return false;
    }

    print('🗑️ Removiendo materia: $dia $hora');

    try {
      await HorarioService.removerMateria(
        horarioId: _horarioActivo!.id,
        dia: dia,
        hora: hora,
      );

      print('✅ Materia removida exitosamente');
      await cargarHorarioActivo();
      await WidgetService.updateWidget(horarioProvider: this);

      _clearError();
      return true;
    } catch (e, stackTrace) {
      print('❌ Error al remover materia: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al remover materia: $e');
      return false;
    }
  }

  /// Cambiar tipo de horario
  Future<bool> cambiarTipoHorario(TipoHorario nuevoTipo) async {
    if (_horarioActivo == null) {
      _setError('No hay horario activo');
      return false;
    }

    print('🔄 Cambiando tipo de horario a: $nuevoTipo');
    _setLoading(true);

    try {
      await HorarioService.cambiarTipoHorario(
        horarioId: _horarioActivo!.id,
        nuevoTipo: nuevoTipo,
      );

      await cargarHorarioActivo();
      await WidgetService.updateWidget(horarioProvider: this);

      _clearError();
      print('✅ Tipo de horario cambiado exitosamente');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error al cambiar tipo de horario: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al cambiar tipo de horario: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Limpiar todo el horario
  Future<bool> limpiarHorario() async {
    if (_horarioActivo == null) {
      _setError('No hay horario activo');
      return false;
    }

    print('🧹 Limpiando horario: ${_horarioActivo!.id}');

    try {
      await HorarioService.limpiarHorario(_horarioActivo!.id);
      await cargarHorarioActivo();
      _clearError();
      print('✅ Horario limpiado exitosamente');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error al limpiar horario: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al limpiar horario: $e');
      return false;
    }
  }

  /// Activar un horario específico (OPTIMIZADO)
  Future<bool> activarHorario(String horarioId) async {
    print('🔄 INICIO - Activando horario: $horarioId');
    _setLoading(true);

    try {
      print('📡 Llamando a Firebase para activar...');
      await HorarioService.activarHorario(horarioId);

      print('📡 Recargando horario activo...');
      await cargarHorarioActivo();

      // OPTIMIZACIÓN: Solo actualizar la lista si es necesario
      // No recargamos todos los horarios porque solo cambió el flag "activo"

      _clearError();
      print('✅ Horario activado exitosamente');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error al activar horario: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al activar horario: $e');
      return false;
    } finally {
      print('🏁 FIN - Proceso completado');
      _setLoading(false);
    }
  }

  /// Eliminar un horario
  Future<bool> eliminarHorario(String horarioId) async {
    print('🗑️ Eliminando horario: $horarioId');

    try {
      await HorarioService.eliminarHorario(horarioId);

      if (_horarioActivo?.id == horarioId) {
        _horarioActivo = null;
        print('🔄 Horario activo limpiado porque fue eliminado');
      }

      await cargarTodosLosHorarios();
      _clearError();
      print('✅ Horario eliminado exitosamente');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error al eliminar horario: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al eliminar horario: $e');
      return false;
    }
  }

  /// Duplicar un horario (OPTIMIZADO)
  Future<bool> duplicarHorario({
    required String horarioId,
    required String nuevoNombre,
  }) async {
    print('📋 Duplicando horario: $horarioId -> $nuevoNombre');
    _setLoading(true);

    try {
      await HorarioService.duplicarHorario(
        horarioId: horarioId,
        nuevoNombre: nuevoNombre,
      );

      // Solo recargar el activo ya que se activa automáticamente
      await cargarHorarioActivo();
      _clearError();
      print('✅ Horario duplicado exitosamente');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error al duplicar horario: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al duplicar horario: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== FUNCIONES DE COMPARTIR ====================

  /// Compartir horario por link (retorna shareId)
  Future<String?> compartirHorarioPorLink() async {
    if (_horarioActivo == null) {
      _setError('No hay horario activo para compartir');
      return null;
    }

    print('📤 Compartiendo horario por link: ${_horarioActivo!.nombre}');
    _setLoading(true);

    try {
      await ShareService.compartirHorarioPorLink(_horarioActivo!);
      _clearError();
      print('✅ Horario compartido por link');

      final shareId = await ShareService.compartirHorario(_horarioActivo!);
      return shareId;
    } catch (e, stackTrace) {
      print('❌ Error al compartir horario: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al compartir horario: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Generar QR del horario activo (retorna string JSON para QR)
  Future<String?> generarQRHorario() async {
    if (_horarioActivo == null) {
      _setError('No hay horario activo para compartir');
      return null;
    }

    print('📤 Generando QR del horario: ${_horarioActivo!.nombre}');
    _setLoading(true);

    try {
      final shareId = await ShareService.compartirHorario(_horarioActivo!);
      final qrData = ShareService.generarQRHorario(shareId);

      _clearError();
      print('✅ QR generado para horario: $shareId');
      return qrData;
    } catch (e, stackTrace) {
      print('❌ Error al generar QR: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al generar QR: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Procesar QR escaneado
  Future<Map<String, dynamic>?> procesarQREscaneado(String qrData) async {
    print('📥 Procesando QR escaneado...');

    try {
      final datos = ShareService.procesarQRData(qrData);

      if (datos == null) {
        _setError('QR no válido o no pertenece a Agenda AI');
        return null;
      }

      print('✅ QR procesado: ${datos['tipo']} - ${datos['shareId']}');
      return datos;
    } catch (e, stackTrace) {
      print('❌ Error al procesar QR: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al procesar QR: $e');
      return null;
    }
  }

  /// Importar horario desde shareId con opciones
  Future<bool> importarHorario({
    required String shareId,
    required OpcionImportar opcion,
    String? nombrePersonalizado,
  }) async {
    print('📥 Importando horario con opción: $opcion');
    _setLoading(true);

    try {
      String? horarioIdASobrescribir;

      if (opcion == OpcionImportar.sobrescribir && _horarioActivo != null) {
        horarioIdASobrescribir = _horarioActivo!.id;
      }

      final horarioId = await ShareService.importarHorario(
        shareId: shareId,
        opcion: opcion,
        nombrePersonalizado: nombrePersonalizado,
        horarioIdASobrescribir: horarioIdASobrescribir,
      );

      print('✅ Horario importado: $horarioId');

      await cargarHorarioActivo();
      _clearError();
      return true;
    } catch (e, stackTrace) {
      print('❌ Error al importar horario: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al importar horario: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Obtener vista previa del horario compartido
  Future<HorarioCompleto?> obtenerVistaPrevia(String shareId) async {
    print('👁️ Obteniendo vista previa del horario: $shareId');
    _setLoading(true);

    try {
      final horario = await ShareService.obtenerHorarioCompartido(shareId);

      if (horario == null) {
        _setError('No se pudo cargar el horario compartido');
        return null;
      }

      print('✅ Vista previa obtenida: ${horario.nombre}');
      _clearError();
      return horario;
    } catch (e, stackTrace) {
      print('❌ Error al obtener vista previa: $e');
      print('📍 Stack trace: $stackTrace');
      _setError('Error al obtener vista previa: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== MÉTODOS AUXILIARES ====================

  /// Obtener materia para un slot específico
  Materia? obtenerMateria(String dia, String hora) {
    if (_horarioActivo == null) return null;

    try {
      final slot = _horarioActivo!.slots.firstWhere(
        (s) => s.dia == dia && s.hora == hora,
        orElse: () => SlotHorario(dia: dia, hora: hora),
      );

      if (slot.materiaId == null) return null;

      final materia = _horarioActivo!.materias[slot.materiaId];
      return materia;
    } catch (e) {
      print('❌ Error al obtener materia ($dia $hora): $e');
      return null;
    }
  }

  /// Obtener color de una materia como Color
  Color obtenerColorMateria(String dia, String hora) {
    final materia = obtenerMateria(dia, hora);
    if (materia == null) return Colors.transparent;

    try {
      final colorValue = int.parse(
        materia.colorHex.replaceFirst('#', ''),
        radix: 16,
      );
      return Color(colorValue);
    } catch (e) {
      print('⚠️ Error al parsear color ${materia.colorHex}: $e');
      return Colors.blue;
    }
  }

  /// Verificar si un slot tiene materia
  bool tieneMateria(String dia, String hora) {
    return obtenerMateria(dia, hora) != null;
  }

  /// Obtener estadísticas del horario activo
  Map<String, dynamic> obtenerEstadisticas() {
    if (_horarioActivo == null) {
      return {
        'totalSlots': 0,
        'slotsOcupados': 0,
        'slotsVacios': 0,
        'totalMaterias': 0,
        'porcentajeCompletado': 0,
      };
    }

    try {
      final totalSlots = _horarioActivo!.slots.length;
      final slotsOcupados = _horarioActivo!.slots
          .where((s) => s.materiaId != null)
          .length;
      final totalMaterias = _horarioActivo!.materias.length;

      return {
        'totalSlots': totalSlots,
        'slotsOcupados': slotsOcupados,
        'slotsVacios': totalSlots - slotsOcupados,
        'totalMaterias': totalMaterias,
        'porcentajeCompletado': totalSlots > 0
            ? (slotsOcupados / totalSlots * 100).round()
            : 0,
      };
    } catch (e) {
      print('❌ Error al calcular estadísticas: $e');
      return {
        'totalSlots': 0,
        'slotsOcupados': 0,
        'slotsVacios': 0,
        'totalMaterias': 0,
        'porcentajeCompletado': 0,
      };
    }
  }

  /// Stream para escuchar cambios en tiempo real
  Stream<HorarioCompleto?> get streamHorarioActivo {
    try {
      return HorarioService.streamHorarioActivo();
    } catch (e) {
      print('❌ Error al crear stream de horario: $e');
      return Stream.value(null);
    }
  }

  // Métodos privados para manejo de estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    print('🚨 HorarioProvider Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
