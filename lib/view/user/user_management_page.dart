import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/user/user_controller.dart';
import '../../logic/utils/role_manager.dart';
import '../../model/exceptions/ui_errorhandle.dart';
import '../../logic/auth/auth_service.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  String? selectedRole;
  String? selectedStatus;
  String searchQuery = '';
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar modificar providers durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserRole();
    });
  }

  Future<void> _checkUserRole() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        final userData = await Supabase.instance.client
            .from('usuarios_app')
            .select('rol')
            .eq('id', currentUser.id)
            .single();
        
        setState(() {
          _isAdmin = RoleManager.isAdmin(userData['rol']);
          _isLoading = false;
        });

        if (_isAdmin) {
          await _loadUsers();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error verificando rol del usuario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    await ref.read(userControllerProvider.notifier).loadUsers();
  }

  List<Map<String, dynamic>> get filteredUsers {
    final users = ref.read(userControllerProvider).users;
    return users.where((user) {
      final matchesRole = selectedRole == null || user['rol'] == selectedRole;
      final matchesStatus = selectedStatus == null || user['estado'] == selectedStatus;
      final matchesSearch = searchQuery.isEmpty || 
          (user['email']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (user['nombre']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      return matchesRole && matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userControllerProvider);

    if (_isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de Usuarios')),
        body: const SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Acceso Denegado',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Solo los administradores pueden gestionar usuarios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      body: SafeArea(
        child: userState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
              children: [
                // Filtros por rol y estado
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Barra de búsqueda
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Buscar usuarios',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      // Filtros
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Filtrar por rol',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedRole,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Todos los roles'),
                                ),
                                DropdownMenuItem<String>(
                                  value: RoleManager.adminRole,
                                  child: Text(RoleManager.getRoleDisplayName(RoleManager.adminRole)),
                                ),
                                DropdownMenuItem<String>(
                                  value: RoleManager.userRole,
                                  child: Text(RoleManager.getRoleDisplayName(RoleManager.userRole)),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedRole = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Filtrar por estado',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedStatus,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Todos los estados'),
                                ),
                                const DropdownMenuItem<String>(
                                  value: 'activo',
                                  child: Text('Activo'),
                                ),
                                const DropdownMenuItem<String>(
                                  value: 'inactivo',
                                  child: Text('Inactivo'),
                                ),
                                const DropdownMenuItem<String>(
                                  value: 'baneado',
                                  child: Text('Baneado'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedStatus = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Lista de usuarios
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return ListTile(
                        title: Text(ocultarDominioCorreo(user['email'])),
                        subtitle: Text('Rol: ${user['rol']} | Estado: ${user['estado']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.admin_panel_settings),
                              tooltip: 'Cambiar rol',
                              onPressed: () => _showChangeRoleDialog(context, user),
                            ),
                            IconButton(
                              icon: Icon(
                                user['estado'] == 'baneado' ? Icons.person_add : Icons.block,
                                color: user['estado'] == 'baneado' ? Colors.green : Colors.red,
                              ),
                              tooltip: user['estado'] == 'baneado' ? 'Desbanear' : 'Banear',
                              onPressed: () => _showBanUserDialog(context, user),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                switch (value) {
                                  case 'profile':
                                    _showUserProfile(context, user);
                                    break;
                                  case 'delete':
                                    _showDeleteUserDialog(context, user);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem<String>(
                                  value: 'profile',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person),
                                      SizedBox(width: 8),
                                      Text('Ver perfil'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, Map<String, dynamic> user) {
    String? newRole = user['rol'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar rol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Usuario: ${ocultarDominioCorreo(user['email'])}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Nuevo rol',
                border: OutlineInputBorder(),
              ),
              value: newRole,
              items: [
                DropdownMenuItem<String>(
                  value: RoleManager.userRole,
                  child: Text(RoleManager.getRoleDisplayName(RoleManager.userRole)),
                ),
                DropdownMenuItem<String>(
                  value: RoleManager.adminRole,
                  child: Text(RoleManager.getRoleDisplayName(RoleManager.adminRole)),
                ),
              ],
              onChanged: (value) {
                newRole = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newRole != null && newRole != user['rol']) {
                try {
                  await ref.read(userControllerProvider.notifier).updateUserRole(user['id'], newRole!);
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rol actualizado correctamente')),
                  );
                } catch (e) {
                  UIErrorHandler.showError(context, e);
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _showBanUserDialog(BuildContext context, Map<String, dynamic> user) {
    final isBanned = user['estado'] == 'baneado';
    final action = isBanned ? 'desbanear' : 'banear';
    final title = isBanned ? 'Desbanear usuario' : 'Banear usuario';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('¿Estás seguro de que quieres $action al usuario ${ocultarDominioCorreo(user['email'])}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final newStatus = isBanned ? 'activo' : 'baneado';
                await ref.read(userControllerProvider.notifier).updateUserStatus(user['id'], newStatus);
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Usuario ${isBanned ? 'desbaneado' : 'baneado'} correctamente')),
                );
              } catch (e) {
                UIErrorHandler.showError(context, e);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isBanned ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isBanned ? 'Desbanear' : 'Banear'),
          ),
        ],
      ),
    );
  }

  void _showUserProfile(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perfil de usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${ocultarDominioCorreo(user['email'])}'),
            const SizedBox(height: 8),
            Text('Nombre: ${user['nombre'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Teléfono: ${user['telefono'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Rol: ${RoleManager.getRoleDisplayName(user['rol'])}'),
            const SizedBox(height: 8),
            Text('Estado: ${user['estado'] ?? 'activo'}'),
            const SizedBox(height: 8),
            Text('Fecha de creación: ${_formatDateTime(user['created_at'] != null ? DateTime.parse(user['created_at']) : null)}'),
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

  void _showDeleteUserDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Estás seguro de que quieres eliminar al usuario ${ocultarDominioCorreo(user['email'])}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(userControllerProvider.notifier).deleteUser(user['id']);
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuario eliminado correctamente')),
                );
              } catch (e) {
                UIErrorHandler.showError(context, e);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  // Función para ocultar el dominio del correo
  String ocultarDominioCorreo(String? email) {
    if (email == null) return '';
    final parts = email.split('@');
    return parts.isNotEmpty ? parts.first : email;
  }
} 