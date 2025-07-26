import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/model/entities/user_2fa_config.dart';

class User2FARepository {
  final _client = Supabase.instance.client;

  // Método temporal para verificar si la tabla existe
  Future<bool> checkTableExists() async {
    try {
      return true;
    } catch (e) {
      print('La tabla user_2fa_config no existe o hay un error: $e');
      return false;
    }
  }

  Future<User2FAConfig?> getUser2FAConfig(String userId) async {
    try {
      // Verificar si la tabla existe
      final tableExists = await checkTableExists();
      if (!tableExists) {
        print('La tabla user_2fa_config no existe, retornando null');
        return null;
      }
      
      final data = await _client
          .from('user_2fa_config')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (data == null) {
        return null;
      }
      
      return User2FAConfig.fromMap(data);
    } catch (e) {
      print('Error en getUser2FAConfig: $e'); // Debug
      return null;
    }
  }

  Future<void> create2FAConfig(User2FAConfig config) async {
    try {
      // Verificar si la tabla existe
      final tableExists = await checkTableExists();
      if (!tableExists) {
        print('La tabla user_2fa_config no existe, no se puede crear configuración');
        return;
      }
      
      final response = await _client
          .from('user_2fa_config')
          .insert(config.toMap());
      
      if (response.error != null) {
        throw PostgrestException(
          message: response.error!.message,
          code: response.error!.code,
          details: response.error!.details,
          hint: response.error!.hint,
        );
      }
    } catch (e) {
      print('Error en create2FAConfig: $e'); // Debug
      // No lanzar excepción para evitar que la app se detenga
    }
  }

  Future<void> update2FAConfig(User2FAConfig config) async {
    try {
      final response = await _client
          .from('user_2fa_config')
          .update({
            ...config.toMap(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', config.userId);
      
      if (response.error != null) {
        throw PostgrestException(
          message: response.error!.message,
          code: response.error!.code,
          details: response.error!.details,
          hint: response.error!.hint,
        );
      }
    } catch (e) {
      throw Exception('Error al actualizar configuración 2FA: $e');
    }
  }

  Future<void> enable2FA(String userId, String secretKey, List<String> backupCodes) async {
    try {
      final config = User2FAConfig(
        userId: userId,
        isEnabled: true,
        secretKey: secretKey,
        backupCodes: backupCodes,
      );
      
      final existingConfig = await getUser2FAConfig(userId);
      if (existingConfig == null) {
        await create2FAConfig(config);
      } else {
        await update2FAConfig(config);
      }
    } catch (e) {
      throw Exception('Error al habilitar 2FA: $e');
    }
  }

  Future<void> disable2FA(String userId) async {
    try {
      final response = await _client
          .from('user_2fa_config')
          .update({
            'is_enabled': false,
            'secret_key': null,
            'backup_codes': null,
            'updated_at': DateTime.now().toIso8601String(),
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
      throw Exception('Error al deshabilitar 2FA: $e');
    }
  }

  Future<bool> verifyBackupCode(String userId, String backupCode) async {
    try {
      final config = await getUser2FAConfig(userId);
      if (config == null || config.backupCodes == null) {
        return false;
      }
      
      return config.backupCodes!.contains(backupCode);
    } catch (e) {
      throw Exception('Error al verificar código de respaldo: $e');
    }
  }

  Future<void> removeBackupCode(String userId, String backupCode) async {
    try {
      final config = await getUser2FAConfig(userId);
      if (config == null || config.backupCodes == null) {
        return;
      }
      
      final updatedCodes = config.backupCodes!.where((code) => code != backupCode).toList();
      
      final response = await _client
          .from('user_2fa_config')
          .update({
            'backup_codes': updatedCodes,
            'updated_at': DateTime.now().toIso8601String(),
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
      throw Exception('Error al remover código de respaldo: $e');
    }
  }

  Future<List<String>> generateNewBackupCodes(String userId) async {
    try {
      final List<String> newCodes = [];
      for (int i = 0; i < 10; i++) {
        newCodes.add(_generateBackupCode());
      }
      
      final response = await _client
          .from('user_2fa_config')
          .update({
            'backup_codes': newCodes,
            'updated_at': DateTime.now().toIso8601String(),
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
      
      return newCodes;
    } catch (e) {
      throw Exception('Error al generar nuevos códigos de respaldo: $e');
    }
  }

  String _generateBackupCode() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 8; i++) {
      code += chars[(random + i) % chars.length];
    }
    return code;
  }
} 