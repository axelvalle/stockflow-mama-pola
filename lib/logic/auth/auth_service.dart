import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';
import 'package:mamapola_app_v1/services/activity_logger_service.dart';
import 'dart:async'; // Aunque ya no usamos Timer, StreamController sí lo requiere.
import 'package:mamapola_app_v1/services/tutorial_service.dart';

class UserNotVerifiedException implements Exception {
  final String message;
  UserNotVerifiedException(this.message);
}

class UserBannedException implements Exception {
  final String message;
  UserBannedException(this.message);
}

class AuthService {
  static final _client = Supabase.instance.client;
  static final StreamController<AuthChangeEvent> _authNavigationEvents =
      StreamController<AuthChangeEvent>.broadcast();

  static Stream<AuthChangeEvent> get authNavigationStream => _authNavigationEvents.stream;

 
  static Future<AuthResponse> login(
      String email, String password, BuildContext context) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user?.emailConfirmedAt == null) {
        await _client.auth.signOut();
        throw UserNotVerifiedException(
          'Tu correo aún no está verificado. Por favor revisa tu bandeja de entrada.',
        );
      }

      // Verificar si el usuario está baneado
      try {
        final userData = await _client
            .from('usuarios_app')
            .select('estado')
            .eq('id', response.user!.id)
            .single();
        
        if (userData['estado'] == 'baneado') {
          await _client.auth.signOut();
          throw UserBannedException(
            'Tu cuenta ha sido suspendida. Contacta al administrador para más información.',
          );
        }
      } catch (e) {
        // Si hay un error al verificar el estado, cerrar sesión por seguridad
        await _client.auth.signOut();
        throw Exception('Error verificando el estado de la cuenta. Intenta nuevamente.');
      }

      // Registrar actividad de login
      try {
        // Obtener el provider de ActivityLoggerService usando un ProviderContainer temporal
        final container = ProviderContainer();
        final activityLogger = container.read(ActivityLoggerService.provider);
        await activityLogger.logLogin();
        container.dispose();
      } catch (e) {
        print('Error registrando actividad de login: $e');
      }

      _authNavigationEvents.add(AuthChangeEvent.signedIn);
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      if (context.mounted) {
        UIErrorHandler.showError(
          context,
          e,
          displayType: ErrorDisplayType.snackBar,
        );
      }
      rethrow;
    }
  }

  static Future<AuthResponse> register(String email, String password) async {
    try {
      debugPrint('AuthService: Registrando usuario: $email');
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      debugPrint('AuthService: Registro respuesta: user: $user');

      if (user != null) {
        await _client.from('usuarios_app').upsert({
          'id': user.id,
          'email': user.email,
        }, onConflict: 'email');
        debugPrint('AuthService: Usuario insertado o actualizado en usuarios_app');
        // Resetear tutorial solo si el usuario registrado es el autenticado actual
        final currentUser = _client.auth.currentUser;
        if (currentUser != null && currentUser.email == email) {
          await Future.delayed(const Duration(milliseconds: 200)); // Espera breve por si el login es asíncrono
          await Future.microtask(() async {
            // Importa el servicio si no está importado
            // import 'package:mamapola_app_v1/services/tutorial_service.dart';
            await TutorialService.resetTutorial();
          });
        }
      }
      // Después de un registro exitoso, podrías emitir un evento.
      _authNavigationEvents.add(AuthChangeEvent.signedIn); // O .signedUp
      return response;
    } on AuthException catch (e) {
      debugPrint('AuthException en register: ${e.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('Error inesperado en register: $e');
      debugPrint('StackTrace: $st');
      throw Exception('Error en el registro: ${e.toString()}');
    }
  }

  static Future<void> logout(BuildContext context) async {
    try {
      // Registrar actividad de logout antes de cerrar sesión
      try {
        final container = ProviderContainer();
        final activityLogger = container.read(ActivityLoggerService.provider);
        await activityLogger.logLogout();
        container.dispose();
      } catch (e) {
        print('Error registrando actividad de logout: $e');
      }

      await _client.auth.signOut();
      // Emite un evento de cierre de sesión si se mantiene el StreamController
      _authNavigationEvents.add(AuthChangeEvent.signedOut);
    } on AuthException catch (e) {
      if (context.mounted) {
        UIErrorHandler.showError(
          context,
          e,
          displayType: ErrorDisplayType.snackBar,
        );
      }
      rethrow;
    } catch (e) {
      if (context.mounted) {
        UIErrorHandler.showError(
          context,
          e,
          displayType: ErrorDisplayType.snackBar,
        );
      }
      rethrow;
    }
  }

  static User? get currentUser => _client.auth.currentUser;

  // Esta función ahora solo es llamada explícitamente cuando sea necesario.
  static Future<bool> isCurrentUserValid(BuildContext context) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return false;

      final response = await _client.auth.getUser();
      return response.user != null;
    } on AuthException catch (e) {
      debugPrint('AuthException en isCurrentUserValid: ${e.message}');

      return false;
    } catch (e) {
      debugPrint('Error inesperado en isCurrentUserValid: $e');
      return false;
    }
  }

  /// Verifica si el usuario actual está baneado
  static Future<bool> isCurrentUserBanned() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      final userData = await _client
          .from('usuarios_app')
          .select('estado')
          .eq('id', currentUser.id)
          .single();
      
      return userData['estado'] == 'baneado';
    } catch (e) {
      print('Error verificando si el usuario está baneado: $e');
      return false;
    }
  }

  /// Verifica si el usuario actual está activo
  static Future<bool> isCurrentUserActive() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      final userData = await _client
          .from('usuarios_app')
          .select('estado')
          .eq('id', currentUser.id)
          .single();
      
      return userData['estado'] == 'activo';
    } catch (e) {
      print('Error verificando si el usuario está activo: $e');
      return false;
    }
  }

  static void dispose() {
    _authNavigationEvents.close(); // Importante cerrar el stream si se usa
  }
}