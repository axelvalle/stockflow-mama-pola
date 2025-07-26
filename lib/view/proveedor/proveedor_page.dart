
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/logic/proveedor/proveedor_controller.dart';
import 'package:mamapola_app_v1/view/proveedor/proveedor_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/logic/utils/role_manager.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';

class ProveedorPage extends ConsumerStatefulWidget {
  const ProveedorPage({super.key});

  @override
  ConsumerState<ProveedorPage> createState() => _ProveedorPageState();
}

class _ProveedorPageState extends ConsumerState<ProveedorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proveedorControllerProvider.notifier).loadProveedores();
    });
  }

  Future<bool> _isCurrentUserAdmin() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
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

  Future<void> _refresh() async {
    await ref.read(proveedorControllerProvider.notifier).loadProveedores();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proveedorControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        centerTitle: true,
        elevation: 2,
        surfaceTintColor: colorScheme.surfaceContainer,
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            tooltip: 'Refrescar lista',
            icon: Icon(Icons.refresh, color: colorScheme.onSurface),
            onPressed: state.isLoading ? null : _refresh,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.proveedores.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          "No hay proveedores registrados.",
                          style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: FutureBuilder<bool>(
                      future: _isCurrentUserAdmin(),
                      builder: (context, snapshot) {
                        final isAdmin = snapshot.hasData && snapshot.data!;
                        return ListView.builder(
                          itemCount: state.proveedores.length,
                          itemBuilder: (context, index) {
                            final proveedor = state.proveedores[index];
                            final persona = proveedor.persona;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              color: colorScheme.surfaceContainer,
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.teal.shade300,
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  '${persona?.primerNombre ?? ''} ${persona?.primerApellido ?? ''}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  persona?.telefono ?? 'Teléfono no disponible',
                                  style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                                ),
                                trailing: isAdmin
                                    ? PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == 'editar') {
                                            final result = await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ProveedorForm(persona: persona),
                                              ),
                                            );
                                            if (result == true) {
                                              await _refresh();
                                            }
                                          } else if (value == 'eliminar') {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                surfaceTintColor: colorScheme.surfaceContainer,
                                                title: const Text('¿Eliminar proveedor?'),
                                                content: const Text('Esta acción no se puede deshacer.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: Text(
                                                      'Cancelar',
                                                      style: TextStyle(color: colorScheme.onSurface),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: colorScheme.error,
                                                      foregroundColor: colorScheme.onError,
                                                    ),
                                                    child: const Text('Eliminar'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true && persona?.idpersona != null) {
                                              Builder(builder: (BuildContext context) {
                                                try {
                                                  print('Eliminando proveedor ${persona!.idpersona}');
                                                  ref
                                                      .read(proveedorControllerProvider.notifier)
                                                      .eliminarProveedor(persona.idpersona!);

                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Text('Proveedor eliminado correctamente'),
                                                      backgroundColor: colorScheme.primary,
                                                      behavior: SnackBarBehavior.floating,
                                                      duration: const Duration(seconds: 3),
                                                    ),
                                                  );

                                                  Future.delayed(const Duration(milliseconds: 500), () {
                                                    _refresh();
                                                  });
                                                } catch (e) {
                                                  print('Error al eliminar proveedor: $e');
                                                  UIErrorHandler.showError(
                                                    context,
                                                    e,
                                                    displayType: ErrorDisplayType.snackBar,
                                                    customTitle: 'Error al eliminar proveedor',
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              });
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(value: 'editar', child: Text('Editar')),
                                          PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                                        ],
                                        color: colorScheme.surfaceContainer,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _isCurrentUserAdmin(),
        builder: (context, snapshot) {
          final isAdmin = snapshot.hasData && snapshot.data!;
          return FloatingActionButton.extended(
            tooltip: 'Agregar nuevo proveedor',
            onPressed: isAdmin
                ? () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const ProveedorForm()),
                    );
                    if (result == true) {
                      await _refresh();
                    }
                  }
                : null,
            backgroundColor: isAdmin ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.4),
            foregroundColor: isAdmin ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.6),
            icon: const Icon(Icons.add),
            label: const Text("Nuevo"),
          );
        },
      ),
    );
  }
}