// logic/categoria/categoria_state.dart
import 'package:equatable/equatable.dart';
import 'package:mamapola_app_v1/model/entities/categoria.dart';

class CategoriaState extends Equatable {
  final bool isLoading;
  final List<Categoria> categorias;
  final Object? error; // CORRECTO: Ahora es Object?

  const CategoriaState({
    this.isLoading = false,
    this.categorias = const [],
    this.error,
  });

  @override
  List<Object?> get props => [isLoading, categorias, error];

  // ¡EL MÉTODO copyWith DEBE LUCIR ASÍ!
  CategoriaState copyWith({
    bool? isLoading,
    List<Categoria>? categorias,
    Object? error, // <--- ¡AQUÍ ESTABA EL ERROR! DEBE SER Object?
    bool clearError = false, // <--- ¡AQUÍ ESTABA EL ERROR! ESTE PARÁMETRO DEBE EXISTIR
  }) {
    return CategoriaState(
      isLoading: isLoading ?? this.isLoading,
      categorias: categorias ?? this.categorias,
      // Implementación del error usando clearError
      error: clearError ? null : (error ?? this.error),
    );
  }
}