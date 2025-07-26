class Producto {
  final int? idproducto;
  final String nombreproducto;
  final double precio;
  final int idcategoria;
  final int idproveedor;
  final String? estado;
  final String? imagenUrl;
  final int? minimoInventario;

  Producto({
    this.idproducto,
    required this.nombreproducto,
    required this.precio,
    required this.idcategoria,
    required this.idproveedor,
    this.estado,
    this.imagenUrl,
    this.minimoInventario,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      idproducto: map['idproducto'] as int?,
      nombreproducto: map['nombreproducto'] as String,
      precio: (map['precio'] as num).toDouble(),
      idcategoria: map['idcategoria'] as int,
      idproveedor: map['idproveedor'] as int,
      estado: map['estado'] as String?,
      imagenUrl: map['imagen_url'] as String?,
      minimoInventario: map['minimo_inventario'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idproducto': idproducto,
      'nombreproducto': nombreproducto,
      'precio': precio,
      'idcategoria': idcategoria,
      'idproveedor': idproveedor,
      'estado': estado,
      'imagen_url': imagenUrl,
      'minimo_inventario': minimoInventario,
    };
  }

  Producto copyWith({
    int? idproducto,
    String? nombreproducto,
    double? precio,
    int? idcategoria,
    int? idproveedor,
    String? estado,
    String? imagenUrl,
    int? minimoInventario,
  }) {
    return Producto(
      idproducto: idproducto ?? this.idproducto,
      nombreproducto: nombreproducto ?? this.nombreproducto,
      precio: precio ?? this.precio,
      idcategoria: idcategoria ?? this.idcategoria,
      idproveedor: idproveedor ?? this.idproveedor,
      estado: estado ?? this.estado,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      minimoInventario: minimoInventario ?? this.minimoInventario,
    );
  }
}
