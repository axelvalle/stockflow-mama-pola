// logic/injection/theme_data.dart

import 'package:flutter/material.dart';

// Colores para el tema CLARO (sin cambios)
final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF673AB7), // Un tono de morado medio (Deep Purple 500)
  primary: const Color(0xFF673AB7), // Violeta principal
  onPrimary: Colors.white, // Texto sobre el violeta
  primaryContainer: const Color(0xFFEADDFF), // Contenedor primario (violeta claro)
  onPrimaryContainer: const Color(0xFF21005D), // Texto sobre contenedor primario
  secondary: const Color(0xFF009688), // Turquesa (Teal 500)
  onSecondary: Colors.white,
  secondaryContainer: const Color(0xFF76D7C4), // Contenedor secundario (turquesa claro)
  onSecondaryContainer: const Color(0xFF00201D),
  tertiary: const Color(0xFFE91E63), // Rosa vibrante (Pink 500)
  onTertiary: Colors.white,
  surface: const Color(0xFFF7F2FA), // Fondo principal (blanco muy sutil)
  onSurface: const Color(0xFF1D1B20), // Texto sobre el fondo
  surfaceVariant: const Color(0xFFE7E0EB), // Fondo secundario (gris claro)
  onSurfaceVariant: const Color(0xFF49454E), // Texto sobre fondo secundario
  outline: const Color(0xFF7A757F), // Contornos y divisores
  error: const Color(0xFFBA1A1A), // Colores de error
  onError: Colors.white,
  brightness: Brightness.light,
);

// Colores para el tema OSCURO - ¡VERSION MEJORADA con tertiaryContainer!
final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF673AB7), // Mismo tono de morado como base
  primary: const Color(0xFFBB86FC),
  onPrimary: const Color(0xFF000000),
  primaryContainer: const Color.fromARGB(255, 40, 10, 109),
  onPrimaryContainer: const Color(0xFFFFFFFF),

  secondary: const Color(0xFF03DAC6),
  onSecondary: const Color(0xFF000000),
  secondaryContainer: const Color(0xFF018786), // Turquesa oscuro para contenedores secundarios
  onSecondaryContainer: const Color(0xFFFFFFFF), // Texto blanco

  tertiary: const Color(0xFFFF4081),
  onTertiary: const Color(0xFF000000),
  tertiaryContainer: const Color(0xFFFF0266),
  onTertiaryContainer: const Color(0xFFFFFFFF), 

  surface: const Color.fromARGB(255, 24, 24, 24),
  onSurface: const Color(0xFFFFFFFF),
  surfaceVariant: const Color(0xFF2C2C2C),
  onSurfaceVariant: const Color(0xFFE0E0E0),
  outline: const Color(0xFF666666),
  error: const Color(0xFFCF6679),
  onError: const Color(0xFF000000),
  brightness: Brightness.dark,
);