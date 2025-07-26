import 'package:flutter/material.dart';
import 'package:mamapola_app_v1/logic/injection/theme_data.dart';

class AppTheme {
  static const String appTitle = 'Mama Pola App';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
    );
  }

  static Widget buildErrorWidget(FlutterErrorDetails errorDetails, BuildContext context) {
    // Este método será implementado en el error handler
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
} 