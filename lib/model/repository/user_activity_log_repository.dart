import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/model/entities/user_activity_log.dart';

class UserActivityLogRepository {
  final _client = Supabase.instance.client;

  // Método para verificar si la tabla existe realmente
  Future<bool> checkTableExists() async {
    try {
      // Intentar hacer una consulta simple para verificar si la tabla existe
      await _client
          .from('user_activity_log')
          .select('id')
          .limit(1);
      return true;
    } catch (e) {
      print('La tabla user_activity_log no existe o hay un error: $e');
      return false;
    }
  }

  Future<List<UserActivityLog>> getUserActivityLog(String userId, {int? limit}) async {
    try {
      print('Intentando obtener actividad para usuario: $userId'); // Debug
      
      var query = _client
          .from('user_activity_log')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final data = await query;
      print('Datos obtenidos: ${data.length} registros'); // Debug
      return (data as List).map((e) => UserActivityLog.fromMap(e)).toList();
    } catch (e) {
      print('Error en getUserActivityLog: $e'); // Debug
      // Si la tabla no existe, retornar lista vacía
      if (e.toString().contains('relation "user_activity_log" does not exist')) {
        print('La tabla user_activity_log no existe en la base de datos');
        return [];
      }
      // Para otros errores, también retornar lista vacía para evitar que la app se detenga
      return [];
    }
  }

  Future<List<UserActivityLog>> getAllActivityLog({int? limit}) async {
    try {
      var query = _client
          .from('user_activity_log')
          .select()
          .order('created_at', ascending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final data = await query;
      print('Datos obtenidos de getAllActivityLog: ${data.length} registros'); // Debug
      return (data as List).map((e) => UserActivityLog.fromMap(e)).toList();
    } catch (e) {
      print('Error en getAllActivityLog: $e'); // Debug
      // Si la tabla no existe, retornar lista vacía
      if (e.toString().contains('relation "user_activity_log" does not exist')) {
        print('La tabla user_activity_log no existe en la base de datos');
        return [];
      }
      return [];
    }
  }

  Future<void> logActivity(UserActivityLog activity) async {
    try {
      final response = await _client
          .from('user_activity_log')
          .insert(activity.toMap());
      
      if (response.error != null) {
        throw PostgrestException(
          message: response.error!.message,
          code: response.error!.code,
          details: response.error!.details,
          hint: response.error!.hint,
        );
      }
    } catch (e) {
      print('Error en logActivity: $e'); // Debug
      // No lanzar excepción para evitar que la app se detenga
    }
  }

  Future<void> logLoginActivity(String userId, String ipAddress, String userAgent) async {
    try {
      final activity = UserActivityLog(
        userId: userId,
        actionType: 'login',
        actionDetails: {'status': 'success'},
        ipAddress: ipAddress,
        userAgent: userAgent,
      );
      
      await logActivity(activity);
    } catch (e) {
      print('Error en logLoginActivity: $e'); // Debug
      // No lanzar excepción para evitar que la app se detenga
    }
  }

  Future<void> logLogoutActivity(String userId, String ipAddress, String userAgent) async {
    try {
      final activity = UserActivityLog(
        userId: userId,
        actionType: 'logout',
        actionDetails: {'status': 'success'},
        ipAddress: ipAddress,
        userAgent: userAgent,
      );
      
      await logActivity(activity);
    } catch (e) {
      print('Error en logLogoutActivity: $e'); // Debug
      // No lanzar excepción para evitar que la app se detenga
    }
  }

  Future<void> logActionActivity(String userId, String actionType, Map<String, dynamic>? details, String? ipAddress, String? userAgent) async {
    try {
      final activity = UserActivityLog(
        userId: userId,
        actionType: actionType,
        actionDetails: details,
        ipAddress: ipAddress,
        userAgent: userAgent,
      );
      
      await logActivity(activity);
    } catch (e) {
      print('Error en logActionActivity: $e'); // Debug
      // No lanzar excepción para evitar que la app se detenga
    }
  }

  Future<List<UserActivityLog>> getActivityByType(String userId, String actionType, {int? limit}) async {
    try {
      var query = _client
          .from('user_activity_log')
          .select()
          .eq('user_id', userId)
          .eq('action_type', actionType)
          .order('created_at', ascending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final data = await query;
      return (data as List).map((e) => UserActivityLog.fromMap(e)).toList();
    } catch (e) {
      print('Error en getActivityByType: $e'); // Debug
      return [];
    }
  }

  Future<List<UserActivityLog>> getActivityByDateRange(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final data = await _client
          .from('user_activity_log')
          .select()
          .eq('user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);
      
      return (data as List).map((e) => UserActivityLog.fromMap(e)).toList();
    } catch (e) {
      print('Error en getActivityByDateRange: $e'); // Debug
      return [];
    }
  }
} 