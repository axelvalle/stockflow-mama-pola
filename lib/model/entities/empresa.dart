import 'package:mamapola_app_v1/model/entities/proveedor.dart';

class Empresa {
  final int idempresa;
  final String nombreempresa;
  final String? direccion;
  final String? contacto;
  final List<Proveedor> proveedores; // ✅ Agregado

  Empresa({
    required this.idempresa,
    required this.nombreempresa,
    this.direccion,
    this.contacto,
    this.proveedores = const [], // ✅ Inicialización
  });

  factory Empresa.fromMap(Map<String, dynamic> map) {
    final proveedorList = (map['proveedor'] as List?)?.map((e) => Proveedor.fromMap(e)).toList() ?? [];

    return Empresa(
      idempresa: map['idempresa'],
      nombreempresa: map['nombreempresa'],
      direccion: map['direccion'],
      contacto: map['contacto'],
      proveedores: proveedorList, // ✅ Seteamos desde join
    );
  }
}
