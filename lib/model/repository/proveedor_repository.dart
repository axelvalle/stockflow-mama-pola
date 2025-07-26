import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/model/entities/proveedor.dart';

class ProveedorRepository {
  final _client = Supabase.instance.client;



  Future<List<Proveedor>> getProveedores() async {
    final data = await _client
        .from('proveedor')
        .select('*, persona(*), empresa(*)');
    return (data as List).map((e) => Proveedor.fromMap(e)).toList();
  }

Future<void> deleteProveedorByPersona(int idPersona) async {
  // Primero obtenemos el ID del proveedor basado en el ID de la persona
  final proveedorResponse = await _client
      .from('proveedor')
      .select('idproveedor')
      .eq('idpersona', idPersona)
      .maybeSingle();

  if (proveedorResponse == null) {
    throw Exception('Proveedor no encontrado');
  }

  final idProveedor = proveedorResponse['idproveedor'] as int;

  // Verificamos si el proveedor tiene productos asociados y obtenemos hasta 3 nombres
  final productosResponse = await _client
      .from('producto')
      .select('nombreproducto')
      .eq('idproveedor', idProveedor)
      .limit(3);

  if (productosResponse.isNotEmpty) {
    final nombres = (productosResponse as List)
        .map((e) => e['nombreproducto'] as String)
        .toList();
    final nombresStr = nombres.join(', ');
    throw Exception('No se puede eliminar el proveedor porque tiene productos asociados. Ejemplo(s): $nombresStr. Elimine primero los productos relacionados.');
  }

  final response = await _client.from('proveedor').delete().match({'idpersona': idPersona});

  if (response.error != null) {
    throw Exception(response.error!.message);
  }
}


Future<void> createProveedor(int idPersona) async {
  final response = await _client.from('proveedor').insert({'idpersona': idPersona});
  if (response.error != null) {
    throw PostgrestException(
      message: response.error!.message,
      code: response.error!.code,
      details: response.error!.details,
      hint: response.error!.hint,
    );
  }
}

Future<void> actualizarEmpresaDelProveedor(int idProveedor, int idEmpresa) async {
  final response = await _client
    .from('proveedor')
    .update({'idempresa': idEmpresa})
    .eq('idproveedor', idProveedor);
  if (response.error != null) {
    throw PostgrestException(
      message: response.error!.message,
      code: response.error!.code,
      details: response.error!.details,
      hint: response.error!.hint,
    );
  }
}

Future<void> quitarEmpresaDeProveedores(List<int> ids) async {
  final response = await _client
      .from('proveedor')
      .update({'idempresa': null})
      .inFilter('idproveedor', ids);
  if (response.error != null) {
    throw PostgrestException(
      message: response.error!.message,
      code: response.error!.code,
      details: response.error!.details,
      hint: response.error!.hint,
    );
  }
}

Future<void> asignarProveedorAEmpresa(int idProveedor, int idEmpresa) async {
  final response = await _client
      .from('proveedor')
      .update({'idempresa': idEmpresa})
      .eq('idproveedor', idProveedor);
  if (response.error != null) {
    throw PostgrestException(
      message: response.error!.message,
      code: response.error!.code,
      details: response.error!.details,
      hint: response.error!.hint,
    );
  }
}

Future<void> desasignarProveedorDeEmpresa(int idProveedor) async {
  final response = await _client.from('proveedor').update({'idempresa': null}).eq('idproveedor', idProveedor);
  if (response.error != null) {
    throw PostgrestException(
      message: response.error!.message,
      code: response.error!.code,
      details: response.error!.details,
      hint: response.error!.hint,
    );
  }
}

}