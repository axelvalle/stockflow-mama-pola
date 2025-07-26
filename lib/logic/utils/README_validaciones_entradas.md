# Validaciones de Entradas - Documentación

## Descripción

La clase `ValidacionesEntradas` proporciona métodos para validar las cantidades de entrada de inventario según las categorías de productos definidas en el sistema.

## Límites por Categoría

| Categoría             | Límite sugerido por entrada |
| --------------------- | --------------------------- |
| Refrescos / Gaseosas  | 5,000 unidades              |
| Galletas / Chocolates | 10,000 unidades             |
| Cerveza               | 3,000 unidades              |
| Bebidas energéticas   | 5,000 unidades              |
| Agua                  | 10,000 unidades             |
| Aseo y Varios         | 2,000 unidades              |
| Café                  | 5,000 unidades              |
| Tabaco                | 1,000 unidades              |
| Frescos Naturales     | 2,000 unidades              |
| Chips / Electrónica   | 500 unidades                |

## Métodos Disponibles

### Validación Básica

#### `validarCantidadEntrada(Categoria categoria, int cantidad)`
Valida si la cantidad está dentro del límite permitido para la categoría.

```dart
final categoria = Categoria(idcategoria: 1, nombrecategoria: 'Refrescos / Gaseosas');
final esValida = ValidacionesEntradas.validarCantidadEntrada(categoria, 3000);
// Retorna: true
```

#### `validarCantidadEntradaPorNombre(String nombreCategoria, int cantidad)`
Valida usando el nombre de la categoría directamente.

```dart
final esValida = ValidacionesEntradas.validarCantidadEntradaPorNombre('Chips / Electrónica', 300);
// Retorna: true
```

### Obtención de Información

#### `obtenerLimiteCategoria(String nombreCategoria)`
Obtiene el límite sugerido para una categoría específica.

```dart
final limite = ValidacionesEntradas.obtenerLimiteCategoria('Cerveza');
// Retorna: 3000
```

#### `obtenerInfoValidacion(Categoria categoria)`
Obtiene información completa de validación para una categoría.

```dart
final info = ValidacionesEntradas.obtenerInfoValidacion(categoria);
// Retorna: {
//   'categoria': 'Cerveza',
//   'limiteMaximo': 3000,
//   'cantidadMinima': 1,
//   'esCategoriaReconocida': true,
// }
```

### Mensajes de Error

#### `obtenerMensajeError(Categoria categoria, int cantidad)`
Obtiene un mensaje descriptivo del error de validación.

```dart
final mensaje = ValidacionesEntradas.obtenerMensajeError(categoria, 5000);
// Retorna: "La cantidad máxima permitida para Cerveza es 3000 unidades"
```

#### `obtenerMensajeErrorPorNombre(String nombreCategoria, int cantidad)`
Obtiene mensaje de error usando el nombre de la categoría.

### Utilidades

#### `obtenerTodasLasCategorias()`
Obtiene todas las categorías con sus límites.

#### `categoriaExiste(String nombreCategoria)`
Verifica si una categoría existe en el sistema.

#### `obtenerLimiteMaximo()` y `obtenerLimiteMinimo()`
Obtienen los límites más altos y más bajos entre todas las categorías.

#### `validarRangoCantidades(Categoria categoria, int cantidadMinima, int cantidadMaxima)`
Valida un rango de cantidades para una categoría.

## Ejemplo de Uso en Formularios

```dart
class ProductoForm extends StatefulWidget {
  @override
  _ProductoFormState createState() => _ProductoFormState();
}

class _ProductoFormState extends State<ProductoForm> {
  final _cantidadController = TextEditingController();
  Categoria? _categoriaSeleccionada;
  String? _errorCantidad;

  void _validarCantidad() {
    if (_categoriaSeleccionada != null) {
      final cantidad = int.tryParse(_cantidadController.text) ?? 0;
      final esValida = ValidacionesEntradas.validarCantidadEntrada(
        _categoriaSeleccionada!, 
        cantidad
      );
      
      setState(() {
        _errorCantidad = esValida ? null : 
          ValidacionesEntradas.obtenerMensajeError(_categoriaSeleccionada!, cantidad);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campo de cantidad
        TextFormField(
          controller: _cantidadController,
          decoration: InputDecoration(
            labelText: 'Cantidad',
            errorText: _errorCantidad,
            helperText: _categoriaSeleccionada != null 
              ? 'Máximo: ${ValidacionesEntradas.obtenerLimiteCategoria(_categoriaSeleccionada!.nombrecategoria)} unidades'
              : null,
          ),
          onChanged: (_) => _validarCantidad(),
        ),
      ],
    );
  }
}
```

## Integración con Controllers

```dart
class ProductoController extends ChangeNotifier {
  bool validarEntradaProducto(Categoria categoria, int cantidad) {
    return ValidacionesEntradas.validarCantidadEntrada(categoria, cantidad);
  }

  String? obtenerErrorValidacion(Categoria categoria, int cantidad) {
    final esValida = ValidacionesEntradas.validarCantidadEntrada(categoria, cantidad);
    return esValida ? null : ValidacionesEntradas.obtenerMensajeError(categoria, cantidad);
  }
}
```

## Notas Importantes

1. **Valor por defecto**: Si una categoría no existe en el sistema, se usa un límite de 1,000 unidades por defecto.

2. **Cantidad mínima**: Todas las validaciones requieren que la cantidad sea mayor a 0.

3. **Inmutabilidad**: El mapa de categorías es inmutable para prevenir modificaciones accidentales.

4. **Compatibilidad**: La clase es compatible con el modelo `Categoria` existente en el proyecto.

## Archivos Relacionados

- `validaciones_entradas.dart` - Clase principal de validaciones
- `ejemplo_validaciones_entradas.dart` - Ejemplos de uso
- `categoria.dart` - Modelo de entidad Categoria 