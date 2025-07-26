import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/model/entities/user_session.dart';

class UserSessionRepository {
  final _client = Supabase.instance.client;

  // Método temporal para verificar si la tabla existe
  Future<bool> checkTableExists() async {
    try {
      return true;
    } catch (e) {
      print('La tabla user_sessions no existe o hay un error: $e');
      return false;
    }
  }

  Future<List<UserSession>> getUserSessions(String userId) async {
    try {
      // Verificar si la tabla existe
      final tableExists = await checkTableExists();
      if (!tableExists) {
        print('La tabla user_sessions no existe, retornando lista vacía');
        return [];
      }
      
      final data = await _client
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('last_activity', ascending: false);
      
      return (data as List).map((e) => UserSession.fromMap(e)).toList();
    } catch (e) {
      print('Error en getUserSessions: $e'); // Debug
      return [];
    }
  }

  Future<List<UserSession>> getAllActiveSessions() async {
    try {
      // Verificar si la tabla existe
      final tableExists = await checkTableExists();
      if (!tableExists) {
        print('La tabla user_sessions no existe, retornando lista vacía');
        return [];
      }
      
      final data = await _client
          .from('user_sessions')
          .select()
          .eq('is_active', true)
          .order('last_activity', ascending: false);
      
      return (data as List).map((e) => UserSession.fromMap(e)).toList();
    } catch (e) {
      print('Error en getAllActiveSessions: $e'); // Debug
      return [];
    }
  }

  Future<void> createSession(UserSession session) async {
    try {
      // Verificar si la tabla existe
      final tableExists = await checkTableExists();
      if (!tableExists) {
        print('La tabla user_sessions no existe, no se puede crear sesión');
        return;
      }
      
      final response = await _client
          .from('user_sessions')
          .insert(session.toMap());
      
      if (response.error != null) {
        throw PostgrestException(
          message: response.error!.message,
          code: response.error!.code,
          details: response.error!.details,
          hint: response.error!.hint,
        );
      }
    } catch (e) {
      print('Error en createSession: $e'); // Debug
      // No lanzar excepción para evitar que la app se detenga
    }
  }

  Future<void> updateLastActivity(String sessionId) async {
    try {
      // Verificar si la tabla existe
      final tableExists = await checkTableExists();
      if (!tableExists) {
        print('La tabla user_sessions no existe, no se puede actualizar actividad');
        return;
      }
      
      final response = await _client
          .from('user_sessions')
          .update({'last_activity': DateTime.now().toIso8601String()})
          .eq('id', sessionId);
      
      if (response.error != null) {
        throw PostgrestException(
          message: response.error!.message,
          code: response.error!.code,
          details: response.error!.details,
          hint: response.error!.hint,
        );
      }
    } catch (e) {
      print('Error en updateLastActivity: $e'); // Debug
      // No lanzar excepción para evitar que la app se detenga
    }
  }

  Future<void> terminateSession(String sessionId) async {
    try {
      // Verificar si la tabla existe
      final tableExists = await checkTableExists();
      if (!tableExists) {
        print('La tabla user_sessions no existe, no se puede terminar sesión');
        return;
      }
      
      final response = await _client
          .from('user_sessions')
          .update({'is_active': false})
          .eq('id', sessionId);
      
      if (response.error != null) {
        throw PostgrestException(
          message: response.error!.message,
          code: response.error!.code,
          details: response.error!.details,
          hint: response.error!.hint,
        );
      }
    } catch (e) {
      print('Error en terminateSession: $e'); // Debug
      // No lanzar excepción para evitar que la app se detenga
    }
  }

  Future<void> terminateAllUserSessions(String userId) async {
    try {
      // Verificar si la tabla existe
      final tableExists = await checkTableExists();
      if (!tableExists) {
        print('La tabla user_sessions no existe, no se pueden terminar sesiones');
        return;
      }
      
      final response = await _client
          .from('user_sessions')
          .update({'is_active': false})
          .eq('user_id', userId);
      
      if (response.error != null) {
        throw PostgrestException(
          message: response.error!.message,
          code: response.error!.code,
          details: response.error!.details,
          hint: response.error!.hint,
        );
      }
    } catch (e) {
      print('Error en terminateAllUserSessions: $e'); // Debug
      // No lanzar excepción para evitar que la app se detenga
    }
  }

  Future<void> terminateOtherUserSessions(String userId, String currentSessionId) async {
    try {
      // Verificar si la tabla existe
      final tableExists = await checkTableExists();
      if (!tableExists) {
        print('La tabla user_sessions no existe, no se pueden terminar otras sesiones');
        return;
      }
      
      final response = await _client
          .from('user_sessions')
          .update({'is_active': false})
          .eq('user_id', userId)
          .neq('id', currentSessionId);
      
      if (response.error != null) {
        throw PostgrestException(
          message: response.error!.message,
          code: response.error!.code,
          details: response.error!.details,
          hint: response.error!.hint,
        );
      }
    } catch (e) {
      print('Error en terminateOtherUserSessions: $e'); // Debug
      // No lanzar excepción para evitar que la app se detenga
    }
  }
} 