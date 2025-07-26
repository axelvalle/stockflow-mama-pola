// lib/ui/movimiento_inventario/movimiento_inventario_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import '../../logic/almacen/almacen_controller.dart';
import '../../logic/movimiento_inventario/movimiento_inventario_controller.dart';
import '../../logic/producto/producto_controller.dart';
import '../../model/entities/movimiento_inventario.dart';

class MovimientoInventarioForm extends ConsumerStatefulWidget {
  const MovimientoInventarioForm({super.key});

  @override
  ConsumerState<MovimientoInventarioForm> createState() => _MovimientoInventarioFormState();
}

class _MovimientoInventarioFormState extends ConsumerState<MovimientoInventarioForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _tipoMovimientoSelected;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productoControllerProvider.notifier).cargarProductos();
      ref.read(almacenControllerProvider.notifier).cargarAlmacenes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productoState = ref.watch(productoControllerProvider);
    final almacenState = ref.watch(almacenControllerProvider);
    final movimientoController = ref.watch(movimientoInventarioControllerProvider);

    final initialValues = {
      'idproducto': null,
      'idalmacen': null,
      'cantidad': '',
      'tipo_movimiento': null,
      'fecha': DateTime.now(),
      'descripcion': '',
      'ajuste_signo': '+',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Movimiento'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FormBuilder(
              key: _formKey,
              initialValue: initialValues,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Datos del Movimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Mostrar mensaje de error del controlador
                  if (movimientoController.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        movimientoController.error!,
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),

                  // Producto
                  const Text('Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (productoState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (productoState.productos.isEmpty)
                    const Text(
                      'No hay productos disponibles',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    FormBuilderDropdown<int>(
                      name: 'idproducto',
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        prefixIcon: Icon(Icons.shopping_cart),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(errorText: 'Seleccione un producto'),
                      items: productoState.productos.map((prod) {
                        return DropdownMenuItem(
                          value: prod.idproducto,
                          child: Text(prod.nombreproducto),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),

                  // Almacén
                  const Text('Almacén', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (almacenState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (almacenState.almacenes.isEmpty)
                    const Text(
                      'No hay almacenes disponibles',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    FormBuilderDropdown<int>(
                      name: 'idalmacen',
                      decoration: const InputDecoration(
                        labelText: 'Almacén',
                        prefixIcon: Icon(Icons.warehouse),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(errorText: 'Seleccione un almacén'),
                      items: almacenState.almacenes.map((alm) {
                        return DropdownMenuItem(
                          value: alm.id,
                          child: Text(alm.nombre),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),

                  // Cantidad
                  FormBuilderTextField(
                    name: 'cantidad',
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'Campo obligatorio'),
                      FormBuilderValidators.integer(errorText: 'Debe ser un número entero'),
                      FormBuilderValidators.min(1, errorText: 'Debe ser mayor a 0'),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // Tipo de Movimiento
                  FormBuilderDropdown<String>(
                    name: 'tipo_movimiento',
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Movimiento',
                      prefixIcon: Icon(Icons.compare_arrows),
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(errorText: 'Seleccione un tipo'),
                    items: const [
                      DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                      DropdownMenuItem(value: 'salida', child: Text('Salida')),
                      DropdownMenuItem(value: 'ajuste', child: Text('Ajuste')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _tipoMovimientoSelected = val;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Ajuste signo (solo visible si tipo_movimiento == 'ajuste')
                  if (_tipoMovimientoSelected == 'ajuste')
                    FormBuilderDropdown<String>(
                      name: 'ajuste_signo',
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Ajuste',
                        prefixIcon: Icon(Icons.swap_vert),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(errorText: 'Seleccione el signo del ajuste'),
                      items: const [
                        DropdownMenuItem(value: '+', child: Text('Aumentar (+)')),
                        DropdownMenuItem(value: '-', child: Text('Disminuir (-)')),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Fecha
                  FormBuilderDateTimePicker(
                    name: 'fecha',
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                    inputType: InputType.date,
                    format: DateFormat('dd/MM/yyyy'),
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.date_range),
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(errorText: 'Seleccione una fecha'),
                  ),

                  const SizedBox(height: 16),

                  // Descripción
                  FormBuilderTextField(
                    name: 'descripcion',
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // Guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: movimientoController.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(movimientoController.isLoading ? 'Guardando...' : 'Guardar'),
                      onPressed: movimientoController.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState?.saveAndValidate() ?? false) {
                                final values = _formKey.currentState!.value;
                                print('Datos del formulario: $values');

                                // Ajustar cantidad para ajustes negativos
                                int cantidadAjustada = int.parse(values['cantidad'].toString());
                                if (_tipoMovimientoSelected == 'ajuste' && values['ajuste_signo'] == '-') {
                                  cantidadAjustada = -cantidadAjustada;
                                }

                                final nuevoMovimiento = MovimientoInventario(
                                  id: 0,
                                  idProducto: values['idproducto'] as int,
                                  idAlmacen: values['idalmacen'] as int,
                                  cantidad: cantidadAjustada,
                                  tipoMovimiento: values['tipo_movimiento'] as String,
                                  fecha: values['fecha'] as DateTime,
                                  descripcion: values['descripcion'] as String?,
                                );
                                print('Movimiento a guardar: ${nuevoMovimiento.toMap()}');

                                try {
                                  // Limpiar error previo
                                  ref.read(movimientoInventarioControllerProvider.notifier).setError(null);

                                  await ref
                                      .read(movimientoInventarioControllerProvider.notifier)
                                      .agregarMovimiento(nuevoMovimiento);

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Movimiento guardado correctamente')),
                                    );
                                    Navigator.pop(context, true);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al guardar: $e')),
                                    );
                                  }
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Complete todos los campos obligatorios')),
                                  );
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}