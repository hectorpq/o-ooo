// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../auth/auth_wrapper_simple.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _slideController;
  bool notificationsEnabled = true;
  String selectedLanguage = 'Español';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _showLanguageDialog() {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.isDarkMode
                    ? [
                        Colors.grey.shade800.withOpacity(0.9),
                        Colors.grey.shade700.withOpacity(0.8),
                      ]
                    : [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.8),
                      ],
              ),
              border: Border.all(color: themeProvider.cardBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 25,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Seleccionar Idioma',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...['Español', 'English', 'Português', 'Français'].map(
                        (lang) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            gradient: selectedLanguage == lang
                                ? LinearGradient(
                                    colors: themeProvider.isDarkMode
                                        ? [
                                            const Color(0xFF495057),
                                            const Color(0xFF6C757D),
                                          ]
                                        : [
                                            Colors.purpleAccent,
                                            Colors.deepPurpleAccent,
                                          ],
                                  )
                                : LinearGradient(
                                    colors: themeProvider.isDarkMode
                                        ? [
                                            Colors.grey.shade700.withOpacity(
                                              0.2,
                                            ),
                                            Colors.grey.shade600.withOpacity(
                                              0.1,
                                            ),
                                          ]
                                        : [
                                            Colors.grey.withOpacity(0.2),
                                            Colors.grey.withOpacity(0.1),
                                          ],
                                  ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              lang,
                              style: TextStyle(
                                color: selectedLanguage == lang
                                    ? Colors.white
                                    : themeProvider.primaryTextColor,
                                fontWeight: selectedLanguage == lang
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                selectedLanguage = lang;
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.isDarkMode
                    ? [
                        const Color(0xFF6C5C5C).withOpacity(0.9),
                        const Color(0xFF5A5252).withOpacity(0.8),
                      ]
                    : [
                        Colors.red.withOpacity(0.9),
                        Colors.redAccent.withOpacity(0.8),
                      ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '¡Atención!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Esta acción eliminará todos tus eventos de forma permanente. ¿Estás seguro?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Aquí iría la lógica para borrar todos los eventos
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Todos los eventos han sido eliminados',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required List<Color> gradientColors,
    Widget? trailing,
    bool isDangerous = false,
  }) {
    final themeProvider = context.watch<ThemeProvider>();

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeProvider.cardBackgroundColor,
              themeProvider.cardBackgroundColor.withOpacity(0.8),
            ],
          ),
          border: Border.all(
            color: isDangerous
                ? (themeProvider.isDarkMode
                      ? const Color(0xFF6C5C5C).withOpacity(0.5)
                      : Colors.red.withOpacity(0.3))
                : themeProvider.cardBorderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: isDangerous
                  ? (themeProvider.isDarkMode
                        ? const Color(0xFF6C5C5C).withOpacity(0.2)
                        : Colors.red.withOpacity(0.1))
                  : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors.first.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDangerous
                                    ? (themeProvider.isDarkMode
                                          ? const Color(0xFF6C5C5C)
                                          : Colors.red.shade300)
                                    : themeProvider.primaryTextColor,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDangerous
                                    ? (themeProvider.isDarkMode
                                          ? const Color(
                                              0xFF6C5C5C,
                                            ).withOpacity(0.8)
                                          : Colors.red.shade200.withOpacity(
                                              0.8,
                                            ))
                                    : themeProvider.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trailing != null) trailing,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
                  // Header personalizado
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeProvider.cardBackgroundColor,
                          themeProvider.cardBackgroundColor.withOpacity(0.8),
                        ],
                      ),
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
                          child: Row(
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
                                            Colors.orangeAccent,
                                            Colors.pinkAccent,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.settings_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Configuración',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.primaryTextColor,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Lista de configuraciones
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FadeTransition(
                        opacity: _animController,
                        child: Column(
                          children: [
                            // Tema
                            _buildSettingsCard(
                              icon: Icons.palette_rounded,
                              title: 'Tema',
                              subtitle: themeProvider.isDarkMode
                                  ? 'Modo Oscuro'
                                  : 'Modo Claro',
                              gradientColors:
                                  themeProvider.iconGradientColors['theme']!,
                              onTap: () async {
                                await themeProvider.toggleTheme();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Tema cambiado a ${themeProvider.isDarkMode ? 'Oscuro' : 'Claro'}',
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
                                }
                              },
                              trailing: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 60,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    colors: themeProvider.isDarkMode
                                        ? [
                                            const Color(0xFF495057),
                                            const Color(0xFF6C757D),
                                          ]
                                        : [
                                            Colors.grey.shade300,
                                            Colors.grey.shade400,
                                          ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedPositioned(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                      left: themeProvider.isDarkMode ? 30 : 0,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          themeProvider.isDarkMode
                                              ? Icons.dark_mode
                                              : Icons.light_mode,
                                          size: 18,
                                          color: themeProvider.isDarkMode
                                              ? const Color(0xFF495057)
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Notificaciones
                            _buildSettingsCard(
                              icon: notificationsEnabled
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_off_rounded,
                              title: 'Notificaciones',
                              subtitle: notificationsEnabled
                                  ? 'Recordatorios activados'
                                  : 'Recordatorios desactivados',
                              gradientColors: themeProvider
                                  .iconGradientColors['notifications']!,
                              onTap: () {
                                setState(() {
                                  notificationsEnabled = !notificationsEnabled;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      notificationsEnabled
                                          ? 'Notificaciones activadas'
                                          : 'Notificaciones desactivadas',
                                    ),
                                    backgroundColor: themeProvider.isDarkMode
                                        ? const Color(0xFF5A6268)
                                        : Colors.tealAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              trailing: Icon(
                                notificationsEnabled
                                    ? Icons.toggle_on_rounded
                                    : Icons.toggle_off_rounded,
                                color: notificationsEnabled
                                    ? (themeProvider.isDarkMode
                                          ? const Color(0xFF5A6268)
                                          : Colors.greenAccent)
                                    : Colors.white.withOpacity(0.5),
                                size: 32,
                              ),
                            ),

                            // Idioma
                            _buildSettingsCard(
                              icon: Icons.language_rounded,
                              title: 'Idioma',
                              subtitle: selectedLanguage,
                              gradientColors:
                                  themeProvider.iconGradientColors['language']!,
                              onTap: _showLanguageDialog,
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: themeProvider.primaryTextColor,
                                size: 18,
                              ),
                            ),

                            // Información de la app
                            _buildSettingsCard(
                              icon: Icons.info_rounded,
                              title: 'Acerca de',
                              subtitle: 'Versión 1.0.0',
                              gradientColors:
                                  themeProvider.iconGradientColors['about']!,
                              onTap: () {
                                showAboutDialog(
                                  context: context,
                                  applicationName: 'Mi Calendario',
                                  applicationVersion: '1.0.0',
                                  applicationIcon: Container(
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
                                    child: const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: themeProvider.primaryTextColor,
                                size: 18,
                              ),
                            ),

                            // Borrar todos los eventos (peligroso)
                            _buildSettingsCard(
                              icon: Icons.delete_forever_rounded,
                              title: 'Borrar todos los eventos',
                              subtitle: 'Esta acción no se puede deshacer',
                              gradientColors:
                                  themeProvider.iconGradientColors['delete']!,
                              onTap: _showDeleteConfirmation,
                              isDangerous: true,
                              trailing: Icon(
                                Icons.warning_rounded,
                                color: themeProvider.isDarkMode
                                    ? const Color(0xFF6C5C5C)
                                    : Colors.red,
                                size: 20,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Botón para cerrar sesión
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeProvider.isDarkMode
                                      ? const Color(0xFF6C757D)
                                      : Colors.deepPurpleAccent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text(
                                  'Cerrar sesión',
                                  style: TextStyle(fontSize: 16),
                                ),
                                onPressed: () async {
                                  // Cerrar sesión con Firebase
                                  await FirebaseAuth.instance.signOut();
                                  // Navegar al wrapper principal y limpiar el stack
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AuthWrapperSimple(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                              ),
                            ),

                            // Footer
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                  colors: [
                                    themeProvider.cardBackgroundColor,
                                    themeProvider.cardBackgroundColor
                                        .withOpacity(0.5),
                                  ],
                                ),
                              ),
                              child: Text(
                                'Hecho con ❤️ para organizar tu vida',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: themeProvider.secondaryTextColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
