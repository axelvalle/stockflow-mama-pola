import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:mamapola_app_v1/logic/auth/auth_service.dart';
import 'package:mamapola_app_v1/logic/auth/password_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpResult {
  final bool needsVerification;
  final String email;

  SignUpResult({
    required this.needsVerification,
    required this.email,
  });
}

class SignUpState {
  final bool isLoading;
  final bool obscurePassword;
  final double passwordStrength;

  SignUpState({
    this.isLoading = false,
    this.obscurePassword = true,
    this.passwordStrength = 0.0,
  });

  SignUpState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    double? passwordStrength,
  }) {
    return SignUpState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      passwordStrength: passwordStrength ?? this.passwordStrength,
    );
  }
}

class SignUpController extends StateNotifier<SignUpState> {
  SignUpController() : super(SignUpState());

  void toggleObscurePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void updatePasswordStrength(String password) {
    final strength = PasswordUtils.calcularFuerza(password);
    state = state.copyWith(passwordStrength: strength);
  }

  void resetState() {
    state = SignUpState();
  }

  Future<bool> _emailExistsInUsuariosApp(String email) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('usuarios_app')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    return response != null;
  }

  Future<SignUpResult?> registerUser(GlobalKey<FormBuilderState> formKey) async {
    if (!(formKey.currentState?.saveAndValidate() ?? false)) return null;

    state = state.copyWith(isLoading: true);

    final email = formKey.currentState!.fields['email']!.value as String;
    final password = formKey.currentState!.fields['password']!.value as String;

    final allowedDomains = [
      'gmail.com',
      'outlook.com',
      'yahoo.com',
      'hotmail.com',
      'live.com',
      'protonmail.com',
    ];

    final emailDomain = email.split('@').last.toLowerCase();

    if (!allowedDomains.contains(emailDomain)) {
      state = state.copyWith(isLoading: false);
      throw AuthException(
        'Solo se permiten correos con dominios confiables: gmail, outlook, yahoo, hotmail, live, protonmail.',
      );
    }

    try {
      final existsInUsuariosApp = await _emailExistsInUsuariosApp(email);

      if (existsInUsuariosApp) {
        state = state.copyWith(isLoading: false);
        throw AuthException('El correo electrónico ya está registrado.');
      }

      final AuthResponse response = await AuthService.register(email, password);
      final user = response.user;

      if (user != null) {
        final needsVerification = user.emailConfirmedAt == null;
        return SignUpResult(
          needsVerification: needsVerification,
          email: email,
        );
      } else {
        throw AuthException('El registro falló por razones desconocidas.');
      }
    } on AuthException catch (e) {
      debugPrint('AuthException atrapada en controller: ${e.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('Error inesperado en controller registerUser: $e');
      debugPrint('StackTrace: $st');
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final signUpControllerProvider =
    StateNotifierProvider<SignUpController, SignUpState>((ref) {
  return SignUpController();
});
