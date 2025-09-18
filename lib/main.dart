// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Servicio de notificaciones
import 'services/notification_service.dart';

// Modelo y Provider
import 'models/evento.dart';
import 'providers/event_provider.dart';
import 'providers/theme_provider.dart'; // ✨ NUEVO: Import del ThemeProvider

// ✨ AGREGAR: Import del AuthService
import 'auth/auth_service.dart';

// Pantallas
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/events_screen.dart';
import 'screens/world_screen.dart';
import 'screens/settings_screen.dart';
// ✨ AGREGAR: Import de la pantalla de login
import 'auth/login_screen.dart';

void main() async {
  // Asegurar que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');

    // 🔔 Inicializar servicio de notificaciones
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
        // ✨ NUEVO: ThemeProvider como primer provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // ✨ AGREGAR: AuthService como segundo provider
        ChangeNotifierProvider(
          create: (_) => AuthService(), // Se inicializa automáticamente
        ),
        ChangeNotifierProvider(
          create: (_) => EventProvider()..listenToUserChanges(),
        ),
      ],
      // ✨ NUEVO: Consumer para usar el tema dinámico
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
            // ✨ CAMBIO: Usar AuthWrapper en lugar de FirebaseLoadingScreen
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

// ✨ NUEVO: Wrapper que maneja el flujo de autenticación
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
          return const LoginScreen(); // Tu pantalla de login existente
        }

        // Si SÍ está autenticado -> Ir a FirebaseLoadingScreen (tu flujo normal)
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

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      // Verificar si Firebase está inicializado
      await Future.delayed(const Duration(seconds: 1));

      if (Firebase.apps.isNotEmpty) {
        setState(() {
          _isFirebaseReady = true;
          _statusMessage = 'Conectado exitosamente';
        });

        // ✨ ELIMINADO: NO cargar eventos aquí porque listenToEvents() lo hace automáticamente
        // await context.read<EventProvider>().loadEvents(); // ← LÍNEA ELIMINADA

        // Esperar un poco antes de navegar
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        setState(() {
          _statusMessage = 'Error: Firebase no inicializado';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error de conexión: $e';
      });

      // Intentar continuar sin Firebase después de un error
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
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

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();

    // 🔥 NUEVA FUNCIONALIDAD: Sincronización en tiempo real automática
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventProvider = context.read<EventProvider>();
      // ✨ Solo usar listenToEvents() - esto carga Y escucha cambios automáticamente
      eventProvider.listenToEvents();

      // 🔔 Verificar notificaciones pendientes periódicamente
      _startNotificationChecker();
    });
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

  // 🔔 Verificador periódico de notificaciones
  void _startNotificationChecker() {
    // Verificar cada 5 minutos si hay notificaciones pendientes
    Stream.periodic(const Duration(minutes: 5)).listen((_) async {
      final eventProvider = context.read<EventProvider>();
      await eventProvider.verificarNotificacionesPendientes();
    });
  }

  // ✨ MÉTODOS ACTUALIZADOS para usar el nuevo EventProvider

  Future<void> _addEvento(Evento evento) async {
    try {
      // El nuevo EventProvider ya maneja las notificaciones internamente
      await context.read<EventProvider>().addEvent(evento);

      if (mounted) {
        _showSuccessSnackBar('Evento creado exitosamente');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al crear evento: $e');
      }
    }
  }

  Future<void> _editEvento(int index, Evento eventoEditado) async {
    try {
      final eventProvider = context.read<EventProvider>();
      final oldEventId = eventProvider.events[index].id;

      // El nuevo EventProvider ya reprograma las notificaciones automáticamente
      await eventProvider.updateEvent(oldEventId, eventoEditado);

      if (mounted) {
        _showSuccessSnackBar('Evento actualizado exitosamente');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al actualizar evento: $e');
      }
    }
  }

  Future<void> _deleteEvento(int index) async {
    try {
      final eventProvider = context.read<EventProvider>();
      final evento = eventProvider.events[index];
      final eventoTitulo = evento.titulo;

      // El nuevo EventProvider ya cancela las notificaciones automáticamente
      await eventProvider.deleteEvent(evento.id);

      if (mounted) {
        _showSuccessSnackBar('Evento eliminado: $eventoTitulo');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al eliminar evento: $e');
      }
    }
  }

  // 🔔 NUEVAS FUNCIONES para gestión avanzada de notificaciones
  Future<void> _toggleEventNotification(String eventoId) async {
    try {
      await context.read<EventProvider>().toggleNotificacion(eventoId);

      if (mounted) {
        _showSuccessSnackBar('Configuración de notificación actualizada');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al cambiar notificación: $e');
      }
    }
  }

  Future<void> _updateNotificationTime(String eventoId, int minutes) async {
    try {
      await context.read<EventProvider>().updateMinutosAntes(eventoId, minutes);

      if (mounted) {
        _showSuccessSnackBar(
          'Tiempo de notificación actualizado a $minutes minutos',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al actualizar tiempo: $e');
      }
    }
  }

  // 🎨 Métodos helper para SnackBars mejorados
  void _showSuccessSnackBar(String message) {
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

  // Limpiar recursos cuando se destruya el widget
  @override
  void dispose() {
    // El EventProvider se limpia automáticamente en su dispose()
    super.dispose();
  }

  // ✨ Páginas mejoradas con Consumer para reactividad
  List<Widget> _buildPages() {
    return [
      // Home Screen
      Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          if (eventProvider.errorMessage != null) {
            // Mostrar error si hay problemas
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorSnackBar(eventProvider.errorMessage!);
              eventProvider.clearError();
            });
          }

          return HomeScreen(
            eventos: eventProvider.events,
            onGoToEvents: () => setState(() => _selectedIndex = 2),
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
            onGoToEvents: () => setState(() => _selectedIndex = 2),
            // 🔔 Nuevas funciones de notificaciones
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
            // 🔔 Nuevas funciones de notificaciones
            onToggleNotification: _toggleEventNotification,
            onUpdateNotificationTime: _updateNotificationTime,
          );
        },
      ),

      const WorldScreen(),

      // ✨ CORREGIDO: Usar tu SettingsScreen separado sin parámetros
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          // Mostrar loading mientras se cargan los eventos
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
          // Mostrar badge de notificaciones próximas
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
