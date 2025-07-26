// view/user/user_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/logic/auth/auth_service.dart';
import 'package:mamapola_app_v1/logic/user/user_controller.dart';
import 'package:mamapola_app_v1/logic/utils/role_manager.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userControllerProvider.notifier).loadUsers();
    });
  }

  Future<void> _refresh() async {
    await ref.read(userControllerProvider.notifier).loadUsers();
  }

  Future<bool> _isCurrentUserAdmin() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;
    try {
      final userData = await Supabase.instance.client
          .from('usuarios_app')
          .select('rol')
          .eq('id', currentUser.id)
          .single();
      return RoleManager.isAdmin(userData['rol']);
    } catch (e) {
      if (context.mounted) {
        UIErrorHandler.showError(
          context,
          e,
          displayType: ErrorDisplayType.snackBar,
          customTitle: 'Error verificando permisos',
        );
      }
      return false;
    }
  }

  // Verifica si hay usuarios no administradores activos
  Future<bool> _hasActiveNonAdminUsers() async {
    try {
      final threshold = DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
      final activeUsers = await Supabase.instance.client
          .from('usuarios_app')
          .select('id, rol')
          .neq('rol', 'admin') // Suponiendo que 'admin' es el rol de administrador
          .gte('last_active', threshold); // Usuarios activos en los últimos 5 minutos
      return activeUsers.isNotEmpty;
    } catch (e) {
      if (context.mounted) {
        UIErrorHandler.showError(
          context,
          e,
          displayType: ErrorDisplayType.snackBar,
          customTitle: 'Error verificando usuarios activos',
        );
      }
      return true; // En caso de error, asumimos que hay usuarios activos para ser conservadores
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Refrescar lista',
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading ? null : _refresh,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'user_management':
                  Navigator.pushNamed(context, '/user_management');
                  break;
                case 'user_profile':
                  Navigator.pushNamed(context, '/user_profile');
                  break;
                case 'user_activity_log':
                  Navigator.pushNamed(context, '/user_activity_log');
                  break;

              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'user_management',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings),
                    SizedBox(width: 8),
                    Text('Gestión de Usuarios'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'user_profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'user_activity_log',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Historial de Actividad'),
                  ],
                ),
              ),

            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.users.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          "No hay usuarios registrados.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        final user = state.users[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.teal.shade300,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              user['email'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Rol: ${RoleManager.getRoleDisplayName(user['rol'])}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                switch (value) {
                                  case 'view_profile':
                                    // TODO: Navegar al perfil del usuario específico
                                    Navigator.pushNamed(context, '/user_profile');
                                    break;
                                  case 'view_activity':
                                    // TODO: Navegar al historial de actividad del usuario específico
                                    Navigator.pushNamed(context, '/user_activity_log');
                                    break;
                                  case 'login_attempts':
                                    // TODO: Mostrar diálogo con intentos de login del usuario
                                    _showLoginAttemptsDialog(context, user['id']);
                                    break;
                                  case 'change_role':
                                    // TODO: Mostrar diálogo para cambiar rol
                                    _showChangeRoleDialog(context, user);
                                    break;
                                  case 'ban_user':
                                    // TODO: Mostrar diálogo para banear/desbanear
                                    _showBanUserDialog(context, user);
                                    break;
                                  case 'eliminar':
                                  // Validar si el usuario es el usuario actual
                                  final currentUser = AuthService.currentUser;
                                  if (currentUser != null && user['id'] == currentUser.id) {
                                    if (context.mounted) {
                                      UIErrorHandler.showError(
                                        context,
                                        Exception('No puedes eliminar tu propia cuenta'),
                                        displayType: ErrorDisplayType.snackBar,
                                        customTitle: 'Error',
                                      );
                                    }
                                    return;
                                  }

                                  // Verificar si el usuario actual es administrador
                                  if (!await _isCurrentUserAdmin()) {
                                    if (context.mounted) {
                                      UIErrorHandler.showError(
                                        context,
                                        Exception('Solo los administradores pueden eliminar usuarios'),
                                        displayType: ErrorDisplayType.snackBar,
                                      );
                                    }
                                    return;
                                  }

                                  // Validar si el usuario a eliminar es administrador y hay usuarios no administradores activos
                                  if (RoleManager.isAdmin(user['rol']) && await _hasActiveNonAdminUsers()) {
                                    if (context.mounted) {
                                      UIErrorHandler.showError(
                                        context,
                                        Exception('No se puede eliminar un administrador mientras hay usuarios activos'),
                                        displayType: ErrorDisplayType.snackBar,
                                        customTitle: 'Error',
                                      );
                                    }
                                    return;
                                  }

                                  // Confirmación de eliminación
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('¿Eliminar usuario?'),
                                      content: const Text('Esta acción no se puede deshacer.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await ref
                                          .read(userControllerProvider.notifier)
                                          .deleteUser(user['id']);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Usuario eliminado correctamente')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        UIErrorHandler.showError(
                                          context,
                                          e,
                                          displayType: ErrorDisplayType.snackBar,
                                          customTitle: 'Error al eliminar usuario',
                                        );
                                      }
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view_profile',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person),
                                      SizedBox(width: 8),
                                      Text('Ver Perfil'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'view_activity',
                                  child: Row(
                                    children: [
                                      Icon(Icons.history),
                                      SizedBox(width: 8),
                                      Text('Ver Actividad'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'login_attempts',
                                  child: Row(
                                    children: [
                                      Icon(Icons.security),
                                      SizedBox(width: 8),
                                      Text('Intentos de Login'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'change_role',
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings),
                                      SizedBox(width: 8),
                                      Text('Cambiar Rol'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'ban_user',
                                  child: Row(
                                    children: [
                                      Icon(Icons.block),
                                      SizedBox(width: 8),
                                      Text('Banear/Desbanear'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'eliminar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete),
                                      SizedBox(width: 8),
                                      Text('Eliminar'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Agregar nuevo usuario',
        onPressed: () {
          Navigator.pushNamed(context, '/signup');
        },
        icon: const Icon(Icons.add),
        label: const Text("Nuevo"),
      ),
    );
  }

  void _showLoginAttemptsDialog(BuildContext context, String userId) {
    // TODO: Implementar diálogo para mostrar intentos de login
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Intentos de Login'),
        content: const Text('Funcionalidad en desarrollo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, Map<String, dynamic> user) {
    // TODO: Implementar diálogo para cambiar rol
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Rol'),
        content: const Text('Funcionalidad en desarrollo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showBanUserDialog(BuildContext context, Map<String, dynamic> user) {
    // TODO: Implementar diálogo para banear/desbanear usuario
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Banear/Desbanear Usuario'),
        content: const Text('Funcionalidad en desarrollo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}