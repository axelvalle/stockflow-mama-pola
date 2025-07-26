class CatalogoProducto {
  final String? nombrecategoria;
  final int? idproducto;
  final String? nombreproducto;
  final double? precio;
  final String? estado;
  final int? minimoInventario;
  final String? proveedor;

  CatalogoProducto({
    this.nombrecategoria,
    this.idproducto,
    this.nombreproducto,
    this.precio,
    this.estado,
    this.minimoInventario,
    this.proveedor,
  });

  factory CatalogoProducto.fromMap(Map<String, dynamic> map) {
    return CatalogoProducto(
      nombrecategoria: map['nombrecategoria'] as String?,
      idproducto: map['idproducto'] as int?,
      nombreproducto: map['nombreproducto'] as String?,
      precio: (map['precio'] as num?)?.toDouble(),
      estado: map['estado'] as String?,
      minimoInventario: map['minimo_inventario'] as int?,
      proveedor: map['proveedor'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombrecategoria': nombrecategoria,
      'idproducto': idproducto,
      'nombreproducto': nombreproducto,
      'precio': precio,
      'estado': estado,
      'minimo_inventario': minimoInventario,
      'proveedor': proveedor,
    };
  }

  @override
  String toString() {
    return 'CatalogoProducto(nombrecategoria: $nombrecategoria, idproducto: $idproducto, nombreproducto: $nombreproducto, precio: $precio, estado: $estado, minimoInventario: $minimoInventario, proveedor: $proveedor)';
  }
} 