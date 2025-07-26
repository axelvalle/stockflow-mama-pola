import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/almacen.dart';

class AlmacenRepository {
  final SupabaseClient _client;

  AlmacenRepository(this._client);

  Future<List<Almacen>> getAll() async {
    final response = await _client.from('almacen').select().order('nombrealmacen');

    return (response as List)
        .map((item) => Almacen.fromMap(item))
        .toList();
  }

  Future<Almacen?> getById(int id) async {
    final data = await _client
        .from('almacen')
        .select()
        .eq('idalmacen', id)
        .maybeSingle();

    if (data == null) return null;
    return Almacen.fromMap(data);
  }

  Future<void> insert(Almacen almacen) async {
    await _client.from('almacen').insert(almacen.toMap());
  }

  Future<void> update(Almacen almacen) async {
    await _client
        .from('almacen')
        .update(almacen.toMap())
        .eq('idalmacen', almacen.id);
  }

  Future<void> deleteById(int id) async {
    await _client
        .from('almacen')
        .delete()
        .eq('idalmacen', id);
  }
}
