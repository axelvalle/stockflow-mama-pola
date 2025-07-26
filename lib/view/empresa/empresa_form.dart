import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:mamapola_app_v1/logic/empresa/empresa_controller.dart';
import 'package:mamapola_app_v1/logic/proveedor/proveedor_controller.dart';
import 'package:mamapola_app_v1/model/entities/empresa.dart';

class EmpresaForm extends ConsumerStatefulWidget {
  final Empresa? empresa;

  const EmpresaForm({super.key, this.empresa});

  @override
  ConsumerState<EmpresaForm> createState() => _EmpresaFormState();
}

class _EmpresaFormState extends ConsumerState<EmpresaForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  List<int> selectedProveedorIds = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(proveedorControllerProvider.notifier).loadProveedores();
    });
    // Inicializar proveedores seleccionados si la empresa tiene proveedores asociados
    if (widget.empresa?.proveedores.isNotEmpty ?? false) {
      selectedProveedorIds = widget.empresa!.proveedores
          .where((prov) => prov.id != null)
          .map((prov) => prov.id!)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final empresaController = ref.watch(empresaControllerProvider);
    final proveedorState = ref.watch(proveedorControllerProvider);
    final initialValues = {
      'nombreempresa': widget.empresa?.nombreempresa ?? '',
      'direccion': widget.empresa?.direccion ?? '',
      'contacto': widget.empresa?.contacto ?? '',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.empresa == null ? 'Nueva Empresa' : 'Editar Empresa'),
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
                    'Datos de la Empresa',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  FormBuilderTextField(
                    name: 'nombreempresa',
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la empresa',
                      prefixIcon: Icon(Icons.business),
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
                    name: 'direccion',
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.maxLength(200, errorText: 'Máximo 200 caracteres'),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'contacto',
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (ej. 2255-2020)',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.maxLength(9, errorText: 'Máximo 9 caracteres'),
                      FormBuilderValidators.match(
                        RegExp(r'^\d{4}-\d{4}$'),
                        errorText: 'Formato de teléfono inválido (use XXXX-XXXX)',
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Asociar Proveedores',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                    Column(
                      children: proveedorState.proveedores.map((prov) {
                        final persona = prov.persona;
                        return CheckboxListTile(
                          title: Text('${persona?.primerNombre ?? 'Sin nombre'} ${persona?.primerApellido ?? ''}'),
                          subtitle: Text(persona?.telefono ?? 'Sin teléfono'),
                          value: selectedProveedorIds.contains(prov.id),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true && prov.id != null) {
                                selectedProveedorIds.add(prov.id!);
                              } else {
                                selectedProveedorIds.remove(prov.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: empresaController.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(empresaController.isLoading ? 'Guardando...' : 'Guardar'),
                      onPressed: empresaController.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState?.saveAndValidate() ?? false) {
                                if (selectedProveedorIds.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Debe seleccionar al menos un proveedor.'),
                                    ),
                                  );
                                  return;
                                }

                                // Validación: ningún proveedor puede estar asociado a otra empresa
                                final proveedorState = ref.read(proveedorControllerProvider);
                                final proveedoresSeleccionados = proveedorState.proveedores.where((prov) => selectedProveedorIds.contains(prov.id)).toList();
                                final proveedoresConOtraEmpresa = proveedoresSeleccionados.where((prov) => prov.idEmpresa != null && prov.idEmpresa != widget.empresa?.idempresa).toList();
                                if (proveedoresConOtraEmpresa.isNotEmpty) {
                                  final nombres = proveedoresConOtraEmpresa.map((prov) => prov.persona?.primerNombre ?? 'Proveedor').join(', ');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('No se puede asociar el/los proveedor(es): $nombres porque ya están asociados a otra empresa.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final values = _formKey.currentState!.value;

                                final nuevaEmpresa = Empresa(
                                  idempresa: widget.empresa?.idempresa ?? 0,
                                  nombreempresa: values['nombreempresa'],
                                  direccion: values['direccion'],
                                  contacto: values['contacto'],
                                  proveedores: [], // Proveedores se asignan después
                                );

                                try {
                                  int empresaId;
                                  if (widget.empresa == null) {
                                    empresaId = await ref
                                        .read(empresaControllerProvider.notifier)
                                        .agregarEmpresaYRetornarId(nuevaEmpresa);
                                  } else {
                                    await ref
                                        .read(empresaControllerProvider.notifier)
                                        .actualizarEmpresa(nuevaEmpresa);
                                    empresaId = nuevaEmpresa.idempresa;
                                  }

                                  // Obtener proveedores actuales (si es edición)
                                  final currentProveedorIds = widget.empresa?.proveedores
                                          .where((prov) => prov.id != null)
                                          .map((prov) => prov.id!)
                                          .toList() ??
                                      [];

                                  // Proveedores a desasociar (presentes en current pero no en selected)
                                  final proveedoresToRemove = currentProveedorIds
                                      .where((id) => !selectedProveedorIds.contains(id))
                                      .toList();

                                  // Proveedores a asociar (presentes en selected pero no en current)
                                  final proveedoresToAdd = selectedProveedorIds
                                      .where((id) => !currentProveedorIds.contains(id))
                                      .toList();

                                  // Desasociar proveedores
                                  for (final idProveedor in proveedoresToRemove) {
                                    await ref
                                        .read(proveedorControllerProvider.notifier)
                                        .desasignarProveedor(idProveedor);
                                  }

                                  // Asociar proveedores
                                  for (final idProveedor in proveedoresToAdd) {
                                    await ref
                                        .read(proveedorControllerProvider.notifier)
                                        .asignarProveedor(idProveedor, empresaId);
                                  }

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Empresa guardada correctamente.'),
                                      ),
                                    );
                                    Navigator.pop(context, true);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al guardar la empresa: $e'),
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