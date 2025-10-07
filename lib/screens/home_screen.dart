// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../models/evento.dart';
import '../models/horario.dart';
import '../providers/theme_provider.dart';
import '../providers/horario_provider.dart';
import '../widgets/dialogo_crear_horario.dart';
import '../widgets/dialogo_agregar_materia.dart';
import '../services/widget_service.dart';
import 'qr_display_screen.dart';
import 'qr_scanner_screen.dart';
import '../services/share_service.dart';

typedef VoidCallbackInt = void Function(int index);

class HomeScreen extends StatefulWidget {
  final List<Evento> eventos;
  final VoidCallback? onGoToEvents;

  const HomeScreen({super.key, required this.eventos, this.onGoToEvents});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _userName;
  late AnimationController _animController;
  late AnimationController _pulseController;
  late AnimationController _slideController;

  Map<TipoHorario, List<String>> horariosDisponibles = {
    TipoHorario.escolar: [
      '7:40 - 8:25',
      '8:25 - 9:10',
      '9:10 - 9:30',
      '9:30 - 10:15',
      '10:15 - 11:05',
      '11:05 - 11:20',
      '11:20 - 12:05',
      '12:05 - 12:45',
      '12:45 - 13:00',
      '13:00 - 13:45',
      '13:45 - 14:30',
    ],
    TipoHorario.colegio: [
      '7:40 - 8:25',
      '8:25 - 9:10',
      '9:10 - 9:30',
      '9:30 - 10:15',
      '10:15 - 11:05',
      '11:05 - 11:20',
      '11:20 - 12:05',
      '12:05 - 12:45',
      '12:45 - 13:00',
      '13:00 - 13:45',
      '13:45 - 14:30',
    ],
    TipoHorario.universidad: [
      '7:30 - 8:20 (M1)',
      '8:25 - 9:15 (M2)',
      '9:20 - 10:10 (M3)',
      '10:15 - 11:05 (M4)',
      '11:15 - 12:05 (M5)',
      '12:10 - 13:00 (M6)',
      '13:10 - 14:00 (T1)',
      '14:05 - 14:55 (T2)',
      '15:00 - 15:50 (T3)',
      '16:00 - 16:50 (T4)',
      '16:55 - 17:45 (T5)',
      '17:50 - 18:40 (T6)',
      '18:45 - 19:35 (N1)',
      '19:40 - 20:30 (N2)',
      '20:35 - 21:25 (N3)',
      '21:30 - 22:20 (N4)',
    ],
  };

  List<String> diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getUserName();
    _initializeProvider();
  }

  void _initializeAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  void _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _userName = user.displayName;
      } else if (user.email != null && user.email!.isNotEmpty) {
        _userName = user.email!.split('@').first;
      } else {
        _userName = 'Usuario';
      }
    } else {
      _userName = 'Usuario';
    }
  }

  void _initializeProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HorarioProvider>().inicializar();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _actualizarWidget() async {
    try {
      final horarioProvider = context.read<HorarioProvider>();
      await WidgetService.updateWidget(
        horarioProvider: horarioProvider,
        eventos: widget.eventos,
      );
    } catch (e) {
      debugPrint('Error actualizando widget: $e');
    }
  }

  // Diálogo de carga adaptativo al tema - FONDOS SÓLIDOS
  void _mostrarDialogoCarga(String mensaje) {
    final themeProvider = context.read<ThemeProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: themeProvider.isDarkMode
          ? Colors
                .black // Negro sólido 100% para modo oscuro
          : Colors.white, // Blanco sólido 100% para modo claro
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? const Color(0xFF1a1a1a) // Negro oscuro para el card
                  : Colors.white, // Blanco para el card
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode
                      ? Colors.black.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  mensaje,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoCrearHorario() {
    showDialog(
      context: context,
      builder: (context) => const DialogoCrearHorario(),
    ).then((_) => _actualizarWidget());
  }

  void _mostrarDialogoAgregarMateria(String dia, String hora) {
    showDialog(
      context: context,
      builder: (context) => DialogoAgregarMateria(dia: dia, hora: hora),
    ).then((_) => _actualizarWidget());
  }

  void _confirmarLimpiarHorario(HorarioProvider horarioProvider) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor: themeProvider.cardBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              '¿Limpiar horario?',
              style: TextStyle(
                color: themeProvider.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Esto eliminará todas las materias del horario actual.',
              style: TextStyle(color: themeProvider.secondaryTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: themeProvider.secondaryTextColor),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await horarioProvider.limpiarHorario();
                  if (success) {
                    _actualizarWidget();
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${horarioProvider.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Limpiar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarOpcionesCompartir(HorarioProvider horarioProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Compartir horario',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.link, color: Colors.blue),
              ),
              title: const Text('Compartir por link'),
              subtitle: const Text('Envía un enlace a través de apps'),
              onTap: () async {
                Navigator.pop(context);
                await _compartirPorLink(horarioProvider);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code, color: Colors.green),
              ),
              title: const Text('Generar código QR'),
              subtitle: const Text('Muestra un QR para escanear'),
              onTap: () async {
                Navigator.pop(context);
                await _mostrarQR(horarioProvider);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _compartirPorLink(HorarioProvider horarioProvider) async {
    _mostrarDialogoCarga('Compartiendo horario...');

    try {
      await horarioProvider.compartirHorarioPorLink();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horario compartido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _mostrarQR(HorarioProvider horarioProvider) async {
    _mostrarDialogoCarga('Generando código QR...');

    try {
      final qrData = await horarioProvider.generarQRHorario();
      final linkId = await ShareService.compartirHorario(
        horarioProvider.horarioActivo!,
      );
      final link = ShareService.generarLinkHorario(linkId);

      if (mounted) {
        Navigator.pop(context);
        if (qrData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRDisplayScreen(
                qrData: qrData,
                titulo: horarioProvider.horarioActivo!.nombre,
                subtitulo: 'Escanea este código para importar el horario',
                link: link,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _abrirEscanerQR() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
  }

  void _mostrarSelectorHorarios(HorarioProvider horarioProvider) async {
    await horarioProvider.cargarTodosLosHorarios();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: themeProvider
                  .dialogBackgroundColor, // ✅ CAMBIADO: Ahora usa dialogBackgroundColor
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: themeProvider.dialogSecondaryTextColor.withOpacity(
                      0.3,
                    ), // ✅ CAMBIADO
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: themeProvider.isDarkMode
                            ? const Color(0xFF6C757D)
                            : Colors.deepPurple,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mis horarios',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: themeProvider
                                .dialogTextColor, // ✅ CAMBIADO: Usa dialogTextColor
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: themeProvider.isDarkMode
                                ? [
                                    const Color(0xFF6C757D),
                                    const Color(0xFF495057),
                                  ]
                                : [Colors.purpleAccent, Colors.pinkAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                            _mostrarDialogoCrearHorario();
                          },
                          tooltip: 'Crear nuevo horario',
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: horarioProvider.todosLosHorarios.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_outlined,
                                  size: 64,
                                  color: themeProvider
                                      .dialogSecondaryTextColor, // ✅ CAMBIADO
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tienes horarios creados',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: themeProvider
                                        .dialogTextColor, // ✅ CAMBIADO
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Toca el botón + para crear uno',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themeProvider
                                        .dialogSecondaryTextColor, // ✅ CAMBIADO
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shrinkWrap: true,
                          itemCount: horarioProvider.todosLosHorarios.length,
                          itemBuilder: (context, index) {
                            final horario =
                                horarioProvider.todosLosHorarios[index];
                            final isActive =
                                horarioProvider.horarioActivo?.id == horario.id;

                            final totalSlots = horario.slots.length;
                            final slotsOcupados = horario.slots
                                .where((s) => s.materiaId != null)
                                .length;
                            final porcentaje = totalSlots > 0
                                ? (slotsOcupados / totalSlots * 100).round()
                                : 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? LinearGradient(
                                        colors: themeProvider.isDarkMode
                                            ? [
                                                const Color(
                                                  0xFF6C757D,
                                                ).withOpacity(0.2),
                                                const Color(
                                                  0xFF495057,
                                                ).withOpacity(0.1),
                                              ]
                                            : [
                                                Colors.deepPurple.withOpacity(
                                                  0.1,
                                                ),
                                                Colors.purpleAccent.withOpacity(
                                                  0.05,
                                                ),
                                              ],
                                      )
                                    : null,
                                color: isActive
                                    ? null
                                    : (themeProvider.isDarkMode
                                          ? const Color(0xFF2C2C2C)
                                          : Colors
                                                .grey
                                                .shade50), // ✅ CAMBIADO: Fondo para cards inactivos
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive
                                      ? (themeProvider.isDarkMode
                                            ? const Color(0xFF6C757D)
                                            : Colors.deepPurple)
                                      : themeProvider
                                            .dialogBorderColor, // ✅ CAMBIADO
                                  width: isActive ? 2 : 1,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color:
                                              (themeProvider.isDarkMode
                                                      ? const Color(0xFF6C757D)
                                                      : Colors.deepPurple)
                                                  .withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: isActive
                                      ? null
                                      : () async {
                                          Navigator.pop(context);
                                          _mostrarDialogoCarga(
                                            'Cambiando horario...',
                                          );

                                          final success = await horarioProvider
                                              .activarHorario(horario.id);

                                          if (mounted) {
                                            Navigator.pop(context);
                                            _actualizarWidget();

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? 'Horario "${horario.nombre}" activado'
                                                      : 'Error al activar horario',
                                                ),
                                                backgroundColor: success
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors:
                                                      themeProvider.isDarkMode
                                                      ? [
                                                          const Color(
                                                            0xFF6C757D,
                                                          ),
                                                          const Color(
                                                            0xFF495057,
                                                          ),
                                                        ]
                                                      : [
                                                          Colors.purpleAccent,
                                                          Colors.pinkAccent,
                                                        ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                isActive
                                                    ? Icons.check_circle
                                                    : Icons.schedule_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    horario.nombre,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: themeProvider
                                                          .dialogTextColor, // ✅ CAMBIADO
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${horario.tipoHorario.toString().split('.').last.toUpperCase()} • ${horario.materias.length} materias',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: themeProvider
                                                          .dialogSecondaryTextColor, // ✅ CAMBIADO
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isActive)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'ACTIVO',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        LinearProgressIndicator(
                                          value: porcentaje / 100.0,
                                          backgroundColor:
                                              themeProvider.isDarkMode
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade300,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                themeProvider.isDarkMode
                                                    ? const Color(0xFF6C757D)
                                                    : Colors.deepPurple,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$porcentaje% completo • $slotsOcupados/$totalSlots clases',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: themeProvider
                                                .dialogSecondaryTextColor, // ✅ CAMBIADO
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _esRecreo(String hora) {
    return hora.contains('9:10 - 9:30') ||
        hora.contains('11:05 - 11:20') ||
        hora.contains('12:45 - 13:00');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, HorarioProvider>(
      builder: (context, themeProvider, horarioProvider, child) {
        String? userInitial = _userName != null && _userName!.isNotEmpty
            ? _userName![0].toUpperCase()
            : null;

        if (horarioProvider.isLoading) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeProvider.backgroundGradientColors,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!horarioProvider.tieneHorarioActivo) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeProvider.backgroundGradientColors,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 80,
                        color: themeProvider.secondaryTextColor,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No tienes un horario activo',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Crea tu primer horario para comenzar',
                        style: TextStyle(
                          fontSize: 16,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _mostrarDialogoCrearHorario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.isDarkMode
                              ? const Color(0xFF6C757D)
                              : Colors.purpleAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Crear Horario',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final horario = horarioProvider.horarioActivo!;
        final estadisticas = horarioProvider.obtenerEstadisticas();

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.backgroundGradientColors,
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (_userName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: themeProvider.isDarkMode
                                ? const Color(0xFF6C757D)
                                : Colors.deepPurpleAccent,
                            child: Text(
                              userInitial ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _userName!,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.primaryTextColor,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: const Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: themeProvider.cardBackgroundColor,
                      border: Border.all(
                        color: themeProvider.cardBorderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: themeProvider.isDarkMode
                                            ? [
                                                const Color(0xFF6C757D),
                                                const Color(0xFF495057),
                                              ]
                                            : [
                                                Colors.purpleAccent,
                                                Colors.pinkAccent,
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.schedule_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          horario.nombre,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                themeProvider.primaryTextColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${horario.tipoHorario.toString().split('.').last.toUpperCase()} • ${estadisticas['porcentajeCompletado']}% completo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: themeProvider
                                                .secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: themeProvider.primaryTextColor,
                                    ),
                                    onSelected: (value) async {
                                      switch (value) {
                                        case 'cambiar_tipo':
                                          _mostrarSelectorHorarios(
                                            horarioProvider,
                                          );
                                          break;
                                        case 'limpiar':
                                          _confirmarLimpiarHorario(
                                            horarioProvider,
                                          );
                                          break;
                                        case 'nuevo':
                                          _mostrarDialogoCrearHorario();
                                          break;
                                        case 'compartir':
                                          _mostrarOpcionesCompartir(
                                            horarioProvider,
                                          );
                                          break;
                                        case 'escanear':
                                          _abrirEscanerQR();
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'cambiar_tipo',
                                        child: Row(
                                          children: [
                                            Icon(Icons.swap_horiz),
                                            SizedBox(width: 8),
                                            Text('Cambiar horario'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'limpiar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.clear_all),
                                            SizedBox(width: 8),
                                            Text('Limpiar horario'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'nuevo',
                                        child: Row(
                                          children: [
                                            Icon(Icons.add),
                                            SizedBox(width: 8),
                                            Text('Nuevo horario'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'compartir',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.share,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Compartir horario'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'escanear',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.qr_code_scanner,
                                              color: Colors.green,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Escanear QR'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value:
                                    estadisticas['porcentajeCompletado'] /
                                    100.0,
                                backgroundColor: themeProvider.isDarkMode
                                    ? const Color(0xFF495057)
                                    : Colors.grey.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  themeProvider.isDarkMode
                                      ? const Color(0xFF6C757D)
                                      : Colors.purpleAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: themeProvider.cardBackgroundColor,
                        border: Border.all(
                          color: themeProvider.cardBorderColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: themeProvider.isDarkMode
                                      ? [
                                          const Color(0xFF2C3E50),
                                          const Color(0xFF34495E),
                                          const Color(0xFF4A6741),
                                        ]
                                      : [
                                          const Color(0xFF667EEA),
                                          const Color(0xFF764BA2),
                                          const Color(0xFF667EEA),
                                        ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 85,
                                    child: Text(
                                      'HORARIO',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  ...diasSemana.map(
                                    (dia) => Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: Text(
                                          dia.substring(0, 3).toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            fontSize: 11,
                                            letterSpacing: 0.3,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  children: horariosDisponibles[horario.tipoHorario]!.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final hora = entry.value;
                                    final isRecreo = _esRecreo(hora);

                                    return AnimatedContainer(
                                      duration: Duration(
                                        milliseconds: 300 + (index * 50),
                                      ),
                                      height: isRecreo ? 35 : 70,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: themeProvider.cardBorderColor
                                                .withOpacity(0.3),
                                            width: 0.5,
                                          ),
                                        ),
                                        color: isRecreo
                                            ? (themeProvider.isDarkMode
                                                  ? const Color(
                                                      0xFF2C3E50,
                                                    ).withOpacity(0.3)
                                                  : const Color(0xFFFFF8E1))
                                            : (index % 2 == 0
                                                  ? themeProvider
                                                        .cardBackgroundColor
                                                  : themeProvider.isDarkMode
                                                  ? const Color(
                                                      0xFF2C3E50,
                                                    ).withOpacity(0.1)
                                                  : const Color(0xFFFAFAFA)),
                                        gradient: isRecreo
                                            ? LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: themeProvider.isDarkMode
                                                    ? [
                                                        const Color(
                                                          0xFF2C3E50,
                                                        ).withOpacity(0.2),
                                                        const Color(
                                                          0xFF34495E,
                                                        ).withOpacity(0.1),
                                                      ]
                                                    : [
                                                        const Color(0xFFFFF3E0),
                                                        const Color(0xFFFFE0B2),
                                                      ],
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 85,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isRecreo
                                                  ? (themeProvider.isDarkMode
                                                        ? const Color(
                                                            0xFF34495E,
                                                          )
                                                        : const Color(
                                                            0xFFFFCC02,
                                                          ))
                                                  : (themeProvider.isDarkMode
                                                        ? const Color(
                                                            0xFF2C3E50,
                                                          )
                                                        : const Color(
                                                            0xFF667EEA,
                                                          )),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(8),
                                                    bottomLeft: Radius.circular(
                                                      8,
                                                    ),
                                                  ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(1, 0),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  hora.split(' ').first,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                if (!isRecreo) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    hora.split(' ').last,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          ...diasSemana.map((dia) {
                                            final materia = horarioProvider
                                                .obtenerMateria(dia, hora);
                                            final tieneMateria =
                                                materia != null;

                                            return Expanded(
                                              child: Container(
                                                height: double.infinity,
                                                margin: const EdgeInsets.all(
                                                  1.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: tieneMateria
                                                        ? horarioProvider
                                                              .obtenerColorMateria(
                                                                dia,
                                                                hora,
                                                              )
                                                        : themeProvider
                                                              .cardBorderColor
                                                              .withOpacity(0.3),
                                                    width: tieneMateria ? 2 : 1,
                                                  ),
                                                  gradient: tieneMateria
                                                      ? LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            horarioProvider
                                                                .obtenerColorMateria(
                                                                  dia,
                                                                  hora,
                                                                )
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            horarioProvider
                                                                .obtenerColorMateria(
                                                                  dia,
                                                                  hora,
                                                                )
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                          ],
                                                        )
                                                      : null,
                                                  color: isRecreo
                                                      ? Colors.transparent
                                                      : (tieneMateria
                                                            ? null
                                                            : themeProvider
                                                                  .isDarkMode
                                                            ? const Color(
                                                                0xFF34495E,
                                                              ).withOpacity(0.1)
                                                            : Colors.white),
                                                  boxShadow: tieneMateria
                                                      ? [
                                                          BoxShadow(
                                                            color: horarioProvider
                                                                .obtenerColorMateria(
                                                                  dia,
                                                                  hora,
                                                                )
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            blurRadius: 4,
                                                            spreadRadius: 1,
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: isRecreo
                                                    ? Center(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                themeProvider
                                                                    .isDarkMode
                                                                ? const Color(
                                                                    0xFF34495E,
                                                                  )
                                                                : const Color(
                                                                    0xFFFFCC02,
                                                                  ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            'RECREO',
                                                            style: TextStyle(
                                                              fontSize: 8,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  themeProvider
                                                                      .isDarkMode
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFF2C3E50,
                                                                    ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          onTap: () =>
                                                              _mostrarDialogoAgregarMateria(
                                                                dia,
                                                                hora,
                                                              ),
                                                          onLongPress:
                                                              tieneMateria
                                                              ? () async {
                                                                  final confirm = await showDialog<bool>(
                                                                    context:
                                                                        context,
                                                                    builder: (context) => AlertDialog(
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              15,
                                                                            ),
                                                                      ),
                                                                      title: const Row(
                                                                        children: [
                                                                          Icon(
                                                                            Icons.delete_outline,
                                                                            color:
                                                                                Colors.red,
                                                                            size:
                                                                                24,
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                8,
                                                                          ),
                                                                          Text(
                                                                            'Eliminar materia',
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      content: Text(
                                                                        '¿Eliminar ${materia.nombre}?',
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                            context,
                                                                            false,
                                                                          ),
                                                                          child: const Text(
                                                                            'Cancelar',
                                                                          ),
                                                                        ),
                                                                        ElevatedButton(
                                                                          onPressed: () => Navigator.pop(
                                                                            context,
                                                                            true,
                                                                          ),
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                Colors.red,
                                                                          ),
                                                                          child: const Text(
                                                                            'Eliminar',
                                                                            style: TextStyle(
                                                                              color: Colors.white,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                  if (confirm ==
                                                                      true) {
                                                                    horarioProvider
                                                                        .removerMateria(
                                                                          dia:
                                                                              dia,
                                                                          hora:
                                                                              hora,
                                                                        );
                                                                    _actualizarWidget();
                                                                  }
                                                                }
                                                              : null,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  6,
                                                                ),
                                                            child: tieneMateria
                                                                ? Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        materia
                                                                            .nombre,
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              9,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          color:
                                                                              themeProvider.primaryTextColor,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        maxLines:
                                                                            2,
                                                                      ),
                                                                      if (materia
                                                                              .aula !=
                                                                          'Sin aula') ...[
                                                                        const SizedBox(
                                                                          height:
                                                                              2,
                                                                        ),
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                4,
                                                                            vertical:
                                                                                1,
                                                                          ),
                                                                          decoration: BoxDecoration(
                                                                            color: horarioProvider
                                                                                .obtenerColorMateria(
                                                                                  dia,
                                                                                  hora,
                                                                                )
                                                                                .withOpacity(
                                                                                  0.8,
                                                                                ),
                                                                            borderRadius: BorderRadius.circular(
                                                                              6,
                                                                            ),
                                                                          ),
                                                                          child: Text(
                                                                            materia.aula,
                                                                            style: const TextStyle(
                                                                              fontSize: 7,
                                                                              color: Colors.white,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                      if (materia
                                                                              .profesor !=
                                                                          'Sin profesor') ...[
                                                                        const SizedBox(
                                                                          height:
                                                                              2,
                                                                        ),
                                                                        Text(
                                                                          materia
                                                                              .profesor,
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                7,
                                                                            color:
                                                                                themeProvider.secondaryTextColor,
                                                                            fontStyle:
                                                                                FontStyle.italic,
                                                                          ),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ],
                                                                    ],
                                                                  )
                                                                : Center(
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            themeProvider.isDarkMode
                                                                            ? const Color(
                                                                                0xFF34495E,
                                                                              ).withOpacity(
                                                                                0.5,
                                                                              )
                                                                            : Colors.grey.withOpacity(
                                                                                0.1,
                                                                              ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              20,
                                                                            ),
                                                                      ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .add_rounded,
                                                                        size:
                                                                            18,
                                                                        color: themeProvider
                                                                            .secondaryTextColor,
                                                                      ),
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'home_fab',
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            elevation: 6,
            tooltip: 'Agregar materia',
            child: const Icon(Icons.add_rounded, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Toca cualquier celda vacía para agregar una materia',
                  ),
                  backgroundColor: themeProvider.isDarkMode
                      ? const Color(0xFF6C757D)
                      : Colors.purpleAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
