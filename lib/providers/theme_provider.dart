// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeService _themeService = ThemeService();
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  // Cargar preferencia guardada
  Future<void> _loadThemePreference() async {
    _isDarkMode = await _themeService.getThemePreference();
    notifyListeners();
  }

  // Cambiar tema
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _themeService.saveThemePreference(_isDarkMode);
    notifyListeners();
  }

  // Definir tema claro (colores originales)
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Definir tema oscuro (negro con plomo)
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.grey,
      scaffoldBackgroundColor: const Color(0xFF121212), // Negro principal
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E), // Gris oscuro para bottom nav
        selectedItemColor: Color(0xFF6C757D), // Plomo claro para seleccionado
        unselectedItemColor: Color(
          0xFF495057,
        ), // Plomo oscuro para no seleccionado
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
      ),
    );
  }

  // Obtener tema actual
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  // Colores específicos para el gradiente de fondo
  List<Color> get backgroundGradientColors {
    if (_isDarkMode) {
      return [
        const Color(0xFF121212), // Negro principal
        const Color(0xFF1E1E1E), // Negro más claro
        const Color(0xFF2C2C2C), // Gris muy oscuro
        const Color(0xFF495057), // Plomo oscuro
      ];
    } else {
      return [
        const Color(0xFF667eea), // Azul
        const Color(0xFF764ba2), // Púrpura
        const Color(0xFFf093fb), // Rosa
        const Color(0xFFf5576c), // Rojo
      ];
    }
  }

  // Colores para los cards con glassmorphism
  Color get cardBackgroundColor {
    if (_isDarkMode) {
      return Colors.grey.shade800.withOpacity(0.3);
    } else {
      return Colors.white.withOpacity(0.25);
    }
  }

  // Color del borde para los cards
  Color get cardBorderColor {
    if (_isDarkMode) {
      return Colors.grey.shade600.withOpacity(0.3);
    } else {
      return Colors.white.withOpacity(0.2);
    }
  }

  // Color del texto principal
  Color get primaryTextColor {
    return _isDarkMode ? Colors.white : Colors.white;
  }

  // Color del texto secundario
  Color get secondaryTextColor {
    if (_isDarkMode) {
      return Colors.grey.shade300;
    } else {
      return Colors.white.withOpacity(0.8);
    }
  }

  // Colores para los gradientes de los iconos en settings
  Map<String, List<Color>> get iconGradientColors {
    if (_isDarkMode) {
      return {
        'theme': [const Color(0xFF495057), const Color(0xFF6C757D)], // Plomo
        'notifications': [
          const Color(0xFF5A6268),
          const Color(0xFF6C757D),
        ], // Plomo verdoso
        'language': [
          const Color(0xFF495057),
          const Color(0xFF5A6268),
        ], // Plomo azulado
        'about': [
          const Color(0xFF6C757D),
          const Color(0xFF495057),
        ], // Plomo ámbar
        'delete': [
          const Color(0xFF6C5C5C),
          const Color(0xFF5A5252),
        ], // Plomo rojizo
      };
    } else {
      return {
        'theme': [Colors.indigoAccent, Colors.purpleAccent],
        'notifications': [Colors.greenAccent, Colors.tealAccent],
        'language': [Colors.blueAccent, Colors.cyanAccent],
        'about': [Colors.amber, Colors.orangeAccent],
        'delete': [Colors.red, Colors.redAccent],
      };
    }
  }
}
