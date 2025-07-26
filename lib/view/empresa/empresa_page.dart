import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/view/empresa/empresa_form.dart';
import 'package:mamapola_app_v1/logic/empresa/empresa_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/logic/utils/role_manager.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';

class EmpresaPage extends ConsumerStatefulWidget {
  const EmpresaPage({super.key});

  @override
  ConsumerState<EmpresaPage> createState() => _EmpresaPageState();
}

class _EmpresaPageState extends ConsumerState<EmpresaPage> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  late Future<bool> _isAdminFuture;

  @override
  void initState() {
    super.initState();
    _isAdminFuture = _isCurrentUserAdmin();
    Future.microtask(() {
      ref.read(empresaControllerProvider.notifier).cargarEmpresas();
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
    await ref.read(empresaControllerProvider.notifier).cargarEmpresas();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(empresaControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Empresas'),
          centerTitle: true,
          elevation: 2,
          surfaceTintColor: colorScheme.surfaceContainer,
          backgroundColor: colorScheme.surface,
          actions: [
            IconButton(
              tooltip: 'Refrescar lista',
              icon: Icon(Icons.refresh, color: colorScheme.onSurface),
              onPressed: controller.isLoading ? null : _refresh,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : controller.empresas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            "No hay empresas registradas.",
                            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.empresas.length,
                      itemBuilder: (context, index) {
                        final empresa = controller.empresas[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: colorScheme.surfaceContainer,
                          child: ExpansionTile(
                            leading: Icon(Icons.business, color: colorScheme.primary),
                            title: Text(
                              empresa.nombreempresa,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              empresa.direccion ?? 'Sin dirección',
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                            trailing: FutureBuilder<bool>(
                              future: _isAdminFuture,
                              builder: (context, snapshot) {
                                final isAdmin = snapshot.hasData && snapshot.data!;
                                return isAdmin
                                    ? PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
                                        onSelected: (value) async {
                                          if (value == 'editar') {
                                            final result = await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EmpresaForm(empresa: empresa),
                                              ),
                                            );
                                            if (result == true) await _refresh();
                                          } else if (value == 'eliminar') {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                surfaceTintColor: colorScheme.surfaceContainer,
                                                title: const Text('¿Eliminar empresa?'),
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
                                                                                      if (confirm == true) {
                                            try {
                                              print('Eliminando empresa ${empresa.idempresa}');
                                              await ref
                                                  .read(empresaControllerProvider.notifier)
                                                  .eliminarEmpresa(empresa.idempresa);

                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: const Text('Empresa eliminada correctamente'),
                                                    backgroundColor: colorScheme.primary,
                                                    behavior: SnackBarBehavior.floating,
                                                    duration: const Duration(seconds: 3),
                                                  ),
                                                );
                                              }

                                              // Solo recargar si la eliminación fue exitosa
                                              await _refresh();
                                            } catch (e) {
                                              print('Error al eliminar empresa: $e');
                                              // Usar el GlobalKey para mostrar el snackbar
                                              final errorMessage = e.toString().replaceAll('Exception: ', '');
                                              _scaffoldKey.currentState?.showSnackBar(
                                                SnackBar(
                                                  content: Text(errorMessage),
                                                  backgroundColor: colorScheme.error,
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: const Duration(seconds: 5),
                                                  action: SnackBarAction(
                                                    label: 'Entendido',
                                                    textColor: colorScheme.onError,
                                                    onPressed: () {
                                                      _scaffoldKey.currentState?.hideCurrentSnackBar();
                                                    },
                                                  ),
                                                ),
                                              );
                                              // NO recargar la página si hay error
                                            }
                                          }
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(value: 'editar', child: Text('Editar')),
                                          PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                                        ],
                                        color: colorScheme.surfaceContainer,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      )
                                    : const SizedBox.shrink();
                              },
                            ),
                            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Contacto: ${empresa.contacto ?? "N/A"}',
                                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Proveedores asociados:',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              if (empresa.proveedores.isEmpty)
                                Text(
                                  'No hay proveedores asociados.',
                                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                                )
                              else
                                Column(
                                  children: empresa.proveedores.map((prov) {
                                    final persona = prov.persona;
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.person, color: colorScheme.onSurfaceVariant),
                                      title: Text(
                                        '${persona?.primerNombre ?? ''} ${persona?.primerApellido ?? ''}',
                                        style: TextStyle(color: colorScheme.onSurface),
                                      ),
                                      subtitle: Text(
                                        persona?.telefono ?? 'Sin teléfono',
                                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
        floatingActionButton: FutureBuilder<bool>(
          future: _isAdminFuture,
          builder: (context, snapshot) {
            final isAdmin = snapshot.hasData && snapshot.data!;
            return FloatingActionButton.extended(
              tooltip: 'Agregar nueva empresa',
              onPressed: isAdmin
                  ? () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const EmpresaForm()),
                      );
                      if (result == true) await _refresh();
                    }
                  : null,
              // ignore: deprecated_member_use
              backgroundColor: isAdmin ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.4),
              // ignore: deprecated_member_use
              foregroundColor: isAdmin ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.6),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            );
          },
        ),
      ),
    );
  }
}
