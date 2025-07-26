import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/model/entities/persona.dart';

class PersonaRepository {
  final _client = Supabase.instance.client;

  Future<int> createPersona(Persona persona) async {
    final res = await _client.from('persona').insert(persona.toMap()).select('idpersona').single();
    return res['idpersona'];
  }

  Future<List<Persona>> getPersonas() async {
    final data = await _client.from('persona').select();
    return (data as List).map((e) => Persona.fromMap(e)).toList();
  }

    Future<void> updatePersona(Persona persona) async {
    await _client.from('persona').update(persona.toMap()).match({'idpersona': persona.idpersona!});
  }

  Future<void> deletePersona(int idPersona) async {
    await _client.from('persona').delete().match({'idpersona': idPersona});
  }

}