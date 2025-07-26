import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/movimiento_inventario.dart';

class MovimientoInventarioRepository {
  final SupabaseClient client;

  MovimientoInventarioRepository(this.client);


  Future<List<Map<String, dynamic>>> getProductosPorCategoria() async {
    try {
      final response = await client
          .from('producto')
          .select('''
            idproducto,
            precio,
            categoria!inner(nombrecategoria)
          ''');

      final data = response as List<dynamic>;
      print('Datos crudos de Supabase: $data');

      // Agrupamos manualmente en el cliente
      final groupedData = <String, List<Map<String, dynamic>>>{};
      for (var item in data) {
        final categoria = item['categoria']['nombrecategoria'] as String;
        groupedData.putIfAbsent(categoria, () => []).add({
          'idproducto': item['idproducto'] as int,
          'precio': (item['precio'] is int) ? (item['precio'] as int).toDouble() : item['precio'] as double,
        });
      }

      final result = groupedData.entries.map((entry) {
        final categoria = entry.key;
        final productos = entry.value;
        final totalProductos = productos.length;
        final precios = productos.map((p) => p['precio'] as double).toList();
        final precioPromedio = precios.isEmpty ? 0.0 : precios.reduce((a, b) => a + b) / precios.length;
        final precioMinimo = precios.isEmpty ? 0.0 : precios.reduce((a, b) => a < b ? a : b);
        final precioMaximo = precios.isEmpty ? 0.0 : precios.reduce((a, b) => a > b ? a : b);

        return {
          'nombrecategoria': categoria,
          'total_productos': totalProductos,
          'precio_promedio': precioPromedio,
          'precio_minimo': precioMinimo,
          'precio_maximo': precioMaximo,
        };
      }).toList();

      print('Datos procesados por categoría: $result');
      return result;
    } catch (e) {
      print('Error en getProductosPorCategoria: $e');
      throw Exception('Error al obtener datos por categoría: $e');
    }
  }


  Future<List<MovimientoInventario>> getAll() async {
    try {
      final response = await client
          .from('movimiento_inventario')
          .select('''
            idmovimiento,
            idproducto,
            idalmacen,
            cantidad,
            tipo_movimiento,
            fecha,
            descripcion,
            producto!inner(nombreproducto),
            almacen!inner(nombrealmacen)
          ''');

      final data = response as List<dynamic>;
      print('Datos recibidos en getAll: $data');
      return data.map((json) => MovimientoInventario.fromMap(json)).toList();
    } catch (e) {
      print('Error en getAll: $e');
      throw Exception('Error al obtener movimientos: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMovimientosAnalytics({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      var query = client
          .from('movimiento_inventario')
          .select('''
            tipo_movimiento,
            cantidad,
            almacen!inner(nombrealmacen),
            fecha
          ''');

      if (fechaInicio != null) {
        // Crear fecha solo con año, mes y día, sin hora
        final fechaInicioSolo = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
        query = query.gte('fecha', fechaInicioSolo.toIso8601String());
      }
      if (fechaFin != null) {
        // Crear fecha solo con año, mes y día, sin hora
        final fechaFinSolo = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
        query = query.lte('fecha', fechaFinSolo.toIso8601String());
      }

      final response = await query;

      final data = response as List<dynamic>;
      return data.map((e) => {
            'nombrealmacen': (e['almacen']?['nombrealmacen'] as String?) ?? 'Desconocido',
            'tipo_movimiento': e['tipo_movimiento'] as String,
            'cantidad': e['cantidad'] as int,
            'fecha': e['fecha'] as String,
          }).toList();
    } catch (e) {
      print('Error en getMovimientosAnalytics: $e');
      throw Exception('Error al obtener datos analíticos: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> streamMovimientosAnalytics() {
    return client
        .from('movimiento_inventario')
        .stream(primaryKey: ['idmovimiento'])
        .map((data) {
          return data.map((e) => {
                'nombrealmacen': (e['almacen']?['nombrealmacen'] as String?) ?? 'Desconocido',
                'tipo_movimiento': e['tipo_movimiento'] as String,
                'cantidad': e['cantidad'] as int,
                'fecha': e['fecha'] as String,
              }).toList();
        });
  }

  Future<int> getStockActual({
    required int idProducto,
    required int idAlmacen,
  }) async {
    try {
      final response = await client
          .from('inventario')
          .select('cantidad')
          .eq('idproducto', idProducto)
          .eq('idalmacen', idAlmacen)
          .single();

      return response['cantidad'] as int? ?? 0;
    } catch (e) {
      print('Error en getStockActual: $e');
      throw Exception('Error al obtener stock actual: $e');
    }
  }

  Future<DateTime?> getUltimaEntrada({
    required int idProducto,
    required int idAlmacen,
  }) async {
    try {
      final response = await client
          .from('movimiento_inventario')
          .select('fecha')
          .eq('idproducto', idProducto)
          .eq('idalmacen', idAlmacen)
          .eq('tipo_movimiento', 'entrada')
          .order('fecha', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return DateTime.parse(response['fecha'] as String);
    } catch (e) {
      print('Error en getUltimaEntrada: $e');
      throw Exception('Error al obtener última entrada: $e');
    }
  }

  Future<MovimientoInventario> insert(MovimientoInventario movimiento) async {
    try {
      final response = await client
          .from('movimiento_inventario')
          .insert(movimiento.toMap())
          .select()
          .single();

      return MovimientoInventario.fromMap(response);
    } catch (e) {
      print('Error en insert: $e');
      throw Exception('Error al insertar movimiento: $e');
    }
  }

  Future<void> update(MovimientoInventario movimiento) async {
    try {
      await client
          .from('movimiento_inventario')
          .update(movimiento.toMap(includeId: true))
          .eq('idmovimiento', movimiento.id);
    } catch (e) {
      print('Error en update: $e');
      throw Exception('Error al actualizar movimiento: $e');
    }
  }

  Future<void> deleteById(int id) async {
    try {
      await client
          .from('movimiento_inventario')
          .delete()
          .eq('idmovimiento', id);
    } catch (e) {
      print('Error en deleteById: $e');
      throw Exception('Error al eliminar movimiento: $e');
    }
  }

  Future<List<MovimientoInventario>> getByProducto(int idProducto) async {
    try {
      final response = await client
          .from('movimiento_inventario')
          .select('''
            idmovimiento,
            idproducto,
            idalmacen,
            cantidad,
            tipo_movimiento,
            fecha,
            descripcion,
            producto!inner(nombreproducto),
            almacen!inner(nombrealmacen)
          ''')
          .eq('idproducto', idProducto);

      final data = response as List<dynamic>;
      return data.map((json) => MovimientoInventario.fromMap(json)).toList();
    } catch (e) {
      print('Error en getByProducto: $e');
      throw Exception('Error al filtrar por producto: $e');
    }
  }

  Future<List<MovimientoInventario>> getByAlmacen(int idAlmacen) async {
    try {
      final response = await client
          .from('movimiento_inventario')
          .select('''
            idmovimiento,
            idproducto,
            idalmacen,
            cantidad,
            tipo_movimiento,
            fecha,
            descripcion,
            producto!inner(nombreproducto),
            almacen!inner(nombrealmacen)
          ''')
          .eq('idalmacen', idAlmacen);

      final data = response as List<dynamic>;
      return data.map((json) => MovimientoInventario.fromMap(json)).toList();
    } catch (e) {
      print('Error en getByAlmacen: $e');
      throw Exception('Error al filtrar por almacén: $e');
    }
  }

  Future<List<MovimientoInventario>> getByTipo(String tipo) async {
    try {
      final response = await client
          .from('movimiento_inventario')
          .select('''
            idmovimiento,
            idproducto,
            idalmacen,
            cantidad,
            tipo_movimiento,
            fecha,
            descripcion,
            producto!inner(nombreproducto),
            almacen!inner(nombrealmacen)
          ''')
          .eq('tipo_movimiento', tipo);

      final data = response as List<dynamic>;
      return data.map((json) => MovimientoInventario.fromMap(json)).toList();
    } catch (e) {
      print('Error en getByTipo: $e');
      throw Exception('Error al filtrar por tipo: $e');
    }
  }

  Future<List<MovimientoInventario>> getByFechaRango(DateTime desde, DateTime hasta) async {
    try {
      final response = await client
          .from('movimiento_inventario')
          .select('''
            idmovimiento,
            idproducto,
            idalmacen,
            cantidad,
            tipo_movimiento,
            fecha,
            descripcion,
            producto!inner(nombreproducto),
            almacen!inner(nombrealmacen)
          ''')
          .gte('fecha', DateTime(desde.year, desde.month, desde.day).toIso8601String())
          .lte('fecha', DateTime(hasta.year, hasta.month, hasta.day).toIso8601String());

      final data = response as List<dynamic>;
      return data.map((json) => MovimientoInventario.fromMap(json)).toList();
    } catch (e) {
      print('Error en getByFechaRango: $e');
      throw Exception('Error al filtrar por rango de fechas: $e');
    }
  }
}