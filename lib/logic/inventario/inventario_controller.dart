import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/model/repository/inventario_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../model/entities/almacen.dart';
import '../../model/entities/categoria.dart';
import '../../model/entities/inventario.dart';
import 'inventario_state.dart';

// Proveedor para SupabaseClient
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  final client = Supabase.instance.client;
  return client;
});

// Proveedor para InventarioRepository
final inventarioRepositoryProvider = Provider<InventarioRepository>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);
  print('Inicializando InventarioRepository con SupabaseClient: $supabaseClient');
  return InventarioRepository(supabaseClient);
});

// Proveedor para InventarioController
final inventarioControllerProvider =
    StateNotifierProvider<InventarioController, InventarioState>((ref) {
  final repo = ref.watch(inventarioRepositoryProvider);
  print('Inicializando InventarioController con repositorio: $repo');
  return InventarioController(repo);
});

class InventarioController extends StateNotifier<InventarioState> {
  final InventarioRepository _repository;

  InventarioController(this._repository) : super(const InventarioState()) {
    print('InventarioController inicializado con repositorio: $_repository');
    _cargarAlmacenesYCategorias();
  }

  Future<void> _cargarAlmacenesYCategorias() async {
    try {
      final almacenesResponse = await _repository.supabaseClient
          .from('almacen')
          .select()
          .then((data) => (data as List<dynamic>).map((e) => Almacen.fromMap(e)).toList());
      final categoriasResponse = await _repository.supabaseClient
          .from('categoria')
          .select()
          .then((data) => (data as List<dynamic>).map((e) => Categoria.fromMap(e)).toList());

      state = state.copyWith(
        almacenes: almacenesResponse,
        categorias: categoriasResponse,
      );
      print('Almacenes cargados: ${almacenesResponse.length}, Categorías cargadas: ${categoriasResponse.length}');
    } catch (e) {
      print('Error al cargar almacenes y categorías: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> cargarInventario() async {
    state = state.copyWith(isLoading: true);
    try {
      final inventarios = await _repository.obtenerInventario();
      state = state.copyWith(
        inventarios: inventarios,
        inventarioFiltrado: inventarios,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        inventarioFiltrado: [],
      );
    }
  }

  void setSearchTerm(String? term) {
    state = state.copyWith(searchTerm: term);
    _filtrarLocalmente();
  }

  void setSelectedAlmacen(int? almacenId) {
    state = state.copyWith(selectedAlmacen: almacenId);
    _filtrarLocalmente();
  }

  void setSelectedCategoria(int? categoriaId) {
    state = state.copyWith(selectedCategoria: categoriaId);
    _filtrarLocalmente();
  }

  void setSortBy(InventarioSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy, isLoading: true);
    cargarInventario();
  }

  void setStockMin(int? value) {
    state = state.copyWith(stockMin: value, isLoading: true);
    cargarInventario();
  }

  void setStockMax(int? value) {
    state = state.copyWith(stockMax: value, isLoading: true);
    cargarInventario();
  }

  void setPrecioMin(double? value) {
    state = state.copyWith(precioMin: value, isLoading: true);
    cargarInventario();
  }

  void setPrecioMax(double? value) {
    state = state.copyWith(precioMax: value, isLoading: true);
    cargarInventario();
  }

  void setStockFilter(String? value) {
    state = state.copyWith(stockFilter: value, isLoading: true);
    cargarInventario();
  }

  void aplicarFiltros() {
    cargarInventario();
  }

  void clearFiltros() {
    state = state.copyWith(
      searchTerm: null,
      selectedAlmacen: null,
      selectedCategoria: null,
      sortBy: InventarioSortBy.none,
      stockMin: null,
      stockMax: null,
      precioMin: null,
      precioMax: null,
      stockFilter: null,
    );
    _filtrarLocalmente();
  }

  void _filtrarLocalmente() {
    List<Inventario> lista = List.from(state.inventarios);
    if (state.searchTerm != null && state.searchTerm!.isNotEmpty) {
      lista = lista.where((item) =>
        (item.nombreProducto ?? '').toLowerCase().contains(state.searchTerm!.toLowerCase())
      ).toList();
    }
    if (state.selectedAlmacen != null) {
      lista = lista.where((item) => item.idalmacen == state.selectedAlmacen).toList();
    }
    if (state.selectedCategoria != null) {
      lista = lista.where((item) => (item.idCategoria ?? -1) == state.selectedCategoria).toList();
    }
    state = state.copyWith(inventarioFiltrado: lista);
  }

  Future<void> modificarCantidad({
    required int idProducto,
    required int idAlmacen,
    required int cantidadCambio,
  }) async {
    try {
      print(
          'Iniciando modificarCantidad: idProducto=$idProducto, idAlmacen=$idAlmacen, cantidadCambio=$cantidadCambio');
      await _repository.actualizarCantidad(
        idProducto: idProducto,
        idAlmacen: idAlmacen,
        cantidadCambio: cantidadCambio,
      );
      print('Cantidad actualizada en el repositorio');
      await cargarInventario();
      print('Cantidad modificada correctamente');
    } catch (e) {
      print('Error al modificar cantidad: $e');
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }
}