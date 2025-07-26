import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/model/entities/producto.dart';

class ProductoRepository {
  final _client = Supabase.instance.client;
  final _bucketName = 'productos';

  Future<List<Producto>> listarProductos({
    String? searchTerm,
    int? idCategoria,
    int? idProveedor,
    String? orderBy, // Campo por el cual ordenar (e.g., 'nombreproducto', 'precio')
    bool ascending = true, // Si el orden es ascendente o descendente
  }) async {
    try {
      // Usamos 'dynamic' para evitar problemas de tipos durante el encadenamiento
      // de métodos de Supabase, ya que el tipo de retorno cambia.
      dynamic query = _client
          .from('producto')
          .select('idproducto, nombreproducto, precio, idcategoria, idproveedor, estado, imagen_url, minimo_inventario');

      // Aplicar filtro por término de búsqueda si existe
      if (searchTerm != null && searchTerm.isNotEmpty) {
        query = query.ilike('nombreproducto', '%$searchTerm%');
      }

      // Aplicar filtro por categoría si existe
      if (idCategoria != null) {
        query = query.eq('idcategoria', idCategoria);
      }

      // Aplicar filtro por proveedor si existe
      if (idProveedor != null) {
        query = query.eq('idproveedor', idProveedor);
      }

      // Aplicar ordenamiento si se especifica un campo
      if (orderBy != null && orderBy.isNotEmpty) {
        query = query.order(orderBy, ascending: ascending);
      } else {
        // Ordenamiento por defecto si no se especifica uno
        query = query.order('idproducto', ascending: true);
      }

      final response = await query; // Ejecutamos la consulta

      return (response as List<dynamic>)
          .map((map) => Producto.fromMap(map))
          .toList();
    } catch (e) {
      print('Error al listar productos: $e');
      throw Exception('Error al listar productos: $e');
    }
  }


  Future<bool> hasProductsInCategory(int categoriaId) async {
    try {
      // **CORRECCIÓN AQUÍ:** Usamos .count() después de la consulta y .maybeSingle() o .limit(1)
      final response = await _client
          .from('producto')
          .select('idproducto') // No necesitamos el 'count' aquí
          .eq('idcategoria', categoriaId)
          .limit(1) // Solo necesitamos saber si existe al menos uno
          .maybeSingle(); // Usamos maybeSingle para obtener 0 o 1 resultado

      // Si response es null, significa que no se encontró ningún producto
      return response != null;
    } catch (e) {
      print('Error al verificar productos en categoría: $e');
      rethrow;
    }
  }

  /// Método para obtener productos por categoría
  Future<List<Producto>> getProductosByCategoria(int categoriaId) async {
    try {
      final response = await _client
          .from('producto')
          .select() // 'select()' sin argumentos selecciona todas las columnas
          .eq('idcategoria', categoriaId)
          .order('nombreproducto', ascending: true);

      // La respuesta de Supabase.select() en las últimas versiones ya es directamente List<Map<String, dynamic>>
      // no es necesario castear a (response as List).
      return response.map((json) => Producto.fromMap(json)).toList();
    } catch (e) {
      print('Error al obtener productos por categoría: $e');
      rethrow;
    }
  }

  Future<int> crearProducto(Producto producto) async {
    final response = await _client
        .from('producto')
        .insert(producto.toMap()
          ..removeWhere((key, value) => key == 'idproducto' && value == null))
        .select('idproducto')
        .single();

    return response['idproducto'] as int;
  }

  Future<void> actualizarProducto(Producto producto) async {
    if (producto.idproducto == null) {
      throw Exception('ID de producto es requerido para actualizar.');
    }

    await _client
        .from('producto')
        .update(producto.toMap()..remove('idproducto'))
        .eq('idproducto', producto.idproducto!);
  }

  Future<void> eliminarProducto(int idProducto) async {
    await _client.from('producto').delete().eq('idproducto', idProducto);
  }

  Future<String> subirImagen(String filePath, int idProducto) async {
    try {
      final file = File(filePath);
      final fileName = 'uploads/producto_${idProducto}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _client.storage
          .from(_bucketName)
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final signedUrl = await _client.storage
          .from(_bucketName)
          .createSignedUrl(fileName, 60 * 60 * 24 * 365); // 1 año

      return signedUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
      throw Exception('Error al subir la imagen: $e');
    }
  }

  Future<void> eliminarImagen(String imagenUrl) async {
    try {
      final pathSegments = Uri.parse(imagenUrl).pathSegments;
      final index = pathSegments.indexOf(_bucketName);
      if (index == -1 || index + 1 >= pathSegments.length) {
        throw Exception('Ruta inválida para eliminar imagen: $imagenUrl');
      }

      final filePath = pathSegments.sublist(index + 1).join('/');
      await _client.storage.from(_bucketName).remove([filePath]);
    } catch (e) {
      print('Error al eliminar imagen: $e');
      throw Exception('Error al eliminar imagen: $e');
    }
  }
}