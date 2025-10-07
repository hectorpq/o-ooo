// lib/widgets/dialogo_crear_horario.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/horario.dart';
import '../providers/theme_provider.dart';
import '../providers/horario_provider.dart';

class DialogoCrearHorario extends StatefulWidget {
  const DialogoCrearHorario({super.key});

  @override
  State<DialogoCrearHorario> createState() => _DialogoCrearHorarioState();
}

class _DialogoCrearHorarioState extends State<DialogoCrearHorario> {
  final TextEditingController _nombreController = TextEditingController();
  TipoHorario _tipoSeleccionado = TipoHorario.escolar;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _crearHorario() async {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un nombre para el horario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final horarioProvider = context.read<HorarioProvider>();
    final success = await horarioProvider.crearHorario(
      tipoHorario: _tipoSeleccionado,
      nombre: _nombreController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horario creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${horarioProvider.error ?? 'Error desconocido'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AlertDialog(
          backgroundColor: themeProvider
              .dialogBackgroundColor, // ✅ CAMBIADO: Usa el color del tema
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Crear Nuevo Horario',
                style: TextStyle(
                  color: themeProvider.dialogTextColor, // ✅ CAMBIADO
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre del horario:',
                  style: TextStyle(
                    color: themeProvider.dialogTextColor, // ✅ CAMBIADO
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nombreController,
                  style: TextStyle(
                    color: themeProvider.dialogTextColor,
                  ), // ✅ CAMBIADO
                  decoration: InputDecoration(
                    hintText: 'Ej: Semestre 2024-1',
                    hintStyle: TextStyle(
                      color: themeProvider.dialogSecondaryTextColor,
                    ), // ✅ CAMBIADO
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: themeProvider.dialogBorderColor,
                      ), // ✅ CAMBIADO
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: themeProvider.dialogBorderColor,
                      ), // ✅ CAMBIADO
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode
                            ? const Color(0xFF6C757D)
                            : Colors.purpleAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tipo de horario:',
                  style: TextStyle(
                    color: themeProvider.dialogTextColor, // ✅ CAMBIADO
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...TipoHorario.values.map((tipo) {
                  final isSelected = _tipoSeleccionado == tipo;
                  String nombre = tipo.toString().split('.').last;
                  nombre = nombre[0].toUpperCase() + nombre.substring(1);

                  String descripcion = '';
                  switch (tipo) {
                    case TipoHorario.escolar:
                      descripcion = '7 períodos • 8:00 - 12:45';
                      break;
                    case TipoHorario.colegio:
                      descripcion = '8 períodos • 7:30 - 13:40';
                      break;
                    case TipoHorario.universidad:
                      descripcion = '7 bloques • 7:00 - 18:40';
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _tipoSeleccionado = tipo;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (themeProvider.isDarkMode
                                    ? const Color(0xFF6C757D).withOpacity(0.2)
                                    : Colors.purpleAccent.withOpacity(0.2))
                              : (themeProvider.isDarkMode
                                    ? const Color(0xFF2C2C2C)
                                    : Colors.grey.shade50),
                          border: Border.all(
                            color: isSelected
                                ? (themeProvider.isDarkMode
                                      ? const Color(0xFF6C757D)
                                      : Colors.purpleAccent)
                                : themeProvider.dialogBorderColor,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Radio<TipoHorario>(
                              value: tipo,
                              groupValue: _tipoSeleccionado,
                              onChanged: (value) {
                                setState(() {
                                  _tipoSeleccionado = value!;
                                });
                              },
                              activeColor: themeProvider.isDarkMode
                                  ? const Color(0xFF6C757D)
                                  : Colors.purpleAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider
                                          .dialogTextColor, // ✅ CAMBIADO
                                    ),
                                  ),
                                  Text(
                                    descripcion,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: themeProvider
                                          .dialogSecondaryTextColor, // ✅ CAMBIADO
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: themeProvider.dialogSecondaryTextColor,
                ), // ✅ CAMBIADO
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _crearHorario,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.isDarkMode
                    ? const Color(0xFF6C757D)
                    : Colors.purpleAccent,
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
                  : const Text(
                      'Crear',
                      style: TextStyle(
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
}
