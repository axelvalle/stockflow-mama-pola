import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/user/user_activity_controller.dart';
import '../../logic/auth/auth_service.dart';
import '../../logic/utils/role_manager.dart';

class UserActivityLogPage extends ConsumerStatefulWidget {
  const UserActivityLogPage({super.key});

  @override
  ConsumerState<UserActivityLogPage> createState() => _UserActivityLogPageState();
}

class _UserActivityLogPageState extends ConsumerState<UserActivityLogPage> {
  bool _isAdmin = false;
  bool _isLoading = true;
  String? selectedActionType;
  String? selectedUser;
  DateTime? selectedDate;
  String searchQuery = '';
  String _sortBy = 'createdAt';
  bool _sortAsc = false;

  final List<String> actionTypes = [
    'login',
    'logout',
    'password_change',
    'profile_update',
    '2fa_toggle',
    'user_created',
    'user_updated',
    'user_deleted',
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
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
          // Cargar historial de actividad solo si es admin
          await ref.read(userActivityControllerProvider.notifier).loadAllActivityLog();
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

  List<dynamic> get filteredActivities {
    final activities = ref.read(userActivityControllerProvider).allActivityLog;
    List<dynamic> filtered = activities.where((activity) {
      final matchesActionType = selectedActionType == null || activity.actionType == selectedActionType;
      final matchesUser = selectedUser == null || activity.userId == selectedUser;
      final matchesDate = selectedDate == null || 
          (activity.createdAt != null && 
           activity.createdAt!.year == selectedDate!.year &&
           activity.createdAt!.month == selectedDate!.month &&
           activity.createdAt!.day == selectedDate!.day);
      final matchesSearch = searchQuery.isEmpty || 
          (activity.actionType.toLowerCase().contains(searchQuery.toLowerCase())) ||
          (activity.actionDetails?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      return matchesActionType && matchesUser && matchesDate && matchesSearch;
    }).toList();

    // Ordenamiento
    filtered.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'userId':
          cmp = (a.userId ?? '').compareTo(b.userId ?? '');
          break;
        case 'actionType':
          cmp = (a.actionType ?? '').compareTo(b.actionType ?? '');
          break;
        case 'createdAt':
        default:
          cmp = (a.createdAt ?? DateTime(1970)).compareTo(b.createdAt ?? DateTime(1970));
          break;
      }
      return _sortAsc ? cmp : -cmp;
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(userActivityControllerProvider);

    if (_isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Historial de Actividad'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
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
                'Solo los administradores pueden ver el historial de actividad.',
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
      appBar: AppBar(
        title: const Text('Historial de Actividad'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(userActivityControllerProvider.notifier).loadAllActivityLog();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filtros y búsqueda
            _buildFiltersSection(),
            const Divider(height: 1),
            
            // Resumen de actividad
            _buildActivitySummary(activityState),
            const Divider(height: 1),
            
            // Lista de actividades
            Expanded(
              child: activityState.isLoading
          ? const Center(child: CircularProgressIndicator())
                  : filteredActivities.isEmpty
                      ? _buildEmptyState()
                      : _buildActivityList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              labelText: 'Buscar actividad',
              hintText: 'Buscar por tipo de acción o detalles...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          
          // Filtros
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de acción',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedActionType,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las acciones'),
                    ),
                    ...actionTypes.map((type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(_getActionTypeDisplayName(type)),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedActionType = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDatePicker(),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(selectedDate != null 
                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                    : 'Seleccionar fecha'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Botón limpiar filtros
          if (selectedActionType != null || selectedDate != null || searchQuery.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    selectedActionType = null;
                    selectedDate = null;
                    searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar filtros'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivitySummary(UserActivityState activityState) {
    final activities = activityState.allActivityLog;
    final totalActivities = activities.length;
    final todayActivities = activities.where((activity) => 
      activity.createdAt != null && 
      activity.createdAt!.isAfter(DateTime.now().subtract(const Duration(days: 1)))
    ).length;
    
    final loginActivities = activities.where((activity) => 
      activity.actionType == 'login'
    ).length;
    
    final logoutActivities = activities.where((activity) => 
      activity.actionType == 'logout'
    ).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Actividad',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total',
                  totalActivities.toString(),
                  Icons.analytics,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Hoy',
                  todayActivities.toString(),
                  Icons.today,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Logins',
                  loginActivities.toString(),
                  Icons.login,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Logouts',
                  logoutActivities.toString(),
                  Icons.logout,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay actividad registrada',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El historial de actividad aparecerá aquí cuando los usuarios realicen acciones en el sistema.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(userActivityControllerProvider.notifier).loadAllActivityLog();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return Column(
      children: [
        // Cabecera de la tabla
        Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSortableHeader('Tipo', 'actionType'),
                _buildSortableHeader('Fecha', 'createdAt'),
                const Spacer(),
                const SizedBox(width: 40), // espacio para menú
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // Lista
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredActivities.length,
            itemBuilder: (context, index) {
              final activity = filteredActivities[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getActionTypeColor(activity.actionType),
                    child: Icon(_getActionTypeIcon(activity.actionType), color: Colors.white),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(_getActionTypeDisplayName(activity.actionType))),
                      Expanded(child: Text(activity.createdAt != null ? _formatDateTime(activity.createdAt!) : '-')),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User Agent: ${activity.userAgent ?? 'auth user'}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'details') {
                        _showActivityDetails(activity);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info),
                            SizedBox(width: 8),
                            Text('Ver detalles'),
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
      ],
    );
  }

  Widget _buildSortableHeader(String label, String sortKey) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            if (_sortBy == sortKey) {
              _sortAsc = !_sortAsc;
            } else {
              _sortBy = sortKey;
              _sortAsc = true;
            }
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_sortBy == sortKey)
              Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((date) {
      if (date != null) {
        setState(() {
          selectedDate = date;
        });
      }
    });
  }

  void _showActivityDetails(dynamic activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getActionTypeDisplayName(activity.actionType)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (activity.createdAt != null)
              Text('Fecha: ${_formatDateTime(activity.createdAt!)}'),
            const SizedBox(height: 8),
            if (activity.userAgent != null)
              Text('User Agent: ${activity.userAgent}'),
            const SizedBox(height: 8),
            if (activity.actionDetails != null)
              Text('Detalles: ${activity.actionDetails.toString()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
                ),
              ],
            ),
    );
  }

  String _getActionTypeDisplayName(String actionType) {
    switch (actionType) {
      case 'login':
        return 'Inicio de sesión';
      case 'logout':
        return 'Cierre de sesión';
      case 'password_change':
        return 'Cambio de contraseña';
      case 'profile_update':
        return 'Actualización de perfil';
      case '2fa_toggle':
        return 'Configuración 2FA';
      case 'user_created':
        return 'Usuario creado';
      case 'user_updated':
        return 'Usuario actualizado';
      case 'user_deleted':
        return 'Usuario eliminado';
      default:
        return actionType;
    }
  }

  IconData _getActionTypeIcon(String actionType) {
    switch (actionType) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'password_change':
        return Icons.lock;
      case 'profile_update':
        return Icons.person;
      case '2fa_toggle':
        return Icons.security;
      case 'user_created':
        return Icons.person_add;
      case 'user_updated':
        return Icons.edit;
      case 'user_deleted':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Color _getActionTypeColor(String actionType) {
    switch (actionType) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.red;
      case 'password_change':
        return Colors.orange;
      case 'profile_update':
        return Colors.blue;
      case '2fa_toggle':
        return Colors.purple;
      case 'user_created':
        return Colors.teal;
      case 'user_updated':
        return Colors.indigo;
      case 'user_deleted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 