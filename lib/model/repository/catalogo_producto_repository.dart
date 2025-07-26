import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/catalogo_producto.dart';

class CatalogoProductoRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene todos los productos del catálogo desde la vista
  Future<List<CatalogoProducto>> getCatalogoProductos() async {
    try {
      final response = await _supabase
          .from('view_catalogo_productos_empresa')
          .select('*')
          .order('nombrecategoria')
          .order('nombreproducto');

      return (response as List<dynamic>)
          .map((item) => CatalogoProducto.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al obtener catálogo de productos: $e');
      rethrow;
    }
  }

  /// Obtiene productos del catálogo filtrados por categoría
  Future<List<CatalogoProducto>> getCatalogoProductosPorCategoria(String categoria) async {
    try {
      final response = await _supabase
          .from('view_catalogo_productos_empresa')
          .select('*')
          .eq('nombrecategoria', categoria)
          .order('nombreproducto');

      return (response as List<dynamic>)
          .map((item) => CatalogoProducto.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al obtener catálogo de productos por categoría: $e');
      rethrow;
    }
  }

  /// Obtiene productos del catálogo filtrados por proveedor
  Future<List<CatalogoProducto>> getCatalogoProductosPorProveedor(String proveedor) async {
    try {
      final response = await _supabase
          .from('view_catalogo_productos_empresa')
          .select('*')
          .eq('proveedor', proveedor)
          .order('nombrecategoria')
          .order('nombreproducto');

      return (response as List<dynamic>)
          .map((item) => CatalogoProducto.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al obtener catálogo de productos por proveedor: $e');
      rethrow;
    }
  }

  /// Obtiene productos del catálogo filtrados por estado
  Future<List<CatalogoProducto>> getCatalogoProductosPorEstado(String estado) async {
    try {
      final response = await _supabase
          .from('view_catalogo_productos_empresa')
          .select('*')
          .eq('estado', estado)
          .order('nombrecategoria')
          .order('nombreproducto');

      return (response as List<dynamic>)
          .map((item) => CatalogoProducto.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al obtener catálogo de productos por estado: $e');
      rethrow;
    }
  }

  /// Busca productos en el catálogo por nombre
  Future<List<CatalogoProducto>> buscarProductos(String termino) async {
    try {
      final response = await _supabase
          .from('view_catalogo_productos_empresa')
          .select('*')
          .ilike('nombreproducto', '%$termino%')
          .order('nombrecategoria')
          .order('nombreproducto');

      return (response as List<dynamic>)
          .map((item) => CatalogoProducto.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al buscar productos en catálogo: $e');
      rethrow;
    }
  }
} 