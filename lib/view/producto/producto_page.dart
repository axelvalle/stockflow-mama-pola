import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:mamapola_app_v1/logic/producto/producto_controller.dart';
import 'package:mamapola_app_v1/logic/producto/producto_state.dart';
import 'package:mamapola_app_v1/model/entities/producto.dart';
import 'package:mamapola_app_v1/view/producto/producto_form.dart';
import 'package:mamapola_app_v1/logic/categoria/categoria_controller.dart';
import 'package:mamapola_app_v1/logic/categoria/categoria_state.dart';
import 'package:mamapola_app_v1/logic/proveedor/proveedor_controller.dart';
import 'package:mamapola_app_v1/logic/proveedor/proveedor_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/logic/utils/role_manager.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';
import 'package:mamapola_app_v1/view/producto/catalogo_page.dart';

import 'package:mamapola_app_v1/view/producto/producto_detail_page.dart';

class ProductoPage extends ConsumerStatefulWidget {
  const ProductoPage({super.key});

  @override
  ConsumerState<ProductoPage> createState() => _ProductoPageState();
}

class _ProductoPageState extends ConsumerState<ProductoPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _filtersExpanded = false;
  String _viewMode = 'grid';
  late Future<bool> _isAdminFuture;

  @override
  void initState() {
    super.initState();
    _isAdminFuture = _isCurrentUserAdmin();
    _loadViewMode();
    Future.microtask(() {
      ref.read(productoControllerProvider.notifier).cargarProductos();
      ref.read(categoriaControllerProvider.notifier).loadCategorias();
      ref.read(proveedorControllerProvider.notifier).loadProveedores();
    });
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _viewMode = prefs.getString('viewMode') ?? 'grid';
    });
  }

  Future<void> _saveViewMode(String viewMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('viewMode', viewMode);
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(productoControllerProvider.notifier).cargarProductos();
  }


  @override
  Widget build(BuildContext context) {
    final productoState = ref.watch(productoControllerProvider);
    final categoriaState = ref.watch(categoriaControllerProvider);
    final proveedorState = ref.watch(proveedorControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 4 : screenWidth > 600 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        centerTitle: true,
        elevation: 2,
        surfaceTintColor: colorScheme.surfaceContainer,
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            tooltip: 'Ver catálogo completo',
            icon: Icon(Icons.inventory_2, color: colorScheme.onSurface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CatalogoPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Refrescar lista',
            icon: Icon(Icons.refresh, color: colorScheme.onSurface),
            onPressed: productoState.isLoading ? null : _refresh,
          ),
          PopupMenuButton<String>(
            tooltip: 'Cambiar vista',
            icon: Icon(
              _viewMode == 'grid' ? Icons.view_module : Icons.view_list,
              color: colorScheme.onSurface,
            ),
            onSelected: (value) {
              setState(() {
                _viewMode = value;
                _saveViewMode(value);
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'grid', child: Text('Vista de cuadrícula')),
              PopupMenuItem(value: 'list', child: Text('Vista de lista')),
            ],
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar producto',
                hintText: 'Ej. Manzanas',
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(productoControllerProvider.notifier).setSearchTerm(null);
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
              onTap: () {
                if (_filtersExpanded) {
                  setState(() => _filtersExpanded = false);
                }
              },
              onChanged: (value) {
                ref.read(productoControllerProvider.notifier).setSearchTerm(value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: ExpansionTile(
                title: const Text('Filtros y Ordenamiento'),
                leading: Icon(Icons.filter_list, color: colorScheme.onSurfaceVariant),
                initiallyExpanded: _filtersExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _filtersExpanded = expanded;
                    if (expanded) FocusScope.of(context).unfocus();
                  });
                },
                children: [
                  Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: SingleChildScrollView(
                      child: _buildFilterDropdowns(productoState, categoriaState, proveedorState),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (productoState.error != null && !productoState.isLoading)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Error: ${productoState.error}',
                style: TextStyle(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: productoState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : productoState.filteredProductos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: colorScheme.onSurfaceVariant),
                              const SizedBox(height: 12),
                              Text(
                                "No hay productos que coincidan con los filtros.",
                                style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        )
                      : _viewMode == 'grid'
                          ? GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: productoState.filteredProductos.length,
                              itemBuilder: (context, index) {
                                final producto = productoState.filteredProductos[index];
                                return _buildProductoCard(producto);
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: productoState.filteredProductos.length,
                              itemBuilder: (context, index) {
                                final producto = productoState.filteredProductos[index];
                                return _buildProductoListItem(producto);
                              },
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _isAdminFuture,
        builder: (context, snapshot) {
          final isAdmin = snapshot.hasData && snapshot.data!;
          return FloatingActionButton.extended(
            tooltip: 'Agregar nuevo producto',
            onPressed: isAdmin
                ? () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductoForm()),
                    );
                    if (result == true) await _refresh();
                  }
                : null,
            backgroundColor: isAdmin ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.4),
            foregroundColor: isAdmin ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.6),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo'),
          );
        },
      ),
    );
  }

  Widget _buildProductoCard(Producto producto) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductoDetailPage(producto: producto)),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: colorScheme.surfaceContainer,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: producto.imagenUrl != null
                        ? Image.network(
                            producto.imagenUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: colorScheme.surfaceContainerLowest,
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            loadingBuilder: (context, child, loadingProgress) =>
                                loadingProgress == null ? child : const Center(child: CircularProgressIndicator()),
                          )
                        : Container(
                            color: colorScheme.surfaceContainerLowest,
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombreproducto,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'C\$${producto.precio.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: FutureBuilder<bool>(
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
                                MaterialPageRoute(builder: (_) => ProductoForm(producto: producto)),
                              );
                              if (result == true) await _refresh();
                            } else if (value == 'eliminar') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  surfaceTintColor: colorScheme.surfaceContainer,
                                  title: const Text('¿Eliminar producto?'),
                                  content: const Text('Esta acción no se puede deshacer.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Cancelar', style: TextStyle(color: colorScheme.onSurface)),
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
                                  await ref
                                      .read(productoControllerProvider.notifier)
                                      .eliminarProducto(producto.idproducto!, producto.imagenUrl);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Producto eliminado'),
                                      backgroundColor: colorScheme.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  await _refresh();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al eliminar: $e'),
                                      backgroundColor: colorScheme.error,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoListItem(Producto producto) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: producto.imagenUrl != null
              ? Image.network(
                  producto.imagenUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: colorScheme.surfaceContainerLowest,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 30,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) => loadingProgress == null
                      ? child
                      : const SizedBox(
                          width: 60,
                          height: 60,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: colorScheme.surfaceContainerLowest,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 30,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        title: Text(
          producto.nombreproducto,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'C\$${producto.precio.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductoDetailPage(producto: producto)),
          );
        },
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
                          MaterialPageRoute(builder: (_) => ProductoForm(producto: producto)),
                        );
                        if (result == true) await _refresh();
                      } else if (value == 'eliminar') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            surfaceTintColor: colorScheme.surfaceContainer,
                            title: const Text('¿Eliminar producto?'),
                            content: const Text('Esta acción no se puede deshacer.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancelar', style: TextStyle(color: colorScheme.onSurface)),
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
                            await ref
                                .read(productoControllerProvider.notifier)
                                .eliminarProducto(producto.idproducto!, producto.imagenUrl);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Producto eliminado'),
                                backgroundColor: colorScheme.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            await _refresh();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al eliminar: $e'),
                                backgroundColor: colorScheme.error,
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
      ),
    );
  }

  Widget _buildFilterDropdowns(
    ProductoState productoState,
    CategoriaState categoriaState,
    ProveedorState proveedorState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButton2<int?>(
          value: productoState.selectedCategoria,
          hint: const Text('Seleccione una categoría'),
          isExpanded: true,
          buttonStyleData: ButtonStyleData(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 200,
            offset: const Offset(0, -10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surfaceContainer,
            ),
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('Todas las categorías', style: TextStyle(color: colorScheme.onSurface)),
            ),
            if (categoriaState.isLoading)
              const DropdownMenuItem<int?>(
                value: null,
                enabled: false,
                child: Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Cargando categorías...'),
                  ],
                ),
              ),
            if (categoriaState.error != null)
              DropdownMenuItem<int?>(
                value: null,
                enabled: false,
                child: Text('Error: ${categoriaState.error}', style: TextStyle(color: colorScheme.error)),
              ),
            ...categoriaState.categorias.map(
              (categoria) => DropdownMenuItem<int>(
                value: categoria.idcategoria,
                child: Text(categoria.nombrecategoria, style: TextStyle(color: colorScheme.onSurface)),
              ),
            ),
          ],
          onChanged: (int? newValue) {
            ref.read(productoControllerProvider.notifier).setSelectedCategoria(newValue);
          },
          menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 16)),
        ),
        const SizedBox(height: 16),
        DropdownButton2<int?>(
          value: productoState.selectedProveedor,
          hint: const Text('Seleccione un proveedor'),
          isExpanded: true,
          buttonStyleData: ButtonStyleData(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 200,
            offset: const Offset(0, -10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surfaceContainer,
            ),
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('Todos los proveedores', style: TextStyle(color: colorScheme.onSurface)),
            ),
            if (proveedorState.isLoading)
              const DropdownMenuItem<int?>(
                value: null,
                enabled: false,
                child: Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Cargando proveedores...'),
                  ],
                ),
              ),
            if (proveedorState.error != null)
              DropdownMenuItem<int?>(
                value: null,
                enabled: false,
                child: Text('Error: ${proveedorState.error}', style: TextStyle(color: colorScheme.error)),
              ),
            ...proveedorState.proveedores.map(
              (proveedor) => DropdownMenuItem<int>(
                value: proveedor.id,
                child: Text(
                  proveedor.persona?.primerNombre ?? 'Proveedor Desconocido',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
            ),
          ],
          onChanged: (int? newValue) {
            ref.read(productoControllerProvider.notifier).setSelectedProveedor(newValue);
          },
          menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 16)),
        ),
        const SizedBox(height: 16),
        DropdownButton2<ProductSortBy>(
          value: productoState.sortBy,
          isExpanded: true,
          buttonStyleData: ButtonStyleData(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 200,
            offset: const Offset(0, -10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surfaceContainer,
            ),
          ),
          items: [
            DropdownMenuItem(
              value: ProductSortBy.none,
              child: Text('Sin ordenar', style: TextStyle(color: colorScheme.onSurface)),
            ),
            DropdownMenuItem(
              value: ProductSortBy.nameAsc,
              child: Text('Nombre (A-Z)', style: TextStyle(color: colorScheme.onSurface)),
            ),
            DropdownMenuItem(
              value: ProductSortBy.nameDesc,
              child: Text('Nombre (Z-A)', style: TextStyle(color: colorScheme.onSurface)),
            ),
            DropdownMenuItem(
              value: ProductSortBy.priceAsc,
              child: Text('Precio (Menor a Mayor)', style: TextStyle(color: colorScheme.onSurface)),
            ),
            DropdownMenuItem(
              value: ProductSortBy.priceDesc,
              child: Text('Precio (Mayor a Menor)', style: TextStyle(color: colorScheme.onSurface)),
            ),
          ],
          onChanged: (ProductSortBy? newValue) {
            if (newValue != null) ref.read(productoControllerProvider.notifier).setSortBy(newValue);
          },
          menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 16)),
        ),
      ],
    );
  }
}