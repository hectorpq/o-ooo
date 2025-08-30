// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Modelo y Provider
import 'models/evento.dart';
import 'providers/event_provider.dart';

// Pantallas
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/events_screen.dart';
import 'screens/world_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  // Asegurar que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase inicializado correctamente');
  } catch (e) {
    print('Error al inicializar Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => EventProvider())],
      child: MaterialApp(
        title: 'Agenda Dinámica',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const FirebaseLoadingScreen(),
      ),
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

        // Cargar eventos desde Firebase
        if (mounted) {
          await context.read<EventProvider>().loadEvents();
        }

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
    // 🔥 NUEVA FUNCIONALIDAD: Sincronización en tiempo real
    // Esto hará que los eventos se actualicen automáticamente cuando otros usuarios los modifiquen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().listenToEvents();
    });
  }

  void _checkFirebaseStatus() {
    if (Firebase.apps.isNotEmpty) {
      print('Firebase Apps disponibles: ${Firebase.apps.length}');
      for (var app in Firebase.apps) {
        print('App: ${app.name}, Options: ${app.options.projectId}');
      }
    } else {
      print('No hay apps de Firebase inicializadas');
    }
  }

  // Métodos para manejar eventos con Firebase
  Future<void> _addEvento(Evento evento) async {
    try {
      await context.read<EventProvider>().addEvent(evento);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Evento creado exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error al crear evento: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editEvento(int index, Evento eventoEditado) async {
    try {
      final eventProvider = context.read<EventProvider>();
      final oldEventId = eventProvider.events[index].id;
      await eventProvider.updateEvent(oldEventId, eventoEditado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Evento actualizado exitosamente'),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error al actualizar evento: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteEvento(int index) async {
    try {
      final eventProvider = context.read<EventProvider>();
      final eventoId = eventProvider.events[index].id;
      final eventoTitulo = eventProvider.events[index].titulo;

      await eventProvider.deleteEvent(eventoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Evento eliminado: $eventoTitulo'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error al eliminar evento: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Limpiar recursos cuando se destruya el widget
  @override
  void dispose() {
    // Detener la escucha de eventos de Firebase
    context.read<EventProvider>().stopListening();
    super.dispose();
  }

  // Páginas usando Consumer para obtener eventos de Firebase
  List<Widget> _buildPages() {
    return [
      // Home Screen
      Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
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
          );
        },
      ),

      const WorldScreen(),
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
                  SizedBox(height: 16),
                  Text(
                    'Cargando eventos...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return IndexedStack(index: _selectedIndex, children: _buildPages());
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Eventos'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'World'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
