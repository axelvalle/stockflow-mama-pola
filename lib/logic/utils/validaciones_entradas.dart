import 'package:mamapola_app_v1/model/entities/categoria.dart';

/// Clase para manejar validaciones de entradas de inventario por categoría
class ValidacionesEntradas {
  
  /// Mapa de límites sugeridos por categoría
  static const Map<String, int> _limitesCategoria = {
    'Refrescos / Gaseosas': 5000,
    'Galletas / Chocolates': 10000,
    'Cerveza': 3000,
    'Bebidas energéticas': 5000,
    'Agua': 10000,
    'Aseo y Varios': 2000,
    'Café': 5000,
    'Tabaco': 1000,
    'Frescos Naturales': 2000,
    'Chips / Electrónica': 500,
  };

  /// Obtiene el límite sugerido para una categoría específica
  /// 
  /// [nombreCategoria] - Nombre de la categoría
  /// Retorna el límite sugerido o 1000 como valor por defecto
  static int obtenerLimiteCategoria(String nombreCategoria) {
    return _limitesCategoria[nombreCategoria] ?? 1000;
  }

  /// Valida si la cantidad de entrada está dentro del límite permitido
  /// 
  /// [categoria] - Objeto Categoria
  /// [cantidad] - Cantidad a validar
  /// Retorna true si la cantidad es válida, false en caso contrario
  static bool validarCantidadEntrada(Categoria categoria, int cantidad) {
    final limite = obtenerLimiteCategoria(categoria.nombrecategoria);
    return cantidad > 0 && cantidad <= limite;
  }

  /// Valida si la cantidad de entrada está dentro del límite permitido usando el nombre de la categoría
  /// 
  /// [nombreCategoria] - Nombre de la categoría
  /// [cantidad] - Cantidad a validar
  /// Retorna true si la cantidad es válida, false en caso contrario
  static bool validarCantidadEntradaPorNombre(String nombreCategoria, int cantidad) {
    final limite = obtenerLimiteCategoria(nombreCategoria);
    return cantidad > 0 && cantidad <= limite;
  }

  /// Obtiene el mensaje de error para una validación fallida
  /// 
  /// [categoria] - Objeto Categoria
  /// [cantidad] - Cantidad que causó el error
  /// Retorna un mensaje descriptivo del error
  static String obtenerMensajeError(Categoria categoria, int cantidad) {
    final limite = obtenerLimiteCategoria(categoria.nombrecategoria);
    
    if (cantidad <= 0) {
      return 'La cantidad debe ser mayor a 0';
    }
    
    if (cantidad > limite) {
      return 'La cantidad máxima permitida para ${categoria.nombrecategoria} es $limite unidades';
    }
    
    return 'Cantidad válida';
  }

  /// Obtiene el mensaje de error para una validación fallida usando el nombre de la categoría
  /// 
  /// [nombreCategoria] - Nombre de la categoría
  /// [cantidad] - Cantidad que causó el error
  /// Retorna un mensaje descriptivo del error
  static String obtenerMensajeErrorPorNombre(String nombreCategoria, int cantidad) {
    final limite = obtenerLimiteCategoria(nombreCategoria);
    
    if (cantidad <= 0) {
      return 'La cantidad debe ser mayor a 0';
    }
    
    if (cantidad > limite) {
      return 'La cantidad máxima permitida para $nombreCategoria es $limite unidades';
    }
    
    return 'Cantidad válida';
  }

  /// Obtiene todas las categorías con sus límites
  /// 
  /// Retorna un Map con todas las categorías y sus límites correspondientes
  static Map<String, int> obtenerTodasLasCategorias() {
    return Map.unmodifiable(_limitesCategoria);
  }

  /// Verifica si una categoría existe en el sistema de validaciones
  /// 
  /// [nombreCategoria] - Nombre de la categoría a verificar
  /// Retorna true si la categoría existe, false en caso contrario
  static bool categoriaExiste(String nombreCategoria) {
    return _limitesCategoria.containsKey(nombreCategoria);
  }

  /// Obtiene el límite más alto entre todas las categorías
  /// 
  /// Retorna el valor del límite más alto
  static int obtenerLimiteMaximo() {
    if (_limitesCategoria.isEmpty) return 0;
    return _limitesCategoria.values.reduce((a, b) => a > b ? a : b);
  }

  /// Obtiene el límite más bajo entre todas las categorías
  /// 
  /// Retorna el valor del límite más bajo
  static int obtenerLimiteMinimo() {
    if (_limitesCategoria.isEmpty) return 0;
    return _limitesCategoria.values.reduce((a, b) => a < b ? a : b);
  }

  /// Valida un rango de cantidades para una categoría
  /// 
  /// [categoria] - Objeto Categoria
  /// [cantidadMinima] - Cantidad mínima del rango
  /// [cantidadMaxima] - Cantidad máxima del rango
  /// Retorna true si el rango es válido, false en caso contrario
  static bool validarRangoCantidades(Categoria categoria, int cantidadMinima, int cantidadMaxima) {
    final limite = obtenerLimiteCategoria(categoria.nombrecategoria);
    return cantidadMinima > 0 && 
           cantidadMaxima <= limite && 
           cantidadMinima <= cantidadMaxima;
  }

  /// Obtiene información de validación completa para una categoría
  /// 
  /// [categoria] - Objeto Categoria
  /// Retorna un Map con información de validación
  static Map<String, dynamic> obtenerInfoValidacion(Categoria categoria) {
    final limite = obtenerLimiteCategoria(categoria.nombrecategoria);
    return {
      'categoria': categoria.nombrecategoria,
      'limiteMaximo': limite,
      'cantidadMinima': 1,
      'esCategoriaReconocida': categoriaExiste(categoria.nombrecategoria),
    };
  }
} 