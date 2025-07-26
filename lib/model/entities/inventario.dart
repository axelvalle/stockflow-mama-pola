import 'package:equatable/equatable.dart';

class Inventario extends Equatable {
  final int idinventario;
  final int idproducto;
  final int idalmacen;
  final int cantidad;
  final int? idCategoria; // Nuevo campo
  final String? nombreProducto;
  final String? nombreAlmacen;
  final String? nombreCategoria;
  final double? precio;
  final int stockMinimo; // Nuevo campo

  const Inventario({
    required this.idinventario,
    required this.idproducto,
    required this.idalmacen,
    required this.cantidad,
    this.idCategoria,
    this.nombreProducto,
    this.nombreAlmacen,
    this.nombreCategoria,
    this.precio,
    this.stockMinimo = 0,
  });

  factory Inventario.fromMap(Map<String, dynamic> map) {
    return Inventario(
      idinventario: map['idinventario'] as int,
      idproducto: map['idproducto'] as int,
      idalmacen: map['idalmacen'] as int,
      cantidad: map['cantidad'] as int,
      idCategoria: map['producto']?['idcategoria'] as int?, // Mapeo del idCategoria
      nombreProducto: map['producto']?['nombreproducto'] as String?,
      nombreAlmacen: map['almacen']?['nombrealmacen'] as String?,
      nombreCategoria: map['producto']?['categoria']?['nombrecategoria'] as String?,
      precio: map['producto']?['precio']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idinventario': idinventario,
      'idproducto': idproducto,
      'idalmacen': idalmacen,
      'cantidad': cantidad,
      'idcategoria': idCategoria,
    };
  }

  @override
  List<Object?> get props => [
        idinventario,
        idproducto,
        idalmacen,
        cantidad,
        idCategoria,
        nombreProducto,
        nombreAlmacen,
        nombreCategoria,
        precio,
      ];
}