import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/logic/categoria/categoria_controller.dart';
import 'package:mamapola_app_v1/logic/categoria/categoria_state.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';
import 'package:mamapola_app_v1/view/categoria/categoria_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/logic/utils/role_manager.dart';

class CategoriaPage extends ConsumerStatefulWidget {
  const CategoriaPage({super.key});

  @override
  ConsumerState<CategoriaPage> createState() => _CategoriaPageState();
}

class _CategoriaPageState extends ConsumerState<CategoriaPage> {
  late Future<bool> _isAdminFuture;

  @override
  void initState() {
    super.initState();
    _isAdminFuture = _isCurrentUserAdmin();
    Future.microtask(() {
      ref.read(categoriaControllerProvider.notifier).loadCategorias();
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
    await ref.read(categoriaControllerProvider.notifier).loadCategorias();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriaControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<CategoriaState>(categoriaControllerProvider, (previousState, newState) {
      if (newState.error != null && previousState?.error != newState.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            UIErrorHandler.showError(context, newState.error);
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.categorias.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          "No hay categorías registradas.",
                          style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = state.categorias[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: colorScheme.surfaceContainer,
                        child: ExpansionTile(
                          leading: Icon(Icons.category, color: colorScheme.primary),
                          title: Text(
                            categoria.nombrecategoria,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
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
                                              builder: (_) => CategoriaForm(categoria: categoria),
                                            ),
                                          );
                                          if (result == true) await _refresh();
                                        } else if (value == 'eliminar') {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              surfaceTintColor: colorScheme.surfaceContainer,
                                              title: const Text('¿Eliminar categoría?'),
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
                                            await ref
                                                .read(categoriaControllerProvider.notifier)
                                                .eliminarCategoria(categoria.idcategoria!);
                                            if (mounted && ref.read(categoriaControllerProvider).error == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: const Text('Categoría eliminada con éxito'),
                                                  backgroundColor: colorScheme.primary,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
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
                                Icon(Icons.numbers, size: 16, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  'ID: ${categoria.idcategoria}',
                                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                                ),
                              ],
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
            tooltip: 'Agregar nueva categoría',
            onPressed: isAdmin
                ? () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoriaForm()),
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
    );
  }
}