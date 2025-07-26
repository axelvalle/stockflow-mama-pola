import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/logic/auth/password_util.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? token;
  final String? email;
  const ResetPasswordPage({super.key, this.token, this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  double _passwordStrength = 0.0;
  bool _passwordHasText = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final newPassword = _passwordController.text.trim();
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¡Contraseña restablecida!'),
          content: const Text('Tu contraseña ha sido cambiada exitosamente. Ahora puedes iniciar sesión.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() { _error = 'No se pudo restablecer la contraseña. Intenta nuevamente.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ingresa tu nueva contraseña para la cuenta:', textAlign: TextAlign.center),
                if (widget.email != null) ...[
                  const SizedBox(height: 8),
                  Text(widget.email!, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: PasswordUtils.validarPasswordSegura,
                  onChanged: (val) {
                    final value = val;
                    setState(() {
                      _passwordStrength = PasswordUtils.calcularFuerza(value);
                      _passwordHasText = value.isNotEmpty;
                    });
                  },
                ),
                if (_passwordHasText) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _passwordStrength,
                          color: PasswordUtils.obtenerColor(_passwordStrength),
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        PasswordUtils.obtenerEtiqueta(_passwordStrength),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: PasswordUtils.obtenerColor(_passwordStrength),
                            ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Restablecer contraseña'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 