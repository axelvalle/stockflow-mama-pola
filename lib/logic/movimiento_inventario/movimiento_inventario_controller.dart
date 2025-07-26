import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../model/entities/movimiento_inventario.dart';
import '../../model/repository/movimiento_inventario_repository.dart';
import '../inventario/inventario_controller.dart';

class MovimientoInventarioController with ChangeNotifier {
  final Ref _ref;
  final MovimientoInventarioRepository _repository;

  List<MovimientoInventario> _movimientos = [];
  Map<String, Map<String, int>> _analyticsData = {};
  List<Map<String, dynamic>> _categoriaData = [];
  bool _isLoading = false;
  String? _error;
  String _search = '';
  String? _filtroTipo;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  MovimientoInventarioController(this._ref, SupabaseClient client)
      : _repository = MovimientoInventarioRepository(client) {
    print('Inicializando MovimientoInventarioController con SupabaseClient: $client');
    subscribeToAnalytics();
    loadCategoriaData();
  }

  List<MovimientoInventario> get movimientos => _movimientos;
  Map<String, Map<String, int>> get analyticsData => _analyticsData;
  List<Map<String, dynamic>> get categoriaData => _categoriaData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get search => _search;
  String? get filtroTipo => _filtroTipo;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;

  List<MovimientoInventario> get movimientosFiltrados {
    print('FiltroTipo: $_filtroTipo, Search: $_search, FechaInicio: $_fechaInicio, FechaFin: $_fechaFin, Movimientos totales: ${_movimientos.length}');
    final filtered = _movimientos.where((mov) {
      final coincideTipo = _filtroTipo == null || mov.tipoMovimiento.toLowerCase() == _filtroTipo?.toLowerCase();
      final coincideTexto = _search.isEmpty ||
          (mov.descripcion?.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
          mov.tipoMovimiento.toLowerCase().contains(_search.toLowerCase()) ||
          (mov.nombreProducto?.toLowerCase().contains(_search.toLowerCase()) ?? false);
      final coincideFecha = (_fechaInicio == null || mov.fecha.isAfter(_fechaInicio!)) &&
          (_fechaFin == null || mov.fecha.isBefore(_fechaFin!.add(const Duration(days: 1))));
      return coincideTipo && coincideTexto && coincideFecha;
    }).toList();
    print('Movimientos filtrados: ${filtered.length}');
    return filtered;
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setSearch(String value) {
    print('Estableciendo search: $value');
    _search = value;
    notifyListeners();
  }

  void setFiltroTipo(String? tipo) {
    print('Estableciendo filtroTipo: $tipo');
    _filtroTipo = tipo;
    notifyListeners();
  }

  void setFechaInicio(DateTime? fecha) {
    print('Estableciendo fechaInicio: $fecha');
    _fechaInicio = fecha;
    notifyListeners();
    loadMovimientosAnalytics();
  }

  void setFechaFin(DateTime? fecha) {
    print('Estableciendo fechaFin: $fecha');
    _fechaFin = fecha;
    notifyListeners();
    loadMovimientosAnalytics();
  }

  void clearFiltrosFechas() {
    print('Limpiando filtros de fechas');
    _fechaInicio = null;
    _fechaFin = null;
    notifyListeners();
    loadMovimientosAnalytics();
  }

  void clearFiltros() {
    _search = '';
    _filtroTipo = null;
    _fechaInicio = null;
    _fechaFin = null;
    notifyListeners();
  }

  Future<void> cargarMovimientos() async {
    _setLoading(true);
    try {
      print('Cargando movimientos...');
      _movimientos = await _repository.getAll();
      print('Movimientos cargados: ${_movimientos.length}');
      _error = null;
    } catch (e) {
      print('Error al cargar movimientos: $e');
      _error = 'Error al cargar movimientos: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMovimientosAnalytics() async {
    _setLoading(true);
    try {
      print('Cargando datos analíticos...');
      final analytics = await _repository.getMovimientosAnalytics(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
      final analyticsData = <String, Map<String, int>>{};
      for (var item in analytics) {
        final fecha = DateTime.parse(item['fecha'] as String);
        if (_fechaInicio != null && fecha.isBefore(_fechaInicio!)) continue;
        if (_fechaFin != null && fecha.isAfter(_fechaFin!.add(const Duration(days: 1)))) continue;

        final almacen = item['nombrealmacen'] as String;
        final tipo = item['tipo_movimiento'] as String;
        final cantidad = item['cantidad'] as int;

        analyticsData.putIfAbsent(almacen, () => {});
        analyticsData[almacen]!.update(tipo, (value) => value + cantidad, ifAbsent: () => cantidad);
      }
      _analyticsData = analyticsData;
      print('Datos analíticos cargados: ${analyticsData.length} almacenes');
      _error = null;
    } catch (e) {
      print('Error en loadMovimientosAnalytics: $e');
      _error = 'Error al cargar datos analíticos: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCategoriaData() async {
    _setLoading(true);
    try {
      print('Cargando datos de categorías...');
      _categoriaData = await _repository.getProductosPorCategoria();
      print('Datos de categorías cargados: ${_categoriaData.length} categorías');
      _error = null;
    } catch (e) {
      print('Error en loadCategoriaData: $e');
      _error = 'Error al cargar datos de categorías: $e';
    } finally {
      _setLoading(false);
    }
  }

  void subscribeToAnalytics() {
    print('Suscribiendo al stream de analíticos...');
    _repository.streamMovimientosAnalytics().listen((analytics) {
      try {
        final analyticsData = <String, Map<String, int>>{};
        for (var item in analytics) {
          final fecha = DateTime.parse(item['fecha'] as String);
          if (_fechaInicio != null && fecha.isBefore(_fechaInicio!)) continue;
          if (_fechaFin != null && fecha.isAfter(_fechaFin!.add(const Duration(days: 1)))) continue;

          final almacen = item['nombrealmacen'] as String;
          final tipo = item['tipo_movimiento'] as String;
          final cantidad = item['cantidad'] as int;

          analyticsData.putIfAbsent(almacen, () => {});
          analyticsData[almacen]!.update(tipo, (value) => value + cantidad, ifAbsent: () => cantidad);
        }
        _analyticsData = analyticsData;
        print('Stream actualizado: ${analyticsData.length} almacenes');
        _error = null;
        notifyListeners();
      } catch (e) {
        print('Error en subscribeToAnalytics: $e');
        _error = 'Error en stream analíticos: $e';
        notifyListeners();
      }
    }, onError: (e) {
      print('Error en stream: $e');
      _error = 'Error en stream analíticos: $e';
      notifyListeners();
    });
  }

  Future<void> agregarMovimiento(MovimientoInventario movimiento) async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado. Por favor, inicia sesión.');
      }
      print('Usuario autenticado: ${user.id}');
      print(
          'Iniciando agregarMovimiento: tipo=${movimiento.tipoMovimiento}, idProducto=${movimiento.idProducto}, idAlmacen=${movimiento.idAlmacen}, cantidad=${movimiento.cantidad}, fecha=${movimiento.fecha}, descripcion=${movimiento.descripcion}');

      final tipo = movimiento.tipoMovimiento.toLowerCase();
      if (!['entrada', 'salida', 'ajuste'].contains(tipo)) {
        throw Exception('Tipo de movimiento inválido: $tipo. Debe ser entrada, salida o ajuste.');
      }

      if (movimiento.idProducto <= 0) {
        throw Exception('ID de producto inválido: ${movimiento.idProducto}');
      }
      if (movimiento.idAlmacen <= 0) {
        throw Exception('ID de almacén inválido: ${movimiento.idAlmacen}');
      }
      if (movimiento.cantidad <= 0 && tipo != 'ajuste') {
        throw Exception('La cantidad debe ser mayor que 0 para entradas y salidas');
      }

      if (tipo == 'salida' || (tipo == 'ajuste' && movimiento.cantidad < 0)) {
        final stockActual = await _repository.getStockActual(
          idProducto: movimiento.idProducto,
          idAlmacen: movimiento.idAlmacen,
        );
        print('Stock actual: $stockActual');
        if (movimiento.cantidad.abs() > stockActual) {
          throw Exception('No hay suficiente stock. Disponible: $stockActual');
        }
      }

      if (tipo == 'salida') {
        final ultimaEntrada = await _repository.getUltimaEntrada(
          idProducto: movimiento.idProducto,
          idAlmacen: movimiento.idAlmacen,
        );
        print('Última entrada: $ultimaEntrada');
        if (ultimaEntrada != null) {
          // Comparar solo las fechas sin considerar la hora
          final fechaMovimiento = DateTime(movimiento.fecha.year, movimiento.fecha.month, movimiento.fecha.day);
          final fechaUltimaEntrada = DateTime(ultimaEntrada.year, ultimaEntrada.month, ultimaEntrada.day);
          
          if (fechaMovimiento.isBefore(fechaUltimaEntrada)) {
            throw Exception(
                'La fecha de salida no puede ser anterior a la última entrada: ${DateFormat('dd/MM/yyyy').format(ultimaEntrada)}');
          }
        }
      }

      print('Insertando movimiento en movimiento_inventario: ${movimiento.toMap()}');
      final insertedMovimiento = await _repository.insert(movimiento);
      print('Movimiento insertado correctamente con id: ${insertedMovimiento.id}');

      final delta = tipo == 'entrada'
          ? movimiento.cantidad
          : tipo == 'salida'
              ? -movimiento.cantidad
              : movimiento.cantidad;
      print('Delta calculado: $delta');

      await _ref.read(inventarioControllerProvider.notifier).modificarCantidad(
            idProducto: movimiento.idProducto,
            idAlmacen: movimiento.idAlmacen,
            cantidadCambio: delta,
          );
      print('Inventario actualizado correctamente');

      await cargarMovimientos();
      print('Movimientos recargados');
      _error = null;
    } catch (e) {
      print('Error en agregarMovimiento: $e');
      _error = 'Error al agregar movimiento: $e';
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> actualizarMovimiento(MovimientoInventario movimiento) async {
    _setLoading(true);
    try {
      print('Actualizando movimiento: id=${movimiento.id}');
      await _repository.update(movimiento);
      print('Movimiento actualizado correctamente');
      await cargarMovimientos();
      _error = null;
    } catch (e) {
      print('Error al actualizar: $e');
      _error = 'Error al actualizar movimiento: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> eliminarMovimiento(int id) async {
    _setLoading(true);
    try {
      print('Eliminando movimiento: id=$id');
      await _repository.deleteById(id);
      print('Movimiento eliminado correctamente');
      await cargarMovimientos();
      _error = null;
    } catch (e) {
      print('Error al eliminar: $e');
      _error = 'Error al eliminar movimiento: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> filtrarPorProducto(int idProducto) async {
    _setLoading(true);
    try {
      print('Filtrando por producto: idProducto=$idProducto');
      _movimientos = await _repository.getByProducto(idProducto);
      print('Movimientos filtrados: ${_movimientos.length}');
      _error = null;
    } catch (e) {
      print('Error al filtrar por producto: $e');
      _error = 'Error al filtrar por producto: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> filtrarPorAlmacen(int idAlmacen) async {
    _setLoading(true);
    try {
      print('Filtrando por almacén: idAlmacen=$idAlmacen');
      _movimientos = await _repository.getByAlmacen(idAlmacen);
      print('Movimientos filtrados: ${_movimientos.length}');
      _error = null;
    } catch (e) {
      print('Error al filtrar por almacén: $e');
      _error = 'Error al filtrar por almacén: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> filtrarPorTipo(String tipo) async {
    _setLoading(true);
    try {
      print('Filtrando por tipo: tipo=$tipo');
      _movimientos = await _repository.getByTipo(tipo);
      print('Movimientos filtrados: ${_movimientos.length}');
      _error = null;
    } catch (e) {
      print('Error al filtrar por tipo: $e');
      _error = 'Error al filtrar por tipo: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> filtrarPorRangoFechas(DateTime desde, DateTime hasta) async {
    _setLoading(true);
    try {
      print('Filtrando por rango de fechas: desde=$desde, hasta=$hasta');
      _movimientos = await _repository.getByFechaRango(desde, hasta);
      print('Movimientos filtrados: ${_movimientos.length}');
      _error = null;
    } catch (e) {
      print('Error al filtrar por fechas: $e');
      _error = 'Error al filtrar por fechas: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

final movimientoInventarioControllerProvider =
    ChangeNotifierProvider<MovimientoInventarioController>((ref) {
  final client = Supabase.instance.client;
  print('Inicializando movimientoInventarioControllerProvider con SupabaseClient: $client');
  return MovimientoInventarioController(ref, client);
});