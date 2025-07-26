import 'package:equatable/equatable.dart';
import 'package:mamapola_app_v1/model/entities/almacen.dart';
import 'package:mamapola_app_v1/model/entities/categoria.dart';
import 'package:mamapola_app_v1/model/entities/inventario.dart';

// Enum para el ordenamiento del inventario
enum InventarioSortBy {
  none,
  nombreAsc,
  nombreDesc,
  stockAsc,
  stockDesc,
  precioAsc,
  precioDesc,
}

class InventarioState extends Equatable {
  final List<Inventario> inventarios;
  final List<Inventario> inventarioFiltrado;
  final List<Almacen> almacenes;
  final List<Categoria> categorias;
  final bool isLoading;
  final String? errorMessage;
  final String? searchTerm; // Cambiado de search a searchTerm
  final int? selectedAlmacen; // Cambiado de filtroAlmacen a selectedAlmacen
  final int? selectedCategoria; // Cambiado de filtroCategoria a selectedCategoria
  final InventarioSortBy sortBy; // Cambiado de filtroOrden a sortBy
  final int? stockMin;
  final int? stockMax;
  final double? precioMin;
  final double? precioMax;
  final String? stockFilter; // 'bajo', 'sin', 'suficiente' o null

  const InventarioState({
    this.inventarios = const [],
    this.inventarioFiltrado = const [],
    this.almacenes = const [],
    this.categorias = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchTerm,
    this.selectedAlmacen,
    this.selectedCategoria,
    this.sortBy = InventarioSortBy.none,
    this.stockMin,
    this.stockMax,
    this.precioMin,
    this.precioMax,
    this.stockFilter,
  });

  InventarioState copyWith({
    List<Inventario>? inventarios,
    List<Inventario>? inventarioFiltrado,
    List<Almacen>? almacenes,
    List<Categoria>? categorias,
    bool? isLoading,
    String? errorMessage,
    String? searchTerm,
    int? selectedAlmacen,
    int? selectedCategoria,
    InventarioSortBy? sortBy,
    int? stockMin,
    int? stockMax,
    double? precioMin,
    double? precioMax,
    String? stockFilter,
  }) {
    return InventarioState(
      inventarios: inventarios ?? this.inventarios,
      inventarioFiltrado: inventarioFiltrado ?? this.inventarioFiltrado,
      almacenes: almacenes ?? this.almacenes,
      categorias: categorias ?? this.categorias,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchTerm: searchTerm,
      selectedAlmacen: selectedAlmacen,
      selectedCategoria: selectedCategoria,
      sortBy: sortBy ?? this.sortBy,
      stockMin: stockMin,
      stockMax: stockMax,
      precioMin: precioMin,
      precioMax: precioMax,
      stockFilter: stockFilter ?? this.stockFilter,
    );
  }

  bool get hasFiltrosActivos {
    return (searchTerm != null && searchTerm!.isNotEmpty) ||
        selectedAlmacen != null ||
        selectedCategoria != null ||
        stockMin != null ||
        stockMax != null ||
        precioMin != null ||
        precioMax != null ||
        stockFilter != null;
  }

  @override
  List<Object?> get props => [
        inventarios,
        inventarioFiltrado,
        almacenes,
        categorias,
        isLoading,
        errorMessage,
        searchTerm,
        selectedAlmacen,
        selectedCategoria,
        sortBy,
        stockMin,
        stockMax,
        precioMin,
        precioMax,
        stockFilter,
      ];
}