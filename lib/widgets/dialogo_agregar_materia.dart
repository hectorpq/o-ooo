// lib/widgets/dialogo_agregar_materia.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/horario_provider.dart';

class DialogoAgregarMateria extends StatefulWidget {
  final String dia;
  final String hora;

  const DialogoAgregarMateria({
    super.key,
    required this.dia,
    required this.hora,
  });

  @override
  State<DialogoAgregarMateria> createState() => _DialogoAgregarMateriaState();
}

class _DialogoAgregarMateriaState extends State<DialogoAgregarMateria> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _profesorController = TextEditingController();
  final TextEditingController _aulaController = TextEditingController();

  Color _colorSeleccionado = Colors.blue;
  bool _isLoading = false;

  final List<Color> _coloresDisponibles = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.lime,
    Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    // Si ya existe una materia en este slot, cargar sus datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final horarioProvider = context.read<HorarioProvider>();
      final materiaExistente = horarioProvider.obtenerMateria(
        widget.dia,
        widget.hora,
      );

      if (materiaExistente != null) {
        _nombreController.text = materiaExistente.nombre;
        _profesorController.text = materiaExistente.profesor == 'Sin profesor'
            ? ''
            : materiaExistente.profesor;
        _aulaController.text = materiaExistente.aula == 'Sin aula'
            ? ''
            : materiaExistente.aula;

        // Obtener el color de la materia existente
        try {
          final colorValue = int.parse(
            materiaExistente.colorHex.replaceFirst('#', ''),
            radix: 16,
          );
          if (mounted) {
            setState(() {
              _colorSeleccionado = Color(colorValue);
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _colorSeleccionado = Colors.blue;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _profesorController.dispose();
    _aulaController.dispose();
    super.dispose();
  }

  Future<void> _guardarMateria() async {
    if (_nombreController.text.trim().isEmpty) {
      _mostrarError('Por favor ingresa el nombre de la materia');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final horarioProvider = context.read<HorarioProvider>();

    // Primero remover la materia existente si existe
    await horarioProvider.removerMateria(dia: widget.dia, hora: widget.hora);

    // Luego agregar la nueva materia
    final success = await horarioProvider.agregarMateria(
      nombre: _nombreController.text.trim(),
      profesor: _profesorController.text.trim().isEmpty
          ? 'Sin profesor'
          : _profesorController.text.trim(),
      aula: _aulaController.text.trim().isEmpty
          ? 'Sin aula'
          : _aulaController.text.trim(),
      color: _colorSeleccionado,
      dia: widget.dia,
      hora: widget.hora,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Materia guardada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        _mostrarError(horarioProvider.error ?? 'Error desconocido');
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Verificar si ya existe una materia
        final horarioProvider = context.watch<HorarioProvider>();
        final materiaExistente = horarioProvider.obtenerMateria(
          widget.dia,
          widget.hora,
        );
        final esEdicion = materiaExistente != null;

        return AlertDialog(
          backgroundColor: themeProvider.isDarkMode
              ? const Color(0xFF2C3E50)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: themeProvider.isDarkMode
                  ? const Color(0xFF34495E)
                  : Colors.grey.shade200,
              width: 2,
            ),
          ),
          elevation: 24,
          shadowColor: Colors.black.withOpacity(0.3),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeProvider.isDarkMode
                        ? [const Color(0xFF6C757D), const Color(0xFF495057)]
                        : [Colors.purpleAccent, Colors.pinkAccent],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  esEdicion ? Icons.edit_rounded : Icons.school_rounded,
                  color: themeProvider.primaryTextColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esEdicion ? 'Editar Materia' : 'Agregar Materia',
                      style: TextStyle(
                        color: themeProvider.primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${widget.dia} • ${widget.hora}',
                      style: TextStyle(
                        color: themeProvider.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // SOLUCIÓN 1: Contenedor con tamaño fijo
          content: SizedBox(
            width: 400, // Ancho fijo
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 500, // Alto máximo
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre de la materia
                    _buildTextField(
                      label: 'Nombre de la materia:',
                      controller: _nombreController,
                      hint: 'Ej: Matemáticas',
                      required: true,
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 16),

                    // Profesor
                    _buildTextField(
                      label: 'Profesor (opcional):',
                      controller: _profesorController,
                      hint: 'Ej: Dr. García',
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 16),

                    // Aula
                    _buildTextField(
                      label: 'Aula (opcional):',
                      controller: _aulaController,
                      hint: 'Ej: Aula 101',
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 20),

                    // Selector de color
                    _buildColorSelector(themeProvider),
                    const SizedBox(height: 16),

                    // Vista previa
                    _buildPreview(themeProvider),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            // Botón eliminar (solo si es edición)
            if (esEdicion)
              TextButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final confirm = await _mostrarConfirmacionEliminar();
                        if (confirm == true && mounted) {
                          final success = await horarioProvider.removerMateria(
                            dia: widget.dia,
                            hora: widget.hora,
                          );

                          if (success && mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Materia eliminada'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Eliminar'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),

            // Botón cancelar
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: themeProvider.secondaryTextColor),
              ),
            ),

            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _guardarMateria,
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorSeleccionado,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      esEdicion ? 'Actualizar' : 'Agregar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required ThemeProvider themeProvider,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : const Color(0xFF2C3E50),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: themeProvider.isDarkMode
                ? const Color(0xFF34495E).withOpacity(0.3)
                : Colors.grey.shade50,
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? const Color(0xFF4A90E2)
                  : Colors.blue.shade300,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : const Color(0xFF2C3E50),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {}); // Para actualizar la vista previa
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Seleccionar color:',
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : const Color(0xFF2C3E50),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? const Color(0xFF34495E).withOpacity(0.2)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? const Color(0xFF4A90E2)
                  : Colors.blue.shade200,
              width: 1.5,
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: _coloresDisponibles.length,
            itemBuilder: (context, index) {
              final color = _coloresDisponibles[index];
              final isSelected = _colorSeleccionado == color;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _colorSeleccionado = color;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (themeProvider.isDarkMode
                                ? Colors.white
                                : const Color(0xFF2C3E50))
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: isSelected ? 12 : 6,
                        spreadRadius: isSelected ? 3 : 1,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 22,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 4),
                          ],
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _colorSeleccionado.withOpacity(0.1),
            _colorSeleccionado.withOpacity(0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _colorSeleccionado, width: 2),
        boxShadow: [
          BoxShadow(
            color: _colorSeleccionado.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _colorSeleccionado,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Vista previa:',
                style: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.white
                      : const Color(0xFF2C3E50),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? const Color(0xFF2C3E50).withOpacity(0.8)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _colorSeleccionado.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nombreController.text.isEmpty
                      ? 'Nombre de la materia'
                      : _nombreController.text,
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : const Color(0xFF2C3E50),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_profesorController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _colorSeleccionado.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: _colorSeleccionado,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _profesorController.text,
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_aulaController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _colorSeleccionado.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.room_rounded,
                          size: 14,
                          color: _colorSeleccionado,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _colorSeleccionado,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _aulaController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _mostrarConfirmacionEliminar() {
    return showDialog<bool>(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor: themeProvider.cardBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Eliminar materia',
                  style: TextStyle(
                    color: themeProvider.primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width:
                  300, // SOLUCIÓN 2: También fijar el ancho del diálogo de confirmación
              child: Text(
                '¿Estás seguro de que quieres eliminar "${_nombreController.text}"?\n\nEsta acción no se puede deshacer.',
                style: TextStyle(color: themeProvider.secondaryTextColor),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: themeProvider.secondaryTextColor),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
