import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/model/entities/empresa.dart';

class EmpresaRepository {
  final _client = Supabase.instance.client;

Future<List<Empresa>> getEmpresasConProveedores() async {
final data = await _client
.from('empresa')
.select('''
idempresa,
nombreempresa,
direccion,
contacto,
proveedor:proveedor (
idproveedor,
idpersona,
persona (
primernombre,
primerapellido,
telefono
)
)
''')
.order('idempresa', ascending: true);

return (data as List).map((e) => Empresa.fromMap(e)).toList();
}

  Future<void> insertarEmpresa(Empresa empresa) async {
    await _client.from('empresa').insert({
      'nombreempresa': empresa.nombreempresa,
      'direccion': empresa.direccion,
      'contacto': empresa.contacto,
    });
  }

  Future<void> actualizarEmpresa(Empresa empresa) async {
    await _client.from('empresa').update({
      'nombreempresa': empresa.nombreempresa,
      'direccion': empresa.direccion,
      'contacto': empresa.contacto,
    }).eq('idempresa', empresa.idempresa);
  }

  Future<void> eliminarEmpresa(int idempresa) async {
    // Verificamos si la empresa tiene proveedores asociados y obtenemos hasta 3 nombres
    final proveedoresResponse = await _client
        .from('proveedor')
        .select('''
          idproveedor,
          persona (
            primernombre,
            primerapellido
          )
        ''')
        .eq('idempresa', idempresa)
        .limit(3);

    if (proveedoresResponse.isNotEmpty) {
      final nombres = (proveedoresResponse as List)
          .map((e) {
            final persona = e['persona'] as Map<String, dynamic>;
            return '${persona['primernombre']} ${persona['primerapellido']}';
          })
          .toList();
      final nombresStr = nombres.join(', ');
      throw Exception('No se puede eliminar la empresa porque tiene proveedores asociados. Ejemplo(s): $nombresStr. Elimine primero los proveedores relacionados.');
    }

    await _client.from('empresa').delete().eq('idempresa', idempresa);
  }

  Future<int> insertarEmpresaYRetornarId(Empresa empresa) async {
  final result = await _client
          .from('empresa')
          .insert({
            'nombreempresa': empresa.nombreempresa,
            'direccion': empresa.direccion,
            'contacto': empresa.contacto,
          })
          .select()
          .single();
      return result['idempresa'];
    }

}
