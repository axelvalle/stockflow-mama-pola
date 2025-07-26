class Categoria {
  final int? idcategoria;
  final String nombrecategoria;

  const Categoria({
    this.idcategoria,
    required this.nombrecategoria,
  });

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      idcategoria: map['idcategoria'] as int?,
      nombrecategoria: map['nombrecategoria'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idcategoria': idcategoria,
      'nombrecategoria': nombrecategoria,
    };
  }
}