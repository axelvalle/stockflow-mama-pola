import 'package:flutter/material.dart';
import 'package:mamapola_app_v1/model/entities/catalogo_producto.dart';
import 'package:mamapola_app_v1/model/repository/catalogo_producto_repository.dart';
import 'package:mamapola_app_v1/services/catalogo_service.dart';

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final CatalogoProductoRepository _repository = CatalogoProductoRepository();
  final TextEditingController _searchController = TextEditingController();
  
  late Future<List<CatalogoProducto>> _productosFuture;
  bool _isGeneratingReport = false;
  String _selectedCategoria = 'Todas';
  String _selectedProveedor = 'Todos';
  final String _selectedEstado = 'Todos';
  
  List<String> _categorias = ['Todas'];
  List<String> _proveedores = ['Todos'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _productosFuture = _repository.getCatalogoProductos();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _productosFuture = _repository.getCatalogoProductos();
    });
  }

  Future<void> _generateCatalogo() async {
    print('Generando catálogo de productos...');

    await CatalogoService.generateCatalogo(
      context: context,
      onProgress: (isGenerating) {
        if (mounted) {
          setState(() {
            _isGeneratingReport = isGenerating;
          });
        }
      },
      limitado: false, // Generar catálogo completo
    );
  }

  List<CatalogoProducto> _aplicarFiltros(List<CatalogoProducto> productos) {
    List<CatalogoProducto> filtrados = productos;

    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty) {
      filtrados = filtrados.where((producto) =>
        producto.nombreproducto?.toLowerCase().contains(_searchController.text.toLowerCase()) == true ||
        producto.nombrecategoria?.toLowerCase().contains(_searchController.text.toLowerCase()) == true ||
        producto.proveedor?.toLowerCase().contains(_searchController.text.toLowerCase()) == true
      ).toList();
    }

    // Filtrar por categoría
    if (_selectedCategoria != 'Todas') {
      filtrados = filtrados.where((producto) => producto.nombrecategoria == _selectedCategoria).toList();
    }

    // Filtrar por proveedor
    if (_selectedProveedor != 'Todos') {
      filtrados = filtrados.where((producto) => producto.proveedor == _selectedProveedor).toList();
    }

    // Filtrar por estado
    if (_selectedEstado != 'Todos') {
      filtrados = filtrados.where((producto) => producto.estado == _selectedEstado).toList();
    }

    return filtrados;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(),
            tooltip: 'Recargar datos',
          ),
          IconButton(
            icon: _isGeneratingReport
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isGeneratingReport ? null : _generateCatalogo,
            tooltip: 'Generar catálogo PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar productos',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                
                // Filtros adicionales
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<List<CatalogoProducto>>(
                        future: _productosFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final productos = snapshot.data!;
                            final categorias = productos
                                .map((p) => p.nombrecategoria)
                                .where((c) => c != null && c.isNotEmpty)
                                .map((c) => c!)
                                .toSet()
                                .toList()
                              ..sort();
                            
                            if (_categorias.length == 1) {
                              _categorias = ['Todas', ...categorias];
                            }

                            return DropdownButtonFormField<String>(
                              value: _selectedCategoria,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                                border: OutlineInputBorder(),
                              ),
                              items: _categorias.map((categoria) {
                                return DropdownMenuItem(
                                  value: categoria,
                                  child: Text(categoria),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoria = value!;
                                });
                              },
                            );
                          }
                          return DropdownButtonFormField<String>(
                            value: 'Todas',
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              border: OutlineInputBorder(),
                            ),
                            items: const [DropdownMenuItem(value: 'Todas', child: Text('Todas'))],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoria = value!;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FutureBuilder<List<CatalogoProducto>>(
                        future: _productosFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final productos = snapshot.data!;
                            final proveedores = productos
                                .map((p) => p.proveedor)
                                .where((p) => p != null && p.isNotEmpty)
                                .map((p) => p!)
                                .toSet()
                                .toList()
                              ..sort();
                            
                            if (_proveedores.length == 1) {
                              _proveedores = ['Todos', ...proveedores];
                            }

                            return DropdownButtonFormField<String>(
                              value: _selectedProveedor,
                              decoration: const InputDecoration(
                                labelText: 'Proveedor',
                                border: OutlineInputBorder(),
                              ),
                              items: _proveedores.map((proveedor) {
                                return DropdownMenuItem(
                                  value: proveedor,
                                  child: Text(proveedor),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedProveedor = value!;
                                });
                              },
                            );
                          }
                          return DropdownButtonFormField<String>(
                            value: 'Todos',
                            decoration: const InputDecoration(
                              labelText: 'Proveedor',
                              border: OutlineInputBorder(),
                            ),
                            items: const [DropdownMenuItem(value: 'Todos', child: Text('Todos'))],
                            onChanged: (value) {
                              setState(() {
                                _selectedProveedor = value!;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: FutureBuilder<List<CatalogoProducto>>(
              future: _productosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar el catálogo',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final productos = snapshot.data ?? [];
                final productosFiltrados = _aplicarFiltros(productos);

                if (productosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          productos.isEmpty ? 'No hay productos en el catálogo' : 'No se encontraron productos con los filtros aplicados',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final producto = productosFiltrados[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(
                          producto.nombreproducto ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Categoría: ${producto.nombrecategoria ?? 'Sin categoría'}'),
                            Text('Proveedor: ${producto.proveedor ?? 'Sin proveedor'}'),
                            Text('Estado: ${producto.estado ?? 'Activo'}'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'C\$${(producto.precio ?? 0).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            if (producto.minimoInventario != null)
                              Text(
                                'Mín: ${producto.minimoInventario}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 