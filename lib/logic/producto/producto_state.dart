import 'package:equatable/equatable.dart';
import 'package:mamapola_app_v1/model/entities/producto.dart';

// Definimos una enumeración para los criterios de ordenamiento disponibles
enum ProductSortBy {
  none, // Sin ordenamiento específico
  nameAsc, // Nombre ascendente
  nameDesc, // Nombre descendente
  priceAsc, // Precio ascendente
  priceDesc, // Precio descendente
}

class ProductoState extends Equatable {
  final List<Producto> productos;
  final List<Producto> filteredProductos;
  final bool isLoading;
  final String? error;
  final String? searchTerm;
  final int? selectedCategoria;
  final int? selectedProveedor;
  final String? selectedEstado;
  final ProductSortBy sortBy; // Nuevo: Campo para el criterio de ordenamiento

  const ProductoState({
    this.productos = const [],
    this.filteredProductos = const [],
    this.isLoading = false,
    this.error,
    this.searchTerm,
    this.selectedCategoria,
    this.selectedProveedor,
    this.selectedEstado,
    this.sortBy = ProductSortBy.none, // Valor inicial por defecto
  });

  @override
  List<Object?> get props => [
        productos,
        filteredProductos,
        isLoading,
        error,
        searchTerm,
        selectedCategoria,
        selectedProveedor,
        selectedEstado,
        sortBy, // Incluimos el nuevo campo en Equatable props
      ];

  ProductoState copyWith({
    List<Producto>? productos,
    List<Producto>? filteredProductos,
    bool? isLoading,
    String? error,
    String? searchTerm,
    int? selectedCategoria,
    int? selectedProveedor,
    String? selectedEstado,
    ProductSortBy? sortBy, // Nuevo: Parámetro para copyWith
  }) {
    return ProductoState(
      productos: productos ?? this.productos,
      filteredProductos: filteredProductos ?? this.filteredProductos,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Si el error es null, se borrará
      searchTerm: searchTerm, // Si el searchTerm es null, se borrará
      selectedCategoria: selectedCategoria, // Si es null, se borrará el filtro
      selectedProveedor: selectedProveedor, // Si es null, se borrará el filtro
      selectedEstado: selectedEstado, // Si es null, se borrará el filtro
      sortBy: sortBy ?? this.sortBy, // Actualizamos el criterio de ordenamiento
    );
  }
}