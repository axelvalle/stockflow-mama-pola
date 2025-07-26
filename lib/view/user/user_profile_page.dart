import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../logic/user/user_controller.dart';
import '../../logic/user/user_2fa_controller.dart';
import '../../logic/auth/auth_service.dart';
import '../../logic/auth/password_util.dart';
import '../../logic/utils/role_manager.dart';
import '../../model/exceptions/ui_errorhandle.dart';
import '../../services/activity_logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _2FACodeController = TextEditingController();
  final _backupCodeController = TextEditingController();
  final _changePasswordFormKey = GlobalKey<FormBuilderState>();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  double _passwordStrength = 0.0;
  bool _isPasswordFocused = false;
  bool _passwordHasText = false;

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar modificar providers durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _2FACodeController.dispose();
    _backupCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      // Cargar datos del usuario actual
      await ref.read(userControllerProvider.notifier).loadUsers();
      
      // Cargar configuración 2FA
      await ref.read(user2FAControllerProvider.notifier).loadUser2FAConfig(currentUser.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Providers
    final userState = ref.watch(userControllerProvider);
    final user2FAState = ref.watch(user2FAControllerProvider);

    // Obtener el usuario actual
    final currentUser = AuthService.currentUser;
    final user = userState.users.isNotEmpty 
        ? userState.users.firstWhere(
            (u) => u['id'] == currentUser?.id,
            orElse: () => userState.users.first,
          )
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de Usuario')),
      body: SafeArea(
        child: user == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica
                    _buildBasicInfoSection(context, user),
                    const Divider(),
                    
                    // Cambiar contraseña
                    _buildPasswordSection(context),
                    const Divider(),
                    
                    // 2FA
                    _build2FASection(context, user2FAState),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, Map<String, dynamic>? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Información básica', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary),
            ),
            title: Text(user?['email'] ?? 'No disponible'),
            subtitle: Text('Rol: ${RoleManager.getRoleDisplayName(user?['rol'] ?? 'user')} | Estado: ${user?['estado'] ?? 'activo'}'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cambiar contraseña', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
            title: const Text('Cambiar contraseña'),
            subtitle: const Text('Actualiza tu contraseña de acceso'),
            trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.primary),
            onTap: () => _showChangePasswordDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _build2FASection(BuildContext context, User2FAState user2FAState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Autenticación de dos factores (2FA)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(
              user2FAState.is2FAEnabled ? Icons.security : Icons.security_outlined,
              color: user2FAState.is2FAEnabled 
                  ? Colors.green 
                  : Theme.of(context).colorScheme.primary,
            ),
            title: Text(user2FAState.is2FAEnabled ? '2FA Activado' : '2FA Desactivado'),
            subtitle: Text(user2FAState.is2FAEnabled 
                ? 'Tu cuenta está protegida con autenticación de dos factores'
                : 'Activa la autenticación de dos factores para mayor seguridad'),
            trailing: Switch(
              value: user2FAState.is2FAEnabled,
              onChanged: (value) {
                if (value) {
                  _showEnable2FADialog(context);
                } else {
                  _showDisable2FADialog(context);
                }
              },
            ),
          ),
        ),
        if (user2FAState.is2FAEnabled) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showBackupCodesDialog(context),
                  icon: const Icon(Icons.backup),
                  label: const Text('Códigos de Respaldo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showNewBackupCodesDialog(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Nuevos Códigos'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Métodos de funcionalidad
  void _showChangePasswordDialog(BuildContext context) {
    // Resetear el formulario
    _changePasswordFormKey.currentState?.reset();
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _obscureCurrentPassword = true;
      _obscureNewPassword = true;
      _obscureConfirmPassword = true;
      _passwordStrength = 0.0;
      _isPasswordFocused = false;
      _passwordHasText = false;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: SizedBox(
            width: double.maxFinite,
            child: FormBuilder(
              key: _changePasswordFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormBuilderTextField(
                    name: 'currentPassword',
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña actual',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setStateDialog(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'La contraseña actual es obligatoria'),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'newPassword',
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setStateDialog(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: PasswordUtils.validarPasswordSegura,
                    onChanged: (val) {
                      final value = val ?? '';
                      setStateDialog(() {
                        _passwordStrength = PasswordUtils.calcularFuerza(value);
                        _passwordHasText = value.isNotEmpty;
                      });
                    },
                    onTap: () {
                      setStateDialog(() {
                        _isPasswordFocused = true;
                      });
                    },
                  ),
                  if (_isPasswordFocused && _passwordHasText) ...[
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
                  FormBuilderTextField(
                    name: 'confirmPassword',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setStateDialog(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma tu nueva contraseña';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _changePassword(context),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    // Validar el formulario
    if (!(_changePasswordFormKey.currentState?.saveAndValidate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrige los errores en el formulario'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validaciones adicionales
    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña actual es obligatoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La nueva contraseña es obligatoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que la nueva contraseña sea diferente a la actual
    if (currentPassword == newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La nueva contraseña debe ser diferente a la actual'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        // Cambiar contraseña usando Supabase Auth
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            password: newPassword,
          ),
        );

        // Registrar actividad de cambio de contraseña
        try {
          final activityLogger = ref.read(ActivityLoggerService.provider);
          await activityLogger.logPasswordChange();
        } catch (e) {
          print('Error registrando actividad de cambio de contraseña: $e');
        }

        // Limpiar el formulario
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _changePasswordFormKey.currentState?.reset();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contraseña cambiada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al cambiar la contraseña';
        
        if (e.toString().contains('Invalid login credentials')) {
          errorMessage = 'La contraseña actual es incorrecta';
        } else if (e.toString().contains('Password should be at least')) {
          errorMessage = 'La nueva contraseña no cumple con los requisitos de seguridad';
        } else if (e.toString().contains('Too many requests')) {
          errorMessage = 'Demasiados intentos. Intenta más tarde';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEnable2FADialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activar 2FA'),
        content: const Text('¿Estás seguro de que quieres activar la autenticación de dos factores?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _enable2FA(context),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }

  Future<void> _enable2FA(BuildContext context) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        await ref.read(user2FAControllerProvider.notifier).enable2FA(
          currentUser.id,
          currentUser.email ?? '',
        );
        
        // Registrar actividad de activación de 2FA
        try {
          final activityLogger = ref.read(ActivityLoggerService.provider);
          await activityLogger.log2FAToggle(true);
        } catch (e) {
          print('Error registrando actividad de activación 2FA: $e');
        }
        
        Navigator.pop(context);
        _showQRCodeDialog(context);
      }
    } catch (e) {
      UIErrorHandler.showError(context, e);
    }
  }

  void _showQRCodeDialog(BuildContext context) {
    final user2FAState = ref.read(user2FAControllerProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar 2FA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escanea este código QR con tu aplicación de autenticación:'),
            const SizedBox(height: 16),
            // TODO: Mostrar QR code
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('QR Code\n(Implementar)'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Códigos de respaldo:'),
            const SizedBox(height: 8),
            if (user2FAState.backupCodes != null)
              ...user2FAState.backupCodes!.map((code) => Text(code)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showDisable2FADialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar 2FA'),
        content: const Text('¿Estás seguro de que quieres desactivar la autenticación de dos factores?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _disable2FA(context),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _disable2FA(BuildContext context) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        await ref.read(user2FAControllerProvider.notifier).disable2FA(currentUser.id);
        
        // Registrar actividad de desactivación de 2FA
        try {
          final activityLogger = ref.read(ActivityLoggerService.provider);
          await activityLogger.log2FAToggle(false);
        } catch (e) {
          print('Error registrando actividad de desactivación 2FA: $e');
        }
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA desactivado exitosamente')),
        );
      }
    } catch (e) {
      UIErrorHandler.showError(context, e);
    }
  }

  void _showBackupCodesDialog(BuildContext context) {
    final user2FAState = ref.read(user2FAControllerProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Códigos de Respaldo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Guarda estos códigos en un lugar seguro:'),
            const SizedBox(height: 16),
            if (user2FAState.backupCodes != null)
              ...user2FAState.backupCodes!.map((code) => Text(code)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showNewBackupCodesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar nuevos códigos'),
        content: const Text('¿Estás seguro? Los códigos actuales dejarán de funcionar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _generateNewBackupCodes(context),
            child: const Text('Generar'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateNewBackupCodes(BuildContext context) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        Navigator.pop(context);
        _showBackupCodesDialog(context);
      }
    } catch (e) {
      UIErrorHandler.showError(context, e);
    }
  }
} 