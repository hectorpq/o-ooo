// lib/auth/auth_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? _errorMessage;

  AuthService() {
    _initialize();
  }

  // Inicialización del servicio
  void _initialize() {
    // Escuchar cambios de estado de autenticación
    _auth.authStateChanges().listen((User? user) {
      _isLoading = false;
      _clearError(); // Limpiar errores cuando cambia el estado
      notifyListeners();

      // Log para debugging (similar al patrón usado en main.dart)
      if (user != null) {
        print('✅ Usuario autenticado: ${user.email}');
      } else {
        print('❌ Usuario no autenticado');
      }
    });
  }

  // GETTERS para el AuthWrapper y otras pantallas
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _auth.currentUser != null;
  String? get errorMessage => _errorMessage;

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Obtener email del usuario actual
  String? get currentUserEmail => _auth.currentUser?.email;

  // Verificar si el email está verificado
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Stream de cambios de estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Stream de cambios de usuario
  Stream<User?> get userChanges => _auth.userChanges();

  // Limpiar mensajes de error
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Método helper para manejar errores de Firebase
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'La contraseña es demasiado débil';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'invalid-email':
        return 'El formato del email no es válido';
      case 'user-not-found':
        return 'No existe usuario con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      default:
        return 'Error de autenticación: $errorCode';
    }
  }

  // Registrar usuario con email y password
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      print('🔄 Intentando registrar usuario: $email');

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ Usuario registrado exitosamente: ${result.user?.email}');

      // Enviar verificación de email automáticamente
      await result.user?.sendEmailVerification();
      print('📧 Email de verificación enviado');

      return result.user;
    } on FirebaseAuthException catch (e) {
      final errorMsg = _getFirebaseErrorMessage(e.code);
      _errorMessage = errorMsg;
      print('❌ Error en registro: ${e.code} - $errorMsg');
      notifyListeners();
      throw Exception(errorMsg);
    } catch (e) {
      _errorMessage = 'Error inesperado al registrar usuario';
      print('❌ Error inesperado en registro: $e');
      notifyListeners();
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Iniciar sesión
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      print('🔄 Intentando iniciar sesión: $email');

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ Sesión iniciada exitosamente: ${result.user?.email}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      final errorMsg = _getFirebaseErrorMessage(e.code);
      _errorMessage = errorMsg;
      print('❌ Error en login: ${e.code} - $errorMsg');
      notifyListeners();
      throw Exception(errorMsg);
    } catch (e) {
      _errorMessage = 'Error inesperado al iniciar sesión';
      print('❌ Error inesperado en login: $e');
      notifyListeners();
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Enviar email de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _clearError();
      print('🔄 Enviando email de recuperación a: $email');

      await _auth.sendPasswordResetEmail(email: email.trim());
      print('✅ Email de recuperación enviado exitosamente');
    } on FirebaseAuthException catch (e) {
      final errorMsg = _getFirebaseErrorMessage(e.code);
      _errorMessage = errorMsg;
      print('❌ Error enviando email de recuperación: ${e.code} - $errorMsg');
      notifyListeners();
      throw Exception(errorMsg);
    } catch (e) {
      _errorMessage = 'Error inesperado al enviar email de recuperación';
      print('❌ Error inesperado enviando email: $e');
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  // Verificar email del usuario actual
  Future<void> sendEmailVerification() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('No hay usuario logueado');
      }

      if (_auth.currentUser!.emailVerified) {
        print('ℹ️ Email ya está verificado');
        return;
      }

      print('🔄 Enviando verificación de email...');
      await _auth.currentUser!.sendEmailVerification();
      print('✅ Email de verificación enviado');
    } on FirebaseAuthException catch (e) {
      final errorMsg = _getFirebaseErrorMessage(e.code);
      _errorMessage = errorMsg;
      print('❌ Error enviando verificación: ${e.code} - $errorMsg');
      notifyListeners();
      throw Exception(errorMsg);
    } catch (e) {
      _errorMessage = 'Error inesperado al verificar email';
      print('❌ Error inesperado en verificación: $e');
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  // Recargar información del usuario
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      notifyListeners();
      print('✅ Información del usuario recargada');
    } catch (e) {
      print('❌ Error recargando usuario: $e');
    }
  }

  // Cerrar sesión (método principal)
  Future<void> signOut() async {
    try {
      print('🔄 Cerrando sesión...');
      await _auth.signOut();
      _clearError();
      print('✅ Sesión cerrada exitosamente');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión';
      print('❌ Error cerrando sesión: $e');
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  // Alias para logout (compatibilidad con main.dart)
  Future<void> logout() async => await signOut();

  // Eliminar cuenta del usuario
  Future<void> deleteAccount() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('No hay usuario logueado');
      }

      print('🔄 Eliminando cuenta de usuario...');
      await _auth.currentUser!.delete();
      _clearError();
      print('✅ Cuenta eliminada exitosamente');
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      final errorMsg = _getFirebaseErrorMessage(e.code);
      _errorMessage = errorMsg;
      print('❌ Error eliminando cuenta: ${e.code} - $errorMsg');
      notifyListeners();
      throw Exception(errorMsg);
    } catch (e) {
      _errorMessage = 'Error inesperado al eliminar cuenta';
      print('❌ Error inesperado eliminando cuenta: $e');
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  // Actualizar perfil del usuario
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('No hay usuario logueado');
      }

      print('🔄 Actualizando perfil del usuario...');
      await _auth.currentUser!.updateDisplayName(displayName);
      if (photoURL != null) {
        await _auth.currentUser!.updatePhotoURL(photoURL);
      }

      await reloadUser();
      print('✅ Perfil actualizado exitosamente');
    } on FirebaseAuthException catch (e) {
      final errorMsg = _getFirebaseErrorMessage(e.code);
      _errorMessage = errorMsg;
      print('❌ Error actualizando perfil: ${e.code} - $errorMsg');
      notifyListeners();
      throw Exception(errorMsg);
    } catch (e) {
      _errorMessage = 'Error inesperado al actualizar perfil';
      print('❌ Error inesperado actualizando perfil: $e');
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  // Cambiar contraseña
  Future<void> changePassword(String newPassword) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('No hay usuario logueado');
      }

      print('🔄 Cambiando contraseña...');
      await _auth.currentUser!.updatePassword(newPassword);
      print('✅ Contraseña cambiada exitosamente');
    } on FirebaseAuthException catch (e) {
      final errorMsg = _getFirebaseErrorMessage(e.code);
      _errorMessage = errorMsg;
      print('❌ Error cambiando contraseña: ${e.code} - $errorMsg');
      notifyListeners();
      throw Exception(errorMsg);
    } catch (e) {
      _errorMessage = 'Error inesperado al cambiar contraseña';
      print('❌ Error inesperado cambiando contraseña: $e');
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  // Limpiar error manualmente (útil para UI)
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    print('🧹 AuthService disposed');
    super.dispose();
  }
}
