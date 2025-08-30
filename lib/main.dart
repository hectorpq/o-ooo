// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Modelo
import 'models/evento.dart';

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
    return MaterialApp(
      title: 'Agenda Dinámica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const FirebaseLoadingScreen(),
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

  /// Lista en memoria de eventos
  final List<Evento> _eventos = [];

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
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

  // CRUD local
  void _addEvento(Evento evento) {
    setState(() {
      _eventos.add(evento);
      _eventos.sort((a, b) => a.fecha.compareTo(b.fecha));
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Evento creado')));
  }

  void _editEvento(int index, Evento eventoEditado) {
    if (index < 0 || index >= _eventos.length) return;
    setState(() {
      _eventos[index] = eventoEditado;
      _eventos.sort((a, b) => a.fecha.compareTo(b.fecha));
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Evento actualizado')));
  }

  void _deleteEvento(int index) {
    if (index < 0 || index >= _eventos.length) return;
    final removed = _eventos[index];
    setState(() {
      _eventos.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Evento eliminado: ${removed.titulo}')),
    );
  }

  // Páginas (usamos getter para que capture el estado actual y callbacks)
  List<Widget> get _pages => [
    // Aquí pasamos la lista dinámica y el callback para ir a 'Eventos'
    HomeScreen(
      eventos: _eventos,
      onGoToEvents: () => setState(() => _selectedIndex = 2),
    ),

    CalendarScreen(
      eventos: _eventos,
      onAddEvento: _addEvento,
      onEditEvento: (index, evento) => _editEvento(index, evento),
      onDeleteEvento: (index) => _deleteEvento(index),
      onGoToEvents: () => setState(() => _selectedIndex = 2),
    ),

    EventsScreen(
      eventos: _eventos,
      onAddEvento: _addEvento,
      onEditEvento: (index, evento) => _editEvento(index, evento),
      onDeleteEvento: (index) => _deleteEvento(index),
    ),

    const WorldScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
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
