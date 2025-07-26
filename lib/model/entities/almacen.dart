class Almacen {
  final int id;
  final String nombre;
  final String? direccion;
  final String estado;

  Almacen({
    required this.id,
    required this.nombre,
    this.direccion,
    this.estado = 'activo',
  });

  factory Almacen.fromMap(Map<String, dynamic> map) {
    return Almacen(
      id: map['idalmacen'] as int,
      nombre: map['nombrealmacen'] as String,
      direccion: map['direccion'],
      estado: map['estado'] ?? 'activo',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idalmacen': id,
      'nombrealmacen': nombre,
      'direccion': direccion,
      'estado': estado,
    };
  }
}
