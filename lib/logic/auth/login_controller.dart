import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:mamapola_app_v1/logic/auth/auth_service.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginState {
  final bool isLoading;
  final bool obscurePassword;

  const LoginState({
    this.isLoading = false,
    this.obscurePassword = true,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? obscurePassword,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  LoginController() : super(const LoginState());

  final supabase = Supabase.instance.client;

  void toggleObscurePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void resetState() {
    state = const LoginState();
  }

  Future<void> login(GlobalKey<FormBuilderState> formKey, BuildContext context) async {
    if (state.isLoading) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    formKey.currentState?.save();
    state = state.copyWith(isLoading: true);

    final email = formKey.currentState?.fields['email']?.value as String?;
    final password = formKey.currentState?.fields['password']?.value as String?;

    if (email == null || password == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      // Paso 1: Verificar si el usuario existe en auth.users
      try {
        final authResponse = await AuthService.login(email,password,context);
        final userId = authResponse.user?.id;

        if (userId == null) {
          throw Exception('No se pudo obtener el ID del usuario.');
        }

        // Verificar si el usuario está bloqueado
        final attemptResponse = await supabase
            .from('login_attempts')
            .select('attempts, is_blocked')
            .eq('user_id', userId)
            .maybeSingle();

        bool isBlocked = attemptResponse?['is_blocked'] ?? false;
        // ignore: unused_local_variable
        int currentAttempts = attemptResponse?['attempts'] ?? 0;

        if (isBlocked) {
          await AuthService.logout(context); // Cerrar sesión para evitar estado inconsistente
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Su usuario está bloqueado. Contacte al administrador.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          state = state.copyWith(isLoading: false);
          return;
        }

        // Verificar si el correo está confirmado
        if (authResponse.user?.emailConfirmedAt == null) {
          await AuthService.logout(context);
          throw UserNotVerifiedException(
            'Tu correo aún no está verificado. Por favor revisa tu bandeja de entrada.',
          );
        }

        // Login exitoso: resetear intentos fallidos
        if (attemptResponse != null) {
          await supabase.from('login_attempts').update({
            'attempts': 0,
            'last_attempt': DateTime.now().toIso8601String(),
            'is_blocked': false,
          }).eq('user_id', userId);
        } else {
          // Crear registro si no existe
          await supabase.from('login_attempts').insert({
            'user_id': userId,
            'attempts': 0,
            'last_attempt': DateTime.now().toIso8601String(),
            'is_blocked': false,
          });
        }

        if (!context.mounted) return;
        resetState(); 
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } catch (authError) {
        debugPrint('Error de autenticación: $authError');

        // Manejar error de credenciales inválidas
        if (authError.toString().toLowerCase().contains('correo o contraseña incorrectos') ||
            authError.toString().toLowerCase().contains('invalid login credentials')) {
          // Obtener user_id desde usuarios_app si es necesario
          final userResponse = await supabase
              .from('usuarios_app')
              .select('id')
              .eq('email', email)
              .maybeSingle();

          if (userResponse == null) {
            throw Exception('Usuario no encontrado.');
          }

          final userId = userResponse['id'] as String;

          // Obtener intentos actuales
          final attemptResponse = await supabase
              .from('login_attempts')
              .select('attempts, is_blocked')
              .eq('user_id', userId)
              .maybeSingle();

          int currentAttempts = (attemptResponse?['attempts'] ?? 0) + 1;

          // Actualizar o crear registro en login_attempts
          if (attemptResponse == null) {
            await supabase.from('login_attempts').insert({
              'user_id': userId,
              'attempts': currentAttempts,
              'last_attempt': DateTime.now().toIso8601String(),
              'is_blocked': currentAttempts >= 3,
            });
          } else {
            await supabase.from('login_attempts').update({
              'attempts': currentAttempts,
              'last_attempt': DateTime.now().toIso8601String(),
              'is_blocked': currentAttempts >= 3,
            }).eq('user_id', userId);
          }

          // Mostrar mensajes según el número de intentos
          if (currentAttempts == 3 && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Advertencia: Su usuario será bloqueado en el próximo intento fallido.'),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (currentAttempts > 3 && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Su usuario ha sido bloqueado. Contacte al administrador.'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Correo o contraseña incorrectos. Intento $currentAttempts de 3.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (authError is UserBannedException) {
          // Manejar usuario baneado específicamente
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authError.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } else if (authError is UserNotVerifiedException) {
          // Manejar usuario no verificado específicamente
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authError.message),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } else {
          // Otros errores de autenticación
          if (context.mounted) {
            UIErrorHandler.showError(context, authError);
          }
        }
      }
    } catch (error) {
      debugPrint('Error general: $error');
      if (context.mounted) {
        UIErrorHandler.showError(context, error);
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

extension FormBuilderStateExtension on FormBuilderState? {
  Map<String, FormBuilderFieldState>? get fields => this?.fields;
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController();
});