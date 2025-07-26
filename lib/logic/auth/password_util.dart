// logica_negocio/auth/password_utils.dart

import 'package:flutter/material.dart';

class PasswordUtils {
  /// Calcula la fuerza de la contraseña como un valor de 0.0 a 1.0
// Método para calcular la fortaleza de una contraseña
// Recibe una contraseña como String y retorna un valor double entre 0 y 1
static double calcularFuerza(String password) {
  // Inicializa la variable strength en 0, que almacenará el puntaje de la contraseña
  double strength = 0;

  // Criterio 1: Verifica si la contraseña tiene 6 o más caracteres
  // Si se cumple, suma 0.25 al puntaje
  if (password.length >= 6) strength += 0.25;

  // Criterio 2: Verifica si la contraseña contiene al menos una letra mayúscula
  // Usa una expresión regular [A-Z] para buscar letras de la A a la Z en mayúsculas
  // Si se cumple, suma 0.25 al puntaje
  if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;

  // Criterio 3: Verifica si la contraseña contiene al menos un número
  // Usa una expresión regular [0-9] para buscar dígitos del 0 al 9
  // Si se cumple, suma 0.25 al puntaje
  if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;

  // Criterio 4: Verifica si la contraseña contiene al menos un carácter especial
  // Usa una expresión regular para buscar caracteres como !, @, #, $, etc.
  // Si se cumple, suma 0.25 al puntaje
  if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;

  // Retorna el puntaje final, que será 0, 0.25, 0.5, 0.75 o 1.0
  // según cuántos criterios se cumplan
  return strength;
}

  /// Devuelve el color correspondiente según la fuerza
  static Color obtenerColor(double fuerza) {
    if (fuerza < 0.25) return Colors.red;
    if (fuerza < 0.5) return Colors.orange;
    if (fuerza < 0.75) return Colors.yellow[700]!;
    return Colors.green;
  }

  /// Devuelve una etiqueta textual según la fuerza
  static String obtenerEtiqueta(double fuerza) {
    if (fuerza < 0.25) return 'Débil';
    if (fuerza < 0.5) return 'Regular';
    if (fuerza < 0.75) return 'Buena';
    return 'Fuerte';
  }

  static String? validarPasswordSegura(String? value) {
  if (value == null || value.isEmpty) {
    return 'La contraseña es obligatoria';
  }
  if (value.length < 8) {
    return 'Debe tener al menos 8 caracteres';
  }
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Debe contener al menos una mayúscula';
  }
  if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
    return 'Debe incluir al menos un símbolo especial';
  }
  return null;
}

}
