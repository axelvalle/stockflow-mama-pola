import '../../model/entities/almacen.dart';

class AlmacenState {
  final List<Almacen> almacenes;
  final bool isLoading;
  final String? error;

  AlmacenState({
    required this.almacenes,
    this.isLoading = false,
    this.error,
  });

  AlmacenState copyWith({
    List<Almacen>? almacenes,
    bool? isLoading,
    String? error,
  }) {
    return AlmacenState(
      almacenes: almacenes ?? this.almacenes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
