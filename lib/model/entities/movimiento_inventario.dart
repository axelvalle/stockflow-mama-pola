// lib/model/entities/movimiento_inventario.dart
class MovimientoInventario {
  final int id;
  final int idProducto;
  final int idAlmacen;
  final int cantidad;
  final String tipoMovimiento; // entrada | salida | ajuste
  final DateTime fecha;
  final String? descripcion;
  final String? nombreProducto; // Nuevo campo
  final String? nombreAlmacen; // Nuevo campo

  MovimientoInventario({
    required this.id,
    required this.idProducto,
    required this.idAlmacen,
    required this.cantidad,
    required this.tipoMovimiento,
    required this.fecha,
    this.descripcion,
    this.nombreProducto,
    this.nombreAlmacen,
  });

  factory MovimientoInventario.fromMap(Map<String, dynamic> map) {
    return MovimientoInventario(
      id: map['idmovimiento'] as int,
      idProducto: map['idproducto'] as int,
      idAlmacen: map['idalmacen'] as int,
      cantidad: map['cantidad'] as int,
      tipoMovimiento: map['tipo_movimiento'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      descripcion: map['descripcion'] as String?,
      nombreProducto: map['producto'] != null ? map['producto']['nombreproducto'] as String? : null,
      nombreAlmacen: map['almacen'] != null ? map['almacen']['nombrealmacen'] as String? : null,
    );
  }

  Map<String, dynamic> toMap({bool includeId = false}) {
    // Crear una fecha solo con año, mes y día, sin hora
    final fechaSolo = DateTime(fecha.year, fecha.month, fecha.day);
    
    final map = {
      'idproducto': idProducto,
      'idalmacen': idAlmacen,
      'cantidad': cantidad,
      'tipo_movimiento': tipoMovimiento,
      'fecha': fechaSolo.toIso8601String(),
      'descripcion': descripcion,
    };

    if (includeId) {
      map['idmovimiento'] = id;
    }

    return map;
  }
}