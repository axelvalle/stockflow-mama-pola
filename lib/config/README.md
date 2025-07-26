# Configuración de la Aplicación

Esta carpeta contiene los archivos de configuración centralizada de la aplicación Mama Pola.

## Archivos

### `app_routes.dart`
- **Propósito**: Centraliza todas las rutas de la aplicación
- **Contenido**: 
  - Constantes de rutas
  - Mapa de rutas con sus widgets correspondientes
  - Método `onGenerateRoute` para rutas dinámicas
- **Beneficios**: 
  - Fácil mantenimiento de rutas
  - Reutilización de rutas en toda la app
  - Separación clara de responsabilidades

### `app_theme.dart`
- **Propósito**: Configuración centralizada de temas
- **Contenido**:
  - Tema claro y oscuro
  - Título de la aplicación
  - Configuración de Material 3
- **Beneficios**:
  - Consistencia visual en toda la app
  - Fácil cambio de temas
  - Reutilización de configuraciones

### `error_handler.dart`
- **Propósito**: Manejo global de errores
- **Contenido**:
  - Widget de error para errores críticos
  - Widget de error para errores de inicialización
- **Beneficios**:
  - Manejo consistente de errores
  - Mejor experiencia de usuario
  - Fácil debugging

## Uso

```dart
// En main.dart
import 'package:mamapola_app_v1/config/app_routes.dart';
import 'package:mamapola_app_v1/config/app_theme.dart';
import 'package:mamapola_app_v1/config/error_handler.dart';

// Usar rutas
routes: AppRoutes.getRoutes(),
onGenerateRoute: AppRoutes.onGenerateRoute,

// Usar temas
theme: AppTheme.lightTheme,
darkTheme: AppTheme.darkTheme,

// Usar manejo de errores
ErrorWidget.builder = (errorDetails) => 
    AppErrorHandler.buildErrorWidget(errorDetails, context);
``` 