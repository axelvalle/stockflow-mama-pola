import 'package:mamapola_app_v1/model/entities/proveedor.dart';

class ProveedorState {
  final bool isLoading;
  final List<Proveedor> proveedores;
  final String? error;

  ProveedorState({
    required this.isLoading,
    required this.proveedores,
    this.error,
  });

  factory ProveedorState.initial() => ProveedorState(
    isLoading: false,
    proveedores: [],
  );

  ProveedorState copyWith({
    bool? isLoading,
    List<Proveedor>? proveedores,
    String? error,
  }) {
    return ProveedorState(
      isLoading: isLoading ?? this.isLoading,
      proveedores: proveedores ?? this.proveedores,
      error: error,
    );
  }
}