import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/logic/categoria/categoria_state.dart';
import 'package:mamapola_app_v1/model/entities/categoria.dart';
import 'package:mamapola_app_v1/model/repository/categoria_repository.dart';

final categoriaRepositoryProvider = Provider((ref) => CategoriaRepository());

final categoriaControllerProvider =
    StateNotifierProvider<CategoriaController, CategoriaState>((ref) {
  return CategoriaController(ref.read(categoriaRepositoryProvider));
});

class CategoriaController extends StateNotifier<CategoriaState> {
  final CategoriaRepository _repo;

  CategoriaController(this._repo) : super(const CategoriaState());

  Future<void> loadCategorias() async {
    state = state.copyWith(isLoading: true, clearError: true); // Limpiar error anterior
    try {
      final categorias = await _repo.listarCategorias();
      state = state.copyWith(categorias: categorias, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(error: e, isLoading: false); // <--- Pasar 'e' directamente
    }
  }

  Future<int?> agregarCategoria(Categoria categoria) async {
    state = state.copyWith(isLoading: true, clearError: true); // Limpiar error anterior
    try {
      final idCategoria = await _repo.crearCategoria(categoria);
      await loadCategorias();
      return idCategoria;
    } catch (e) {
      state = state.copyWith(error: e, isLoading: false); // <--- Pasar 'e' directamente
      return null;
    }
  }

  Future<void> actualizarCategoria(Categoria categoria) async {
    state = state.copyWith(isLoading: true, clearError: true); // Limpiar error anterior
    try {
      await _repo.actualizarCategoria(categoria);
      await loadCategorias();
    } catch (e) {
      state = state.copyWith(error: e, isLoading: false); // <--- Pasar 'e' directamente
    }
  }

  Future<void> eliminarCategoria(int idCategoria) async {
    state = state.copyWith(isLoading: true, clearError: true); // Limpiar error anterior
    try {
      await _repo.eliminarCategoria(idCategoria);
      await loadCategorias();
    } catch (e) {
      state = state.copyWith(error: e, isLoading: false); // <--- Pasar 'e' directamente
    }
  }
}