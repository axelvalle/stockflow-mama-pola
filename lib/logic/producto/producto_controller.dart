import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/logic/producto/producto_state.dart';
import 'package:mamapola_app_v1/model/entities/producto.dart';
import 'package:mamapola_app_v1/model/repository/producto_repository.dart';

final productoControllerProvider =
    StateNotifierProvider<ProductoController, ProductoState>((ref) {
  return ProductoController(ref.read(productoRepositoryProvider)); // Inyectamos el repositorio
});

// Definimos un proveedor para el ProductoRepository si aún no lo tienes
// Esto es una buena práctica con Riverpod para facilitar la inyección de dependencias y los tests
final productoRepositoryProvider = Provider((ref) => ProductoRepository());


class ProductoController extends StateNotifier<ProductoState> {
  final ProductoRepository _repo; // Ahora inyectamos el repositorio

  ProductoController(this._repo) : super(const ProductoState());

  // Método para cargar productos con filtros y ordenamiento
  Future<void> cargarProductos({
    String? searchTerm,
    int? idCategoria,
    int? idProveedor,
    ProductSortBy? sortBy,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      // Usamos los parámetros del estado si no se proporcionan explícitamente
      final currentSearchTerm = searchTerm ?? state.searchTerm;
      final currentCategoria = idCategoria ?? state.selectedCategoria;
      final currentProveedor = idProveedor ?? state.selectedProveedor;
      final currentSortBy = sortBy ?? state.sortBy;

      String? orderByColumn;
      bool ascending = true;

      // Determinamos la columna y la dirección de ordenamiento
      switch (currentSortBy) {
        case ProductSortBy.nameAsc:
          orderByColumn = 'nombreproducto';
          ascending = true;
          break;
        case ProductSortBy.nameDesc:
          orderByColumn = 'nombreproducto';
          ascending = false;
          break;
        case ProductSortBy.priceAsc:
          orderByColumn = 'precio';
          ascending = true;
          break;
        case ProductSortBy.priceDesc:
          orderByColumn = 'precio';
          ascending = false;
          break;
        case ProductSortBy.none: // Manejamos 'none' explícitamente
          orderByColumn = null; // Sin ordenamiento específico
          break;
        // La cláusula 'default' es ahora innecesaria y se elimina.
        // Si añades nuevos valores al enum ProductSortBy, Dart te avisará
        // si no los manejas aquí, lo cual es un comportamiento deseable.
      }

      final productos = await _repo.listarProductos(
        searchTerm: currentSearchTerm,
        idCategoria: currentCategoria,
        idProveedor: currentProveedor,
        orderBy: orderByColumn,
        ascending: ascending,
      );

      state = state.copyWith(
        productos: productos,
        filteredProductos: productos, // Inicialmente, los productos filtrados son todos los cargados
        isLoading: false,
        error: null,
        searchTerm: currentSearchTerm,
        selectedCategoria: currentCategoria,
        selectedProveedor: currentProveedor,
        sortBy: currentSortBy,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      // Opcional: limpiar la lista de productos filtrados si hay un error
      state = state.copyWith(filteredProductos: []);
    }
  }

  // Métodos para actualizar los filtros y disparar la carga de productos
  void setSearchTerm(String? term) {
    state = state.copyWith(searchTerm: term, isLoading: true);
    cargarProductos(searchTerm: term); // Recargamos productos con el nuevo término
  }

  void setSelectedCategoria(int? categoriaId) {
    state = state.copyWith(selectedCategoria: categoriaId, isLoading: true);
    cargarProductos(idCategoria: categoriaId); // Recargamos productos con la nueva categoría
  }

  void setSelectedProveedor(int? proveedorId) {
    state = state.copyWith(selectedProveedor: proveedorId, isLoading: true);
    cargarProductos(idProveedor: proveedorId); // Recargamos productos con el nuevo proveedor
  }

  void setSortBy(ProductSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy, isLoading: true);
    cargarProductos(sortBy: sortBy); // Recargamos productos con el nuevo ordenamiento
  }


  // Métodos para operaciones CRUD (sin cambios significativos aquí, pero pueden usar cargarProductos)

  Future<int> agregarProducto(Producto producto, String? imagenPath) async {
    state = state.copyWith(isLoading: true);
    try {
      final idProducto = await _repo.crearProducto(producto);
      String? imagenUrl;
      if (imagenPath != null) {
        imagenUrl = await _repo.subirImagen(imagenPath, idProducto);
        await _repo.actualizarProducto(producto.copyWith(idproducto: idProducto, imagenUrl: imagenUrl));
      }
      await cargarProductos(); // Recargar productos después de agregar
      return idProducto;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> actualizarProducto(Producto producto, String? imagenPath) async {
    state = state.copyWith(isLoading: true);
    try {
      String? imagenUrl = producto.imagenUrl;
      if (imagenPath != null) {
        if (producto.imagenUrl != null) {
          await _repo.eliminarImagen(producto.imagenUrl!);
        }
        imagenUrl = await _repo.subirImagen(imagenPath, producto.idproducto!);
      }
      await _repo.actualizarProducto(producto.copyWith(imagenUrl: imagenUrl));
      await cargarProductos(); // Recargar productos después de actualizar
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> eliminarProducto(int idProducto, String? imagenUrl) async {
    state = state.copyWith(isLoading: true);
    try {
      if (imagenUrl != null) {
        await _repo.eliminarImagen(imagenUrl);
      }
      await _repo.eliminarProducto(idProducto);
      await cargarProductos(); // Recargar productos después de eliminar
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}