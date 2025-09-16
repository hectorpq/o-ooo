// lib/services/sound_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;
  static bool _soundEnabled = true;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configurar el reproductor de audio
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);

      _isInitialized = true;
      print('SoundService inicializado correctamente');
    } catch (e) {
      print('Error al inicializar SoundService: $e');
    }
  }

  // Sonido cuando se crea un evento
  static Future<void> playEventCreatedSound() async {
    if (!_isInitialized || !_soundEnabled) return;

    try {
      // Usar sonido del sistema
      await _playSystemSound();

      // Alternativa: usar archivo de audio personalizado
      // await _audioPlayer.play(AssetSource('sounds/event_created.mp3'));

      print('Sonido de evento creado reproducido');
    } catch (e) {
      print('Error al reproducir sonido de evento creado: $e');
    }
  }

  // Sonido para recordatorio (5 min antes)
  static Future<void> playReminderSound() async {
    if (!_isInitialized || !_soundEnabled) return;

    try {
      await _playSystemSound();

      // Sonido más suave para recordatorio
      // await _audioPlayer.play(AssetSource('sounds/reminder.mp3'));

      print('Sonido de recordatorio reproducido');
    } catch (e) {
      print('Error al reproducir sonido de recordatorio: $e');
    }
  }

  // Sonido cuando inicia el evento
  static Future<void> playEventStartSound() async {
    if (!_isInitialized || !_soundEnabled) return;

    try {
      await _playSystemSound();

      // Sonido más prominente para inicio
      // await _audioPlayer.play(AssetSource('sounds/event_start.mp3'));

      print('Sonido de inicio de evento reproducido');
    } catch (e) {
      print('Error al reproducir sonido de inicio: $e');
    }
  }

  // Reproducir sonido del sistema (funciona sin archivos externos)
  static Future<void> _playSystemSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      print('Error al reproducir sonido del sistema: $e');
    }
  }

  // Métodos para sonidos personalizados (si agregas archivos de audio)
  static Future<void> playCustomSound(String soundPath) async {
    if (!_isInitialized || !_soundEnabled) return;

    try {
      await _audioPlayer.play(AssetSource(soundPath));
      print('Sonido personalizado reproducido: $soundPath');
    } catch (e) {
      print('Error al reproducir sonido personalizado: $e');
    }
  }

  // Reproducir sonido desde URL
  static Future<void> playNetworkSound(String url) async {
    if (!_isInitialized || !_soundEnabled) return;

    try {
      await _audioPlayer.play(UrlSource(url));
      print('Sonido de red reproducido: $url');
    } catch (e) {
      print('Error al reproducir sonido de red: $e');
    }
  }

  // Controlar volumen
  static Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;

    try {
      // El volumen debe estar entre 0.0 y 1.0
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(clampedVolume);
      print('Volumen establecido a: $clampedVolume');
    } catch (e) {
      print('Error al establecer volumen: $e');
    }
  }

  // Habilitar/deshabilitar sonidos
  static void enableSound(bool enabled) {
    _soundEnabled = enabled;
    print('Sonidos ${enabled ? 'habilitados' : 'deshabilitados'}');
  }

  // Verificar si los sonidos están habilitados
  static bool get isSoundEnabled => _soundEnabled;

  // Parar cualquier sonido que se esté reproduciendo
  static Future<void> stopSound() async {
    if (!_isInitialized) return;

    try {
      await _audioPlayer.stop();
      print('Sonido detenido');
    } catch (e) {
      print('Error al detener sonido: $e');
    }
  }

  // Test de sonido
  static Future<void> testSound() async {
    if (!_isInitialized) {
      print('SoundService no inicializado, inicializando...');
      await initialize();
    }

    try {
      await playEventCreatedSound();
      print('Test de sonido completado');
    } catch (e) {
      print('Error en test de sonido: $e');
    }
  }

  // Limpiar recursos
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      print('SoundService limpiado');
    } catch (e) {
      print('Error al limpiar SoundService: $e');
    }
  }

  // Vibración (funciona sin permisos especiales en la mayoría de dispositivos)
  static Future<void> vibrate() async {
    try {
      await HapticFeedback.mediumImpact();
      print('Vibración activada');
    } catch (e) {
      print('Error al vibrar: $e');
    }
  }

  // Combo: sonido + vibración
  static Future<void> playSoundWithVibration() async {
    await Future.wait([playEventCreatedSound(), vibrate()]);
  }
}
