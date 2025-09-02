import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../welcome/welcome_screen.dart';
import '../main.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class AuthWrapperSimple extends StatefulWidget {
  const AuthWrapperSimple({super.key});

  @override
  State<AuthWrapperSimple> createState() => _AuthWrapperSimpleState();
}

class _AuthWrapperSimpleState extends State<AuthWrapperSimple> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Listener para cambios de autenticación
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    });
    // Estado inicial
    _currentUser = FirebaseAuth.instance.currentUser;
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }
    if (_currentUser != null) {
      // Mostrar MainScreen con menú inferior tras login
      return const MainScreen();
    }
    return const WelcomeScreen();
  }
}
