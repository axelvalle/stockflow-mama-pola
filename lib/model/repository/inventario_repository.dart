import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/inventario.dart';

class InventarioRepository {
  final SupabaseClient supabaseClient;

  InventarioRepository(this.supabaseClient);

  /// Obtiene una lista de inventario con información de producto, almacén y categoría
  Future<List<Inventario>> obtenerInventario({
    String? searchTerm,
    int? idAlmacen,
    int? idCategoria,
    double? precioMin,
    double? precioMax,
    int? stockMin,
    int? stockMax,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      // Usamos dynamic para evitar problemas de tipado
      dynamic query = supabaseClient
          .from('inventario')
          .select('''
            idinventario,
            idproducto,
            idalmacen,
            cantidad,
            producto (nombreproducto, precio, idcategoria, categoria (nombrecategoria)),
            almacen (nombrealmacen)
          ''');

      // Aplicar filtro por término de búsqueda
      if (searchTerm != null && searchTerm.isNotEmpty) {
        query = query.ilike('producto.nombreproducto', '%$searchTerm%');
        print('Aplicando filtro: searchTerm=$searchTerm');
      }

      // Aplicar filtro por almacén
      if (idAlmacen != null) {
        query = query.eq('idalmacen', idAlmacen);
        print('Aplicando filtro: idAlmacen=$idAlmacen');
      }

      // Aplicar filtro por categoría
      if (idCategoria != null) {
        query = query.eq('producto.idcategoria', idCategoria);
        query = query.not('producto.idcategoria', 'is', null);
        print('Aplicando filtro: idCategoria=$idCategoria, excluyendo idcategoria nulo');
      }

      // Aplicar filtros de precio
      if (precioMin != null) {
        query = query.gte('producto.precio', precioMin);
        print('Aplicando filtro: precioMin=$precioMin');
      }
      if (precioMax != null) {
        query = query.lte('producto.precio', precioMax);
        print('Aplicando filtro: precioMax=$precioMax');
      }

      // Aplicar filtros de stock
      if (stockMin != null) {
        query = query.gte('cantidad', stockMin);
        print('Aplicando filtro: stockMin=$stockMin');
      }
      if (stockMax != null) {
        query = query.lte('cantidad', stockMax);
        print('Aplicando filtro: stockMax=$stockMax');
      }

      // Aplicar ordenamiento
      if (orderBy != null && orderBy.isNotEmpty) {
        String field = orderBy;
        String? referencedTable;
        if (orderBy == 'nombreproducto' || orderBy == 'precio') {
          referencedTable = 'producto';
        } else if (orderBy == 'cantidad') {
          referencedTable = null; // Campo de la tabla inventario
        }
        query = query.order(field, ascending: ascending, referencedTable: referencedTable);
        print('Aplicando orden: $orderBy, ascending=$ascending');
      } else {
        query = query.order('idproducto', ascending: true);
        print('Aplicando orden por defecto: idproducto asc');
      }

      final response = await query;

      final data = response as List<dynamic>;
      print('Inventarios obtenidos: ${data.length} registros');

      return data.map((e) => Inventario.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error al obtener inventario: $e');
      throw Exception('Error al obtener inventario: $e');
    }
  }

  /// Obtiene un inventario único por producto y almacén
  Future<Inventario?> obtenerInventarioPorProductoAlmacen(int idProducto, int idAlmacen) async {
    try {
      final response = await supabaseClient
          .from('inventario')
          .select('''
            idinventario,
            idproducto,
            idalmacen,
            cantidad,
            producto (nombreproducto, precio, idcategoria, categoria (nombrecategoria)),
            almacen (nombrealmacen)
          ''')
          .eq('idproducto', idProducto)
          .eq('idalmacen', idAlmacen)
          .maybeSingle();

      if (response == null) {
        print('No se encontró inventario para idProducto=$idProducto, idAlmacen=$idAlmacen');
        return null;
      }

      return Inventario.fromMap(response);
    } catch (e) {
      print('Error al obtener inventario por producto y almacén: $e');
      rethrow;
    }
  }

  /// Actualiza la cantidad en inventario (suma o resta)
  Future<void> actualizarCantidad({
    required int idProducto,
    required int idAlmacen,
    required int cantidadCambio,
  }) async {
    print('Iniciando actualizarCantidad: idProducto=$idProducto, idAlmacen=$idAlmacen, cantidadCambio=$cantidadCambio');
    try {
      // Obtener inventario actual
      final response = await supabaseClient
          .from('inventario')
          .select()
          .eq('idproducto', idProducto)
          .eq('idalmacen', idAlmacen)
          .maybeSingle();

      int nuevaCantidad;

      if (response == null) {
        // Si no existe el registro, crearlo para movimientos de entrada o ajuste positivo
        if (cantidadCambio < 0) {
          throw Exception('No se puede realizar una salida o ajuste negativo sin inventario existente');
        }
        print('Creando nuevo registro en inventario...');
        final insertResponse = await supabaseClient.from('inventario').insert({
          'idproducto': idProducto,
          'idalmacen': idAlmacen,
          'cantidad': cantidadCambio,
        }).select();

        if (insertResponse.isEmpty) {
          throw Exception('Error al crear inventario: No se devolvió el registro insertado');
        }
        nuevaCantidad = cantidadCambio;
        print('Registro creado con cantidad: $nuevaCantidad');
      } else {
        // Si existe, actualizar la cantidad
        final currentInventario = Inventario.fromMap(response);
        nuevaCantidad = currentInventario.cantidad + cantidadCambio;

        if (nuevaCantidad < 0) {
          throw Exception('Stock insuficiente. No se puede disminuir más de lo disponible.');
        }

        print('Actualizando inventario: idinventario=${currentInventario.idinventario}, nuevaCantidad=$nuevaCantidad');
        final updateResponse = await supabaseClient
            .from('inventario')
            .update({'cantidad': nuevaCantidad})
            .eq('idinventario', currentInventario.idinventario)
            .select();

        if (updateResponse.isEmpty) {
          throw Exception('Error al actualizar inventario: No se devolvió el registro actualizado');
        }
        print('Inventario actualizado con éxito');
      }
    } catch (e) {
      print('Error en actualizarCantidad: $e');
      rethrow;
    }
  }

  /// Crear un nuevo inventario (cuando no existe)
  Future<void> crearInventario({
    required int idProducto,
    required int idAlmacen,
    required int cantidadInicial,
  }) async {
    print('Creando inventario: idProducto=$idProducto, idAlmacen=$idAlmacen, cantidadInicial=$cantidadInicial');
    try {
      final insertResponse = await supabaseClient.from('inventario').insert({
        'idproducto': idProducto,
        'idalmacen': idAlmacen,
        'cantidad': cantidadInicial,
      }).select();

      if (insertResponse.isEmpty) {
        throw Exception('Error al crear inventario: No se devolvió el registro insertado');
      }
      print('Inventario creado con éxito');
    } catch (e) {
      print('Error al crear inventario: $e');
      rethrow;
    }
  }
}