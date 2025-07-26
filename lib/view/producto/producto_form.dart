import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mamapola_app_v1/logic/categoria/categoria_controller.dart';
import 'package:mamapola_app_v1/logic/producto/producto_controller.dart';
import 'package:mamapola_app_v1/logic/proveedor/proveedor_controller.dart';
import 'package:mamapola_app_v1/model/entities/producto.dart';
import 'package:mamapola_app_v1/view/categoria/categoria_form.dart';

class ProductoForm extends ConsumerStatefulWidget {
  final Producto? producto;

  const ProductoForm({super.key, this.producto});

  @override
  ConsumerState<ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends ConsumerState<ProductoForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(proveedorControllerProvider.notifier).loadProveedores();
      ref.read(categoriaControllerProvider.notifier).loadCategorias();
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productoController = ref.watch(productoControllerProvider);
    final proveedorState = ref.watch(proveedorControllerProvider);
    final categoriaState = ref.watch(categoriaControllerProvider);
    final initialValues = {
      'nombreproducto': widget.producto?.nombreproducto ?? '',
      'precio': widget.producto?.precio.toString() ?? '',
      'minimoInventario': widget.producto?.minimoInventario?.toString() ?? '0',
      'idcategoria': widget.producto?.idcategoria,
      'idproveedor': widget.producto?.idproveedor,
      'estado': widget.producto?.estado ?? 'activo',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto == null ? 'Nuevo Producto' : 'Editar Producto'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FormBuilder(
              key: _formKey,
              initialValue: initialValues,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos del Producto',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  FormBuilderTextField(
                    name: 'nombreproducto',
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto',
                      prefixIcon: Icon(Icons.label),
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'Campo obligatorio'),
                      FormBuilderValidators.minLength(3, errorText: 'Mínimo 3 caracteres'),
                      FormBuilderValidators.maxLength(100, errorText: 'Máximo 100 caracteres'),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'precio',
                    decoration: const InputDecoration(
                      labelText: 'Precio (C\$)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'Campo obligatorio'),
                      FormBuilderValidators.numeric(errorText: 'Debe ser un número'),
                      FormBuilderValidators.min(0.01, errorText: 'El precio debe ser mayor a 0'),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'minimoInventario',
                    decoration: const InputDecoration(
                      labelText: 'Mínimo de Inventario',
                      prefixIcon: Icon(Icons.inventory),
                      border: OutlineInputBorder(),
                      helperText: 'Cantidad mínima antes de generar alerta de stock bajo',
                    ),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.numeric(errorText: 'Debe ser un número'),
                      FormBuilderValidators.min(0, errorText: 'El mínimo debe ser 0 o mayor'),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  const Text('Asociar Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (categoriaState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (categoriaState.categorias.isEmpty)
                    Column(
                      children: [
                        const Text('No hay categorías disponibles.'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CategoriaForm()),
                            ).then((result) {
                              if (result == true) {
                                ref.read(categoriaControllerProvider.notifier).loadCategorias();
                              }
                            });
                          },
                          child: const Text('Crear Categoría'),
                        ),
                      ],
                    )
                  else
                    FormBuilderDropdown<int>(
                      name: 'idcategoria',
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(errorText: 'Seleccione una categoría'),
                      items: categoriaState.categorias.map((cat) {
                        return DropdownMenuItem(
                          value: cat.idcategoria,
                          child: Text(cat.nombrecategoria),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  const Text('Asociar Proveedor', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (proveedorState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (proveedorState.proveedores.isEmpty)
                    Column(
                      children: [
                        const Text('No hay proveedores disponibles.'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/proveedor_form').then((result) {
                              if (result == true) {
                                ref.read(proveedorControllerProvider.notifier).loadProveedores();
                              }
                            });
                          },
                          child: const Text('Crear Proveedor'),
                        ),
                      ],
                    )
                  else
                    FormBuilderDropdown<int>(
                      name: 'idproveedor',
                      decoration: const InputDecoration(
                        labelText: 'Proveedor',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(errorText: 'Seleccione un proveedor'),
                      items: proveedorState.proveedores.map((prov) {
                        final persona = prov.persona;
                        final empresa = prov.empresa;
                        final nombreCompleto = '${persona?.primerNombre ?? ''} ${persona?.primerApellido ?? ''}'.trim();
                        final nombreEmpresa = empresa?.nombreempresa ?? 'Sin empresa';
                        return DropdownMenuItem(
                          value: prov.id,
                          child: Text(
                            '$nombreCompleto - $nombreEmpresa',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  FormBuilderDropdown<String>(
                    name: 'estado',
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      prefixIcon: Icon(Icons.info),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'activo', child: Text('Activo')),
                      DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                    ],
                    validator: FormBuilderValidators.required(errorText: 'Seleccione un estado'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Imagen del Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_imageFile != null || widget.producto?.imagenUrl != null)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : NetworkImage(widget.producto!.imagenUrl!) as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Seleccionar Imagen'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: productoController.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(productoController.isLoading ? 'Guardando...' : 'Guardar'),
                      onPressed: productoController.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState?.saveAndValidate() ?? false) {
                                final values = _formKey.currentState!.value;

                                final nuevoProducto = Producto(
                                  idproducto: widget.producto?.idproducto,
                                  nombreproducto: values['nombreproducto'],
                                  precio: double.parse(values['precio'].toString()),
                                  minimoInventario: int.tryParse(values['minimoInventario']?.toString() ?? '0'),
                                  idcategoria: values['idcategoria'],
                                  idproveedor: values['idproveedor'],
                                  estado: values['estado'],
                                  imagenUrl: widget.producto?.imagenUrl,
                                );


                                try {
                                  if (widget.producto == null) {
                                    await ref
                                        .read(productoControllerProvider.notifier)
                                        .agregarProducto(nuevoProducto, _imageFile?.path);
                                  } else {
                                    await ref
                                        .read(productoControllerProvider.notifier)
                                        .actualizarProducto(nuevoProducto, _imageFile?.path);
                                  }

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Producto guardado correctamente.')),
                                    );
                                    Navigator.pop(context, true);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al guardar el producto: $e')),
                                    );
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Por favor, complete todos los campos requeridos.')),
                                );
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
