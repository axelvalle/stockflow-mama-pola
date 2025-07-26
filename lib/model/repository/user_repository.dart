// model/repository/user_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase.from('usuarios_app').select();
      return response;
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Eliminar de usuarios_app
      await _supabase.from('usuarios_app').delete().eq('id', userId);
      // Llamar a la Edge Function para eliminar de auth.users
      final response = await _supabase.functions.invoke('delete-auth-user', body: {'user_id': userId});
      if (response.status != 200) {
        throw Exception('Error al eliminar usuario de auth.users: ${response.data['error']}');
      }
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final response = await _supabase
          .from('usuarios_app')
          .update({'rol': newRole})
          .eq('id', userId);
      
      if (response.error != null) {
        throw PostgrestException(
          message: response.error!.message,
          code: response.error!.code,
          details: response.error!.details,
          hint: response.error!.hint,
        );
      }
    } catch (e) {
      throw Exception('Error al actualizar rol del usuario: $e');
    }
  }

  Future<void> updateUserStatus(String userId, String newStatus) async {
    try {
      final response = await _supabase
          .from('usuarios_app')
          .update({'estado': newStatus})
          .eq('id', userId);
      
      if (response.error != null) {
        throw PostgrestException(
          message: response.error!.message,
          code: response.error!.code,
          details: response.error!.details,
          hint: response.error!.hint,
        );
      }
    } catch (e) {
      throw Exception('Error al actualizar estado del usuario: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLoginAttempts() async {
    try {
      final response = await _supabase
          .from('login_attempts')
          .select('*, usuarios_app(email)')
          .eq('is_blocked', true)
          .order('last_attempt', ascending: false);
      return response;
    } catch (e) {
      throw Exception('Error al obtener intentos de login: $e');
    }
  }

  Future<void> resetLoginAttempts(String userId) async {
    try {
      final response = await _supabase
          .from('login_attempts')
          .update({
            'attempts': 0,
            'is_blocked': false,
            'last_attempt': DateTime.now().toIso8601String(),
          })
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
      throw Exception('Error al resetear intentos de login: $e');
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      final response = await _supabase
          .from('login_attempts')
          .update({
            'attempts': 0,
            'is_blocked': false,
            'last_attempt': DateTime.now().toIso8601String(),
          })
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
      throw Exception('Error al desbloquear usuario: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('usuarios_app')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Error al obtener usuario por ID: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final response = await _supabase
          .from('usuarios_app')
          .select()
          .eq('rol', role)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      throw Exception('Error al obtener usuarios por rol: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUsersByStatus(String status) async {
    try {
      final response = await _supabase
          .from('usuarios_app')
          .select()
          .eq('estado', status)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      throw Exception('Error al obtener usuarios por estado: $e');
    }
  }

  Future<void> updateUserProfile(String userId, String nombre, String telefono) async {
    try {
      final response = await _supabase
          .from('usuarios_app')
          .update({
            'nombre': nombre,
            'telefono': telefono,
          })
          .eq('id', userId);
      if (response.error != null) {
        throw PostgrestException(
          message: response.error!.message,
          code: response.error!.code,
          details: response.error!.details,
          hint: response.error!.hint,
        );
      }
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }
}