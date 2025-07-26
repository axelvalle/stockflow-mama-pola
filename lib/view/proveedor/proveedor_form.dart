import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:mamapola_app_v1/logic/proveedor/proveedor_controller.dart';
import 'package:mamapola_app_v1/model/entities/persona.dart';

class ProveedorForm extends ConsumerStatefulWidget {
  final Persona? persona;  // <-- parámetro opcional para edición

  const ProveedorForm({super.key, this.persona});

  @override
  ConsumerState<ProveedorForm> createState() => _ProveedorFormState();
}

class _ProveedorFormState extends ConsumerState<ProveedorForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(proveedorControllerProvider);

    // Valores iniciales si es edición
    final initialValues = {
      'primernombre': widget.persona?.primerNombre ?? '',
      'segundonombre': widget.persona?.segundoNombre ?? '',
      'primerapellido': widget.persona?.primerApellido ?? '',
      'segundoapellido': widget.persona?.segundoApellido ?? '',
      'telefono': widget.persona?.telefono ?? '',
      'direccion': widget.persona?.direccion ?? '',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.persona == null ? 'Nuevo Proveedor' : 'Editar Proveedor'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FormBuilder(
              key: _formKey,
              initialValue: initialValues,
              child: Column(
                children: [
                  const Text(
                    'Formulario de Registro',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  FormBuilderTextField(
                    name: 'primernombre',
                    decoration: const InputDecoration(
                      labelText: 'Primer Nombre',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'Campo obligatorio'),
                      FormBuilderValidators.minLength(2, errorText: 'Mínimo 2 caracteres'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'segundonombre',
                    decoration: const InputDecoration(
                      labelText: 'Segundo Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'primerapellido',
                    decoration: const InputDecoration(
                      labelText: 'Primer Apellido',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'Campo obligatorio'),
                      FormBuilderValidators.minLength(2, errorText: 'Mínimo 2 caracteres'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'segundoapellido',
                    decoration: const InputDecoration(
                      labelText: 'Segundo Apellido',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'telefono',
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'Campo obligatorio'),
                      FormBuilderValidators.match(
                        RegExp(r'^\d{8,10}$'),
                        errorText: 'Debe tener entre 8 y 10 dígitos',
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'direccion',
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: FormBuilderValidators.required(errorText: 'Campo obligatorio'),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: controller.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(controller.isLoading ? 'Guardando...' : 'Guardar'),
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState?.saveAndValidate() ?? false) {
                                final values = _formKey.currentState!.value;

                                final persona = Persona(
                                  idpersona: widget.persona?.idpersona, // para actualizar
                                  primerNombre: values['primernombre'],
                                  segundoNombre: values['segundonombre'],
                                  primerApellido: values['primerapellido'],
                                  segundoApellido: values['segundoapellido'],
                                  telefono: values['telefono'],
                                  direccion: values['direccion'],
                                  estado: 'activo',
                                );

                                if (widget.persona == null) {
                                  await ref.read(proveedorControllerProvider.notifier).registrarProveedor(persona);
                                } else {
                                  await ref.read(proveedorControllerProvider.notifier).actualizarProveedor(persona);
                                }

                                if (mounted) Navigator.pop(context, true);
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
