import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';

class SupabaseService {
  static Future<void> initialize() async {
    try {
      String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Las variables de entorno de Supabase no están configuradas');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      throw Exception('Error al inicializar Supabase: ${UIErrorHandler.getFriendlyMessage(e)}');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
} 