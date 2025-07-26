class Persona {
  final int? idpersona;
  final String? primerNombre;
  final String? segundoNombre;
  final String? primerApellido;
  final String? segundoApellido;
  final String? telefono;
  final String? direccion;
  final String? estado;

  Persona({
    this.idpersona,
    this.primerNombre,
    this.segundoNombre,
    this.primerApellido,
    this.segundoApellido,
    this.telefono,
    this.direccion,
    this.estado,
  });

  factory Persona.fromMap(Map<String, dynamic> map) => Persona(
    idpersona: map['idpersona'],
    primerNombre: map['primernombre'],
    segundoNombre: map['segundonombre'],
    primerApellido: map['primerapellido'],
    segundoApellido: map['segundoapellido'],
    telefono: map['telefono'],
    direccion: map['direccion'],
    estado: map['estado'],
  );

  Map<String, dynamic> toMap() => {
    'primernombre': primerNombre,
    'segundonombre': segundoNombre,
    'primerapellido': primerApellido,
    'segundoapellido': segundoApellido,
    'telefono': telefono,
    'direccion': direccion,
    'estado': estado,
  };
}