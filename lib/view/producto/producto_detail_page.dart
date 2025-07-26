import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/model/entities/producto.dart';
import 'package:mamapola_app_v1/logic/categoria/categoria_controller.dart';
import 'package:mamapola_app_v1/logic/proveedor/proveedor_controller.dart';
import 'package:mamapola_app_v1/model/entities/categoria.dart';
import 'package:mamapola_app_v1/model/entities/proveedor.dart';

class ProductoDetailPage extends ConsumerWidget {
  final Producto producto;
  const ProductoDetailPage({super.key, required this.producto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriaState = ref.watch(categoriaControllerProvider);
    final proveedorState = ref.watch(proveedorControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final categoria = categoriaState.categorias.firstWhere(
      (cat) => cat.idcategoria == producto.idcategoria,
      orElse: () => const Categoria(idcategoria: null, nombrecategoria: '-'),
    );

    final proveedor = proveedorState.proveedores.firstWhere(
      (prov) => prov.id == producto.idproveedor,
      orElse: () => Proveedor(id: null, idPersona: 0, persona: null, empresa: null),
    );

    String proveedorInfo = '-';
    if (proveedor.persona != null || proveedor.empresa != null) {
      final persona = proveedor.persona;
      final empresa = proveedor.empresa;
      final nombreCompleto =
          '${persona?.primerNombre ?? ''} ${persona?.primerApellido ?? ''}'.trim();
      final nombreEmpresa = empresa?.nombreempresa ?? 'Sin empresa';
      proveedorInfo = '$nombreCompleto - $nombreEmpresa';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Producto'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen con sombra y borde
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: producto.imagenUrl != null
                      ? Image.network(
                          producto.imagenUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 200,
                            height: 200,
                            color: colorScheme.surfaceContainerLowest,
                            child: Icon(Icons.image_not_supported, size: 60, color: colorScheme.onSurfaceVariant),
                          ),
                        )
                      : Container(
                          width: 200,
                          height: 200,
                          color: colorScheme.surfaceContainerLowest,
                          child: Icon(Icons.image_not_supported, size: 60, color: colorScheme.onSurfaceVariant),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Card principal con los datos
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: colorScheme.surfaceContainer,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(context, Icons.label, 'Nombre', producto.nombreproducto, isTitle: true),
                    const Divider(height: 28),
                    _buildDetailRow(context, Icons.attach_money, 'Precio', 'C\$${producto.precio.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, Icons.inventory, 'Mínimo Inventario', producto.minimoInventario?.toString() ?? '0'),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, Icons.category, 'Categoría', categoria.nombrecategoria),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, Icons.person, 'Proveedor', proveedorInfo),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, Icons.info_outline, 'Estado', producto.estado ?? '-'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {bool isTitle = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: isTitle ? 28 : 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isTitle ? FontWeight.bold : FontWeight.w600,
                  fontSize: isTitle ? 20 : 16,
                  color: isTitle ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTitle ? 20 : 16,
                  color: isTitle ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 