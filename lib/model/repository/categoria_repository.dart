import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/model/entities/categoria.dart';

class CategoriaRepository {
  final _client = Supabase.instance.client;

  Future<List<Categoria>> listarCategorias() async {
    final response = await _client
        .from('categoria')
        .select('idcategoria, nombrecategoria')
        .order('idcategoria', ascending: true);

    return (response as List<dynamic>).map((map) => Categoria.fromMap(map)).toList();
  }

  Future<int> crearCategoria(Categoria categoria) async {
    final response = await _client
        .from('categoria')
        .insert(categoria.toMap()..removeWhere((key, value) => key == 'idcategoria' && value == null))
        .select('idcategoria')
        .single();

    return response['idcategoria'] as int;
  }

  Future<void> actualizarCategoria(Categoria categoria) async {
    if (categoria.idcategoria == null) {
      throw Exception('ID de categoría es requerido para actualizar.');
    }

    await _client
        .from('categoria')
        .update(categoria.toMap()..removeWhere((key, value) => key == 'idcategoria'))
        .eq('idcategoria', categoria.idcategoria!);
  }

  Future<void> eliminarCategoria(int idCategoria) async {
    await _client.from('categoria').delete().eq('idcategoria', idCategoria);
  }
}