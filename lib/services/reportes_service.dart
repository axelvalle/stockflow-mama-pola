import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/model/entities/inventario.dart';
import 'package:mamapola_app_v1/model/entities/movimiento_inventario.dart';
import 'package:mamapola_app_v1/model/entities/catalogo_producto.dart';
import 'package:mamapola_app_v1/model/repository/inventario_repository.dart';
import 'package:mamapola_app_v1/model/repository/movimiento_inventario_repository.dart';
import 'package:mamapola_app_v1/model/repository/catalogo_producto_repository.dart';

class ReportesService {
  /// Genera un reporte de inventario en formato PDF
  /// 
  /// [context] - Contexto de Flutter para mostrar mensajes
  /// [onProgress] - Callback para actualizar el estado de progreso
  /// [filtroAlmacen] - ID del almacén para filtrar (opcional)
  /// [filtroCategoria] - ID de la categoría para filtrar (opcional)
  static Future<void> generateInventarioReport({
    required BuildContext context,
    required Function(bool) onProgress,
    int? filtroAlmacen,
    int? filtroCategoria,
  }) async {
    onProgress(true);

    try {
      print('Iniciando generación de reporte de inventario...');
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

      // Obtener datos de inventario
      final repository = InventarioRepository(Supabase.instance.client);
      final inventarios = await repository.obtenerInventario(
        idAlmacen: filtroAlmacen,
        idCategoria: filtroCategoria,
      );

      print('Inventarios obtenidos: ${inventarios.length} registros');

      if (inventarios.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No hay datos de inventario para generar reporte'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Crear el PDF del reporte
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Encabezado
            pw.Text(
              'Reporte de Inventario',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Sistema de Gestión de Inventario - Mamapola',
              style: pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Generado el: ${dateFormat.format(now)}',
              style: pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.Divider(),
            pw.SizedBox(height: 15),

            // Resumen ejecutivo
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Resumen del Inventario', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Este reporte presenta el estado actual del inventario, incluyendo productos, '
                    'cantidades disponibles, y ubicaciones en almacenes. Los datos fueron generados '
                    'automáticamente por el sistema de gestión de inventario.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Estadísticas generales
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Estadísticas Generales', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Métrica', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Valor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total de Productos en Inventario')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${inventarios.length}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Stock Total')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${_calcularStockTotal(inventarios)}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Productos con Stock Bajo')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${_contarProductosBajoStock(inventarios)}')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Tabla de inventario
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Detalle del Inventario', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      // Encabezados
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('PRODUCTO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('CATEGORÍA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ALMACÉN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('CANTIDAD', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ESTADO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        ],
                      ),
                      // Datos
                      ...inventarios.map((inventario) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_truncateText(inventario.nombreProducto ?? 'N/A', 20), style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_truncateText(inventario.nombreCategoria ?? 'N/A', 15), style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_truncateText(inventario.nombreAlmacen ?? 'N/A', 15), style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${inventario.cantidad}', style: pw.TextStyle(fontSize: 9))),
                                                     pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Activo', style: pw.TextStyle(fontSize: 9))),
                        ],
                      )),
                    ],
                  ),
                ],
              ),
            ),

            // Pie de página
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Reporte generado automáticamente por el Sistema Mamapola',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );

      // Guardar y abrir el PDF
      final bytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/reporte_inventario_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      print('Reporte guardado en: ${file.path}');

      // Abrir el archivo
      await OpenFile.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte de inventario generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error al generar reporte de inventario: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      onProgress(false);
    }
  }

  /// Genera un reporte de movimientos de inventario en formato PDF
  /// 
  /// [context] - Contexto de Flutter para mostrar mensajes
  /// [onProgress] - Callback para actualizar el estado de progreso
  /// [filtroTipo] - Tipo de movimiento para filtrar (opcional)
  /// [filtroFechaInicio] - Fecha de inicio para filtrar (opcional)
  /// [filtroFechaFin] - Fecha de fin para filtrar (opcional)
  static Future<void> generateMovimientosReport({
    required BuildContext context,
    required Function(bool) onProgress,
    String? filtroTipo,
    DateTime? filtroFechaInicio,
    DateTime? filtroFechaFin,
  }) async {
    onProgress(true);

    try {
      print('Iniciando generación de reporte de movimientos...');
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

      // Obtener datos de movimientos
      final repository = MovimientoInventarioRepository(Supabase.instance.client);
      final movimientos = await repository.getAll();

      print('Movimientos obtenidos: ${movimientos.length} registros');

      if (movimientos.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No hay movimientos para generar reporte'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Crear el PDF del reporte
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Encabezado
            pw.Text(
              'Reporte de Movimientos de Inventario',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Sistema de Gestión de Inventario - Mamapola',
              style: pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Generado el: ${dateFormat.format(now)}',
              style: pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.Divider(),
            pw.SizedBox(height: 15),

            // Resumen ejecutivo
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Resumen de Movimientos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Este reporte presenta el historial de movimientos de inventario, incluyendo entradas, '
                    'salidas y ajustes. Los datos fueron generados automáticamente por el sistema de '
                    'gestión de inventario.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Estadísticas generales
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Estadísticas Generales', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Métrica', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Valor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total de Movimientos')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${movimientos.length}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Entradas')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${_contarMovimientosPorTipo(movimientos, 'entrada')}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Salidas')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${_contarMovimientosPorTipo(movimientos, 'salida')}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Ajustes')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${_contarMovimientosPorTipo(movimientos, 'ajuste')}')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Tabla de movimientos
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Detalle de Movimientos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      // Encabezados
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('FECHA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('PRODUCTO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('TIPO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('CANTIDAD', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ALMACÉN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        ],
                      ),
                      // Datos
                      ...movimientos.map((movimiento) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd/MM/yyyy').format(movimiento.fecha), style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_truncateText(movimiento.nombreProducto ?? 'N/A', 20), style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_truncateText(movimiento.tipoMovimiento, 10), style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${movimiento.cantidad}', style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_truncateText(movimiento.nombreAlmacen ?? 'N/A', 15), style: pw.TextStyle(fontSize: 9))),
                        ],
                      )),
                    ],
                  ),
                ],
              ),
            ),

            // Pie de página
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Reporte generado automáticamente por el Sistema Mamapola',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );

      // Guardar y abrir el PDF
      final bytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/reporte_movimientos_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      print('Reporte guardado en: ${file.path}');

      // Abrir el archivo
      await OpenFile.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte de movimientos generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error al generar reporte de movimientos: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      onProgress(false);
    }
  }

  /// Genera un catálogo de productos en formato PDF
  /// 
  /// [context] - Contexto de Flutter para mostrar mensajes
  /// [onProgress] - Callback para actualizar el estado de progreso
  /// [filtroCategoria] - ID de la categoría para filtrar (opcional)
  /// [filtroProveedor] - ID del proveedor para filtrar (opcional)
  /// [filtroEstado] - Estado para filtrar (opcional)
  static Future<void> generateCatalogoReport({
    required BuildContext context,
    required Function(bool) onProgress,
    int? filtroCategoria,
    int? filtroProveedor,
    String? filtroEstado,
  }) async {
    onProgress(true);

    try {
      print('Iniciando generación de catálogo de productos...');
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

      // Obtener datos del catálogo
      final repository = CatalogoProductoRepository();
      final productos = await repository.getCatalogoProductos();

      print('Productos obtenidos: ${productos.length} registros');

      if (productos.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No hay productos para generar catálogo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Crear el PDF del catálogo
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Encabezado
            pw.Text(
              'Catálogo de Productos',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Sistema de Gestión de Inventario - Mamapola',
              style: pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Generado el: ${dateFormat.format(now)}',
              style: pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.Divider(),
            pw.SizedBox(height: 15),

            // Resumen ejecutivo
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Resumen del Catálogo', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Este catálogo presenta todos los productos disponibles en el sistema, '
                    'incluyendo información de categorías, precios y estados. Los datos fueron '
                    'generados automáticamente por el sistema de gestión de inventario.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Estadísticas generales
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Estadísticas Generales', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Métrica', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Valor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total de Productos')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${productos.length}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Categorías Únicas')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${_contarCategoriasUnicas(productos)}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Proveedores Únicos')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${_contarProveedoresUnicos(productos)}')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Tabla de productos
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Catálogo de Productos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      // Encabezados
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('CATEGORÍA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('PRODUCTO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('PRECIO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('PROVEEDOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ESTADO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        ],
                      ),
                      // Datos
                      ...productos.map((producto) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_truncateText(producto.nombrecategoria ?? 'N/A', 15), style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_truncateText(producto.nombreproducto ?? 'N/A', 20), style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('C\$${(producto.precio ?? 0).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_truncateText(producto.proveedor ?? 'N/A', 15), style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_truncateText(producto.estado ?? 'Activo', 10), style: pw.TextStyle(fontSize: 9))),
                        ],
                      )),
                    ],
                  ),
                ],
              ),
            ),

            // Pie de página
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Catálogo generado automáticamente por el Sistema Mamapola',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );

      // Guardar y abrir el PDF
      final bytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/catalogo_productos_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      print('Catálogo guardado en: ${file.path}');

      // Abrir el archivo
      await OpenFile.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catálogo de productos generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error al generar catálogo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar catálogo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      onProgress(false);
    }
  }

  // Métodos auxiliares
  static int _calcularStockTotal(List<Inventario> inventarios) {
    return inventarios.fold(0, (sum, inventario) => sum + inventario.cantidad);
  }

  static int _contarProductosBajoStock(List<Inventario> inventarios) {
    return inventarios.where((inventario) => inventario.cantidad < 10).length;
  }

  static int _contarMovimientosPorTipo(List<MovimientoInventario> movimientos, String tipo) {
    return movimientos.where((movimiento) => movimiento.tipoMovimiento == tipo).length;
  }

  static int _contarCategoriasUnicas(List<CatalogoProducto> productos) {
    final categorias = productos.map((p) => p.nombrecategoria).where((c) => c != null && c.isNotEmpty).toSet();
    return categorias.length;
  }

  static int _contarProveedoresUnicos(List<CatalogoProducto> productos) {
    final proveedores = productos.map((p) => p.proveedor).where((p) => p != null && p.isNotEmpty).toSet();
    return proveedores.length;
  }

  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
} 