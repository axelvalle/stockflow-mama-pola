import 'persona.dart';
import 'empresa.dart';

class Proveedor {
  final int? id;
  final int idPersona;
  final int? idEmpresa;
  final Persona? persona;
  final Empresa? empresa;

  Proveedor({
    this.id, 
    required this.idPersona, 
    this.idEmpresa,
    this.persona,
    this.empresa,
  });

  factory Proveedor.fromMap(Map<String, dynamic> map) => Proveedor(
    id: map['idproveedor'],
    idPersona: map['idpersona'],
    idEmpresa: map['idempresa'],
    persona: map['persona'] != null ? Persona.fromMap(map['persona']) : null,
    empresa: map['empresa'] != null ? Empresa.fromMap(map['empresa']) : null,
  );

  Map<String, dynamic> toMap() => {
    'idpersona': idPersona,
    'idempresa': idEmpresa,
  };
}
