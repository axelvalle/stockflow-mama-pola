import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:mamapola_app_v1/logic/categoria/categoria_controller.dart';
import 'package:mamapola_app_v1/model/entities/categoria.dart';

class CategoriaForm extends ConsumerStatefulWidget {
  final Categoria? categoria;

  const CategoriaForm({super.key, this.categoria});

  @override
  ConsumerState<CategoriaForm> createState() => _CategoriaFormState();
}

class _CategoriaFormState extends ConsumerState<CategoriaForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final categoriaController = ref.watch(categoriaControllerProvider);
    final initialValues = {
      'nombrecategoria': widget.categoria?.nombrecategoria ?? '',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoria == null ? 'Nueva Categoría' : 'Editar Categoría'),
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
                    'Datos de la Categoría',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  FormBuilderTextField(
                    name: 'nombrecategoria',
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la categoría',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'Campo obligatorio'),
                      FormBuilderValidators.minLength(3, errorText: 'Mínimo 3 caracteres'),
                      FormBuilderValidators.maxLength(100, errorText: 'Máximo 100 caracteres'),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: categoriaController.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(categoriaController.isLoading ? 'Guardando...' : 'Guardar'),
                      onPressed: categoriaController.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState?.saveAndValidate() ?? false) {
                                final values = _formKey.currentState!.value;

                                final nuevaCategoria = Categoria(
                                  idcategoria: widget.categoria?.idcategoria,
                                  nombrecategoria: values['nombrecategoria'],
                                );

                                try {
                                  if (widget.categoria == null) {
                                    await ref
                                        .read(categoriaControllerProvider.notifier)
                                        .agregarCategoria(nuevaCategoria);
                                  } else {
                                    await ref
                                        .read(categoriaControllerProvider.notifier)
                                        .actualizarCategoria(nuevaCategoria);
                                  }

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Categoría guardada correctamente.'),
                                      ),
                                    );
                                    Navigator.pop(context, true);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al guardar la categoría: $e'),
                                      ),
                                    );
                                  }
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