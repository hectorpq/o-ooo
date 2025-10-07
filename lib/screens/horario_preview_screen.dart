// TODO Implement this library.
// lib/screens/horario_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/horario.dart';
import '../providers/horario_provider.dart';
import '../services/share_service.dart';

class HorarioPreviewScreen extends StatefulWidget {
  final String shareId;

  const HorarioPreviewScreen({Key? key, required this.shareId})
    : super(key: key);

  @override
  State<HorarioPreviewScreen> createState() => _HorarioPreviewScreenState();
}

class _HorarioPreviewScreenState extends State<HorarioPreviewScreen> {
  HorarioCompleto? _horarioPreview;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _nombreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarVistaPrevia();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _cargarVistaPrevia() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final horarioProvider = Provider.of<HorarioProvider>(
        context,
        listen: false,
      );

      final horario = await horarioProvider.obtenerVistaPrevia(widget.shareId);

      if (horario != null) {
        setState(() {
          _horarioPreview = horario;
          _nombreController.text = horario.nombre;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No se pudo cargar el horario';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa del horario')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildPreview(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 24),
            Text(
              _error!,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_horarioPreview == null) return const SizedBox();

    final horario = _horarioPreview!;
    final slotsOcupados = horario.slots
        .where((s) => s.materiaId != null)
        .length;

    return Column(
      children: [
        // Información del horario
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.calendar_today, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                horario.nombre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _nombreTipoHorario(horario.tipoHorario),
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),

        // Estadísticas
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.book,
                label: 'Materias',
                value: horario.materias.length.toString(),
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.access_time,
                label: 'Clases',
                value: slotsOcupados.toString(),
                color: Colors.green,
              ),
            ],
          ),
        ),

        // Lista de materias
        Expanded(
          child: horario.materias.isEmpty
              ? const Center(child: Text('Este horario no tiene materias'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: horario.materias.length,
                  itemBuilder: (context, index) {
                    final materia = horario.materias.values.elementAt(index);
                    return _buildMateriaCard(materia);
                  },
                ),
        ),

        // Botones de acción
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo de nombre personalizado
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del horario',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit),
                  ),
                ),
                const SizedBox(height: 16),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _mostrarOpcionesImportar(
                          OpcionImportar.sobrescribir,
                        ),
                        child: const Text('Sobrescribir'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _mostrarOpcionesImportar(OpcionImportar.crearNuevo),
                        child: const Text('Crear nuevo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriaCard(Materia materia) {
    Color color;
    try {
      final colorValue = int.parse(
        materia.colorHex.replaceFirst('#', ''),
        radix: 16,
      );
      color = Color(colorValue);
    } catch (e) {
      color = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(Icons.book, color: color),
        ),
        title: Text(
          materia.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (materia.profesor.isNotEmpty) Text('👨‍🏫 ${materia.profesor}'),
            if (materia.aula.isNotEmpty) Text('📍 ${materia.aula}'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _mostrarOpcionesImportar(OpcionImportar opcion) async {
    final horarioProvider = Provider.of<HorarioProvider>(
      context,
      listen: false,
    );

    String mensaje;
    String titulo;

    if (opcion == OpcionImportar.sobrescribir) {
      if (!horarioProvider.tieneHorarioActivo) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes un horario activo para sobrescribir'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      titulo = 'Sobrescribir horario';
      mensaje =
          '¿Estás seguro de sobrescribir tu horario actual?\n\nSe perderán todos los datos del horario "${horarioProvider.horarioActivo!.nombre}".';
    } else {
      titulo = 'Crear nuevo horario';
      mensaje = '¿Deseas importar este horario como uno nuevo?';
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _importarHorario(opcion);
    }
  }

  Future<void> _importarHorario(OpcionImportar opcion) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final horarioProvider = Provider.of<HorarioProvider>(
        context,
        listen: false,
      );

      final exito = await horarioProvider.importarHorario(
        shareId: widget.shareId,
        opcion: opcion,
        nombrePersonalizado: _nombreController.text.trim().isNotEmpty
            ? _nombreController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga

        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Horario importado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Volver a la pantalla anterior (home o donde sea)
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(horarioProvider.error ?? 'Error al importar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _nombreTipoHorario(TipoHorario tipo) {
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
