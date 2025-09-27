// lib/main.dart - SOLUCIÓN FINAL CORREGIDA + WIDGET
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Servicio de notificaciones
import 'services/notification_service.dart';
// NUEVO: Servicio de widgets
import 'services/widget_service.dart';

// Modelo y Provider
import 'models/evento.dart';
import 'providers/event_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/horario_provider.dart';

// Import del AuthService
import 'auth/auth_service.dart';

// Pantallas
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/events_screen.dart';
import 'screens/world_screen.dart';
import 'screens/settings_screen.dart';
// Import de la pantalla de login
import 'auth/login_screen.dart';

void main() async {
  // Capturar errores globales
  FlutterError.onError = (FlutterErrorDetails details) {
    print('🚨 ERROR FLUTTER: ${details.exception}');
    print('📍 UBICACIÓN: ${details.library}');
  };

  // Asegurar que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');

    // NUEVO: Inicializar servicio de widgets
    await WidgetService.initialize();

    // Inicializar servicio de notificaciones
    await NotificationService.initialize();
    print('✅ Servicio de notificaciones inicializado');
  } catch (e) {
    print('❌ Error al inicializar Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ThemeProvider como primer provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // HorarioProvider
        ChangeNotifierProvider(create: (_) => HorarioProvider()),

        // AuthService
        ChangeNotifierProvider(create: (_) => AuthService()),

        // EventProvider
        ChangeNotifierProvider(
          create: (_) => EventProvider()..listenToUserChanges(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Agenda Dinámica',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

// Wrapper que maneja el flujo de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Si está cargando la verificación de autenticación
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verificando sesión...'),
                ],
              ),
            ),
          );
        }

        // Si NO está autenticado -> Ir a Login
        if (!authService.isAuthenticated) {
          return const LoginScreen();
        }

        // Si SÍ está autenticado -> Ir a FirebaseLoadingScreen
        return const FirebaseLoadingScreen();
      },
    );
  }
}

// Pantalla de carga para verificar la conexión con Firebase
class FirebaseLoadingScreen extends StatefulWidget {
  const FirebaseLoadingScreen({super.key});

  @override
  State<FirebaseLoadingScreen> createState() => _FirebaseLoadingScreenState();
}

class _FirebaseLoadingScreenState extends State<FirebaseLoadingScreen> {
  bool _isFirebaseReady = false;
  String _statusMessage = 'Conectando con Firebase...';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      if (_isDisposed) return;

      if (Firebase.apps.isNotEmpty) {
        _safeSetState(() {
          _isFirebaseReady = true;
          _statusMessage = 'Conectado exitosamente';
        });

        await _initializeHorarioProvider();

        if (_isDisposed) return;

        await Future.delayed(const Duration(seconds: 1));

        if (!_isDisposed && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        _safeSetState(() {
          _statusMessage = 'Error: Firebase no inicializado';
        });
      }
    } catch (e) {
      _safeSetState(() {
        _statusMessage = 'Error de conexión: $e';
      });

      await Future.delayed(const Duration(seconds: 3));
      if (!_isDisposed && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  Future<void> _initializeHorarioProvider() async {
    if (_isDisposed || !mounted) return;

    try {
      _safeSetState(() {
        _statusMessage = 'Inicializando horarios...';
      });

      await Future.delayed(const Duration(milliseconds: 100));

      if (!_isDisposed && mounted) {
        final horarioProvider = context.read<HorarioProvider>();

        try {
          await horarioProvider.inicializar();
          print('✅ HorarioProvider inicializado');

          // NUEVO: Actualizar widget después de inicializar horarios
          try {
            await WidgetService.updateWidget(horarioProvider: horarioProvider);
          } catch (widgetError) {
            print('⚠️ Error al actualizar widget inicial: $widgetError');
          }
        } catch (indexError) {
          print('⚠️ Error de índice en horarios (continuando): $indexError');
        }
      }
    } catch (e) {
      print('⚠️ Error al inicializar horarios: $e');
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _statusMessage = 'Continuando sin horarios...';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (!_isFirebaseReady && _statusMessage.contains('Error'))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: () => _checkFirebaseConnection(),
                  child: const Text('Reintentar'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        final eventProvider = context.read<EventProvider>();
        eventProvider.listenToEvents();
        _startNotificationChecker();

        // NUEVO: Configurar actualizaciones del widget
        _setupWidgetUpdates();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  // NUEVO: Configurar actualizaciones del widget
  void _setupWidgetUpdates() async {
    try {
      // Programar actualizaciones periódicas
      await WidgetService.schedulePeriodicUpdates();

      // Escuchar cambios en horarios
      final horarioProvider = context.read<HorarioProvider>();
      horarioProvider.addListener(_updateHomeWidget);

      // Actualización inicial
      _updateHomeWidget();

      print('✅ Widget updates configuradas');
    } catch (e) {
      print('⚠️ Error configurando widget updates: $e');
    }
  }

  // NUEVO: Actualizar widget cuando cambien los datos
  void _updateHomeWidget() async {
    if (_isDisposed || !mounted) return;

    try {
      final horarioProvider = context.read<HorarioProvider>();
      await WidgetService.updateWidget(horarioProvider: horarioProvider);
    } catch (e) {
      print('⚠️ Error actualizando widget: $e');
    }
  }

  void _checkFirebaseStatus() {
    if (Firebase.apps.isNotEmpty) {
      print('✅ Firebase Apps disponibles: ${Firebase.apps.length}');
      for (var app in Firebase.apps) {
        print('📱 App: ${app.name}, Project: ${app.options.projectId}');
      }
    } else {
      print('⚠️ No hay apps de Firebase inicializadas');
    }
  }

  void _startNotificationChecker() {
    if (_isDisposed) return;

    Stream.periodic(const Duration(minutes: 5)).listen((_) async {
      if (!_isDisposed && mounted) {
        final eventProvider = context.read<EventProvider>();
        await eventProvider.verificarNotificacionesPendientes();
      }
    });
  }

  Future<void> _addEvento(Evento evento) async {
    if (_isDisposed) return;

    try {
      await context.read<EventProvider>().addEvent(evento);
      if (!_isDisposed && mounted) {
        _showSuccessSnackBar('Evento creado exitosamente');
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _showErrorSnackBar('Error al crear evento: $e');
      }
    }
  }

  Future<void> _editEvento(int index, Evento eventoEditado) async {
    if (_isDisposed) return;

    try {
      final eventProvider = context.read<EventProvider>();
      final oldEventId = eventProvider.events[index].id;
      await eventProvider.updateEvent(oldEventId, eventoEditado);
      if (!_isDisposed && mounted) {
        _showSuccessSnackBar('Evento actualizado exitosamente');
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _showErrorSnackBar('Error al actualizar evento: $e');
      }
    }
  }

  Future<void> _deleteEvento(int index) async {
    if (_isDisposed) return;

    try {
      final eventProvider = context.read<EventProvider>();
      final evento = eventProvider.events[index];
      final eventoTitulo = evento.titulo;
      await eventProvider.deleteEvent(evento.id);
      if (!_isDisposed && mounted) {
        _showSuccessSnackBar('Evento eliminado: $eventoTitulo');
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _showErrorSnackBar('Error al eliminar evento: $e');
      }
    }
  }

  Future<void> _toggleEventNotification(String eventoId) async {
    if (_isDisposed) return;

    try {
      await context.read<EventProvider>().toggleNotificacion(eventoId);
      if (!_isDisposed && mounted) {
        _showSuccessSnackBar('Configuración de notificación actualizada');
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _showErrorSnackBar('Error al cambiar notificación: $e');
      }
    }
  }

  Future<void> _updateNotificationTime(String eventoId, int minutes) async {
    if (_isDisposed) return;

    try {
      await context.read<EventProvider>().updateMinutosAntes(eventoId, minutes);
      if (!_isDisposed && mounted) {
        _showSuccessSnackBar(
          'Tiempo de notificación actualizado a $minutes minutos',
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _showErrorSnackBar('Error al actualizar tiempo: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (_isDisposed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (_isDisposed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  List<Widget> _buildPages() {
    return [
      // Home Screen - CON MANEJO DE ERRORES
      Consumer2<EventProvider, HorarioProvider>(
        builder: (context, eventProvider, horarioProvider, child) {
          if (eventProvider.errorMessage != null && !_isDisposed && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isDisposed && mounted) {
                _showErrorSnackBar(eventProvider.errorMessage!);
                eventProvider.clearError();
              }
            });
          }

          return HomeScreen(
            eventos: eventProvider.events,
            onGoToEvents: () => _safeSetState(() => _selectedIndex = 2),
          );
        },
      ),

      // Calendar Screen
      Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          return CalendarScreen(
            eventos: eventProvider.events,
            onAddEvento: _addEvento,
            onEditEvento: _editEvento,
            onDeleteEvento: _deleteEvento,
            onGoToEvents: () => _safeSetState(() => _selectedIndex = 2),
            onToggleNotification: _toggleEventNotification,
            onUpdateNotificationTime: _updateNotificationTime,
          );
        },
      ),

      // Events Screen
      Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          return EventsScreen(
            eventos: eventProvider.events,
            onAddEvento: _addEvento,
            onEditEvento: _editEvento,
            onDeleteEvento: _deleteEvento,
            onToggleNotification: _toggleEventNotification,
            onUpdateNotificationTime: _updateNotificationTime,
          );
        },
      ),

      const WorldScreen(),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) => _safeSetState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          if (eventProvider.isLoading && eventProvider.events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando eventos...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (eventProvider.eventosConNotificacionProxima.isNotEmpty)
                    Text(
                      '🔔 ${eventProvider.eventosConNotificacionProxima.length} notificaciones próximas',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.orange),
                    ),
                ],
              ),
            );
          }

          return IndexedStack(index: _selectedIndex, children: _buildPages());
        },
      ),
      bottomNavigationBar: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          final notificacionesProximas =
              eventProvider.eventosConNotificacionProxima.length;

          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.calendar_today),
                    if (notificacionesProximas > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '$notificacionesProximas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Calendario',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.event),
                label: 'Eventos',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.public),
                label: 'World',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Ajustes',
              ),
            ],
          );
        },
      ),
    );
  }
}
