import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ErrorDisplayType { snackBar, dialog, banner }

class UIErrorHandler {
  static void showError(
    BuildContext context,
    dynamic error, {
    ErrorDisplayType displayType = ErrorDisplayType.snackBar,
    String? customTitle,
    VoidCallback? onRetry,
    bool dismissible = true,
  }) {
    final message = getFriendlyMessage(error);
    final title = customTitle ?? _getErrorTitle(error);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..hideCurrentMaterialBanner();

    switch (displayType) {
      case ErrorDisplayType.snackBar:
        _showSnackBarError(context, message);
        break;
      case ErrorDisplayType.dialog:
        _showDialogError(context, title, message, onRetry, dismissible: dismissible);
        break;
      case ErrorDisplayType.banner:
        _showBannerError(context, message);
        break;
    }
  }

  static bool _isNetworkError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        error.toString().toLowerCase().contains('connection') ||
        error.toString().toLowerCase().contains('network') ||
        error.toString().toLowerCase().contains('offline') ||
        error.toString().toLowerCase().contains('host lookup');
  }

  static String getFriendlyMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (error is Exception && error.toString().startsWith('Exception: ')) {
      final customMessage = error.toString().substring('Exception: '.length);
      if (customMessage.contains('Intento') ||
          customMessage.contains('Advertencia') ||
          customMessage.contains('bloqueado') ||
          customMessage.contains('productos asociados') ||
          customMessage.contains('proveedores asociados')) {
        return customMessage;
      }
    }

    if (error is AuthException) {
      if (errorStr.contains('invalid login credentials') ||
          errorStr.contains('credentials')) {
        return 'Correo electrónico o contraseña incorrectos. Por favor verifica tus datos.';
      }
      if (errorStr.contains('user not found') ||
          errorStr.contains('invalid session') ||
          errorStr.contains('session') ||
          errorStr.contains('token')) {
        return 'Tu sesión ha sido cerrada debido a un baneo o eliminación de la cuenta. Por favor, contacta al soporte.';
      }
      return 'Error de autenticación: ${error.message}. Por favor, intenta de nuevo.';
    }

    if (error is PostgrestException) {
      if (error.code == '23503') {
        if (error.message.contains('producto') && error.message.contains('idproveedor')) {
          return 'No puedes eliminar este proveedor porque tiene productos asociados. Por favor, reasigna o elimina los productos que dependen de este proveedor antes de eliminarlo.';
        }
        if (error.message.contains('producto') && error.message.contains('idcategoria')) {
          return 'No puedes eliminar esta categoría porque tiene productos asociados. Por favor, reasigna o elimina los productos de esta categoría primero.';
        }
        if (error.message.contains('proveedor') && error.message.contains('idempresa')) {
          return 'No puedes eliminar esta empresa porque tiene proveedores asociados. Elimina o reasigna primero los proveedores relacionados a esta empresa.';
        }
        return 'Esta acción no se puede completar porque el registro está en uso en otra tabla.';
      }
      if (error.code == '23505') {
        return 'Este correo electrónico ya está registrado. ¿Olvidaste tu contraseña?';
      }
    }

    if (errorStr.contains('email_not_confirmed') ||
        errorStr.contains('email not confirmed')) {
      return 'Tu correo electrónico no está verificado. Por favor revisa tu bandeja de entrada y confirma tu correo.';
    }

    if (_isNetworkError(error)) {
      return 'Error de conexión. Verifica tu conexión a internet e intenta nuevamente.';
    }

    if (errorStr.contains('already registered') ||
        errorStr.contains('user already exists') ||
        errorStr.contains('email already in use')) {
      return 'Este correo electrónico ya está registrado. ¿Olvidaste tu contraseña?';
    } else if (errorStr.contains('invalid email') ||
        errorStr.contains('malformed email')) {
      return 'Por favor ingresa un correo electrónico válido (ejemplo: usuario@dominio.com)';
    } else if (errorStr.contains('verify your email') ||
        errorStr.contains('email verification') ||
        errorStr.contains('tu correo aún no está verificado')) {
      return 'Registro exitoso. Por favor verifica tu correo electrónico siguiendo el enlace que te enviamos.';
    } else if (errorStr.contains('password') || errorStr.contains('contraseña')) {
      if (errorStr.contains('short') || errorStr.contains('6 characters')) {
        return 'La contraseña debe tener al menos 6 caracteres';
      }
      return 'Usuario o Contraseña no válidos';
    } else if (errorStr.contains('invalid login credentials') ||
        errorStr.contains('credentials')) {
      return 'Correo electrónico o contraseña incorrectos. Por favor verifica tus datos.';
    } else if (errorStr.contains('too many requests')) {
      return 'Demasiados intentos. Por favor espera un momento antes de intentar nuevamente.';
    }

    return 'Ocurrió un error inesperado. Por favor, intenta de nuevo más tarde.';
  }

  static void _showSnackBarError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            });
          },
        ),
      ),
    );
  }

  static void _showDialogError(
    BuildContext context,
    String title,
    String message,
    VoidCallback? onRetry, {
    bool dismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onRetry();
              },
              child: const Text('Reintentar'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  static void _showBannerError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        actions: [
          TextButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              });
            },
            child: const Text('CERRAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static String _getErrorTitle(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (error is AuthException) {
      if (errorStr.contains('user not found') ||
          errorStr.contains('invalid session') ||
          errorStr.contains('session') ||
          errorStr.contains('token')) {
        return 'Sesión Cerrada';
      }
      return 'Error de Autenticación';
    }

    if (error is PostgrestException && error.code == '23503') {
      if (error.message.contains('producto') && error.message.contains('idproveedor')) {
        return 'Proveedor en uso';
      }
      if (error.message.contains('producto') && error.message.contains('idcategoria')) {
        return 'Categoría en uso';
      }
      if (error.message.contains('proveedor') && error.message.contains('idempresa')) {
        return 'Empresa en uso';
      }
      return 'Elemento en uso';
    }
    if (error is PostgrestException && error.code == '23505') {
      return 'Correo ya registrado';
    }
    if (_isNetworkError(error)) return 'Problema de conexión';
    if (errorStr.contains('email_not_confirmed') ||
        errorStr.contains('email not confirmed')) {
      return 'Correo no verificado';
    }
    if (errorStr.contains('already registered')) return 'Usuario existente';
    if (errorStr.contains('email')) return 'Error con el correo';
    if (errorStr.contains('password')) return 'Error con la contraseña';
    return 'Ocurrió un error';
  }
}
