import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/logic/auth/password_util.dart';
import 'package:mamapola_app_v1/logic/auth/signup_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/logic/injection/theme_provider.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isPasswordFocused = false;
  bool _passwordHasText = false;

  @override
  void initState() {
    super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(signUpControllerProvider.notifier).resetState();
    });

    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }


  Future<void> _handleRegistration() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(signUpControllerProvider.notifier).registerUser(_formKey);

      if (!mounted) return;

      if (result != null && result.needsVerification) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Verifica tu correo'),
            content: Text(
              'Te hemos enviado un enlace de verificación a ${result.email}. '
              'Por favor, verifica tu correo para continuar.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      } else if (result != null) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      final errorStr = e.message.toLowerCase();

      if (errorStr.contains('already registered') ||
          errorStr.contains('user already exists') ||
          errorStr.contains('email already in use') ||
          errorStr.contains('ya está registrado')) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Cuenta existente'),
            content: const Text(
              'Este correo ya está registrado. ¿Quieres iniciar sesión o regresar?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Iniciar sesión'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _formKey.currentState?.fields['email']?.reset();
                  _formKey.currentState?.fields['password']?.reset();
                },
                child: const Text('Regresar'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en el registro: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkTheme = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Registro'),
        actions: [
          Row(
            children: [
              Icon(isDarkTheme ? Icons.dark_mode : Icons.light_mode),
              Switch(
                value: isDarkTheme,
                onChanged: (_) => toggleTheme(ref),
                activeColor: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.local_florist,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                "¡Bienvenid@ a Mamá Pola !",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Crea tu cuenta para empezar a disfrutar 🌸",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 30),
              FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    FormBuilderTextField(
                      name: 'email',
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: 'Requerido'),
                        FormBuilderValidators.email(errorText: 'Correo inválido'),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    FormBuilderTextField(
                      name: 'password',
                      focusNode: _passwordFocusNode,
                      obscureText: state.obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            state.obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          tooltip: state.obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                          onPressed: ref.read(signUpControllerProvider.notifier).toggleObscurePassword,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: PasswordUtils.validarPasswordSegura,
                      onChanged: (val) {
                        final value = val ?? '';
                        ref.read(signUpControllerProvider.notifier).updatePasswordStrength(value);
                        setState(() {
                          _passwordHasText = value.isNotEmpty;
                        });
                      },
                    ),
                    if (_isPasswordFocused && _passwordHasText) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: state.passwordStrength,
                              color: PasswordUtils.obtenerColor(state.passwordStrength),
                              backgroundColor: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            PasswordUtils.obtenerEtiqueta(state.passwordStrength),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: PasswordUtils.obtenerColor(state.passwordStrength),
                                ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegistration,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Registrarse", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                      child: Text(
                        "¿Ya tienes una cuenta? Inicia sesión",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
