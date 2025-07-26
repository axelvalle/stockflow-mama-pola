import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class AnalyticsService {
  /// Genera un reporte de analytics en formato PDF
  /// 
  /// [inventarioData] - Datos de inventario por almacén
  /// [movimientosData] - Datos de movimientos recientes
  /// [bajoInventarioData] - Datos de productos con bajo inventario
  /// [categoriasData] - Datos de distribución por categoría
  /// [movimientosPorCategoriaData] - Datos de movimientos por categoría
  /// [context] - Contexto de Flutter para mostrar mensajes
  /// [onProgress] - Callback para actualizar el estado de progreso
  static Future<void> generateAnalyticsReport({
    required List<Map<String, dynamic>> inventarioData,
    required List<Map<String, dynamic>> movimientosData,
    required List<Map<String, dynamic>> bajoInventarioData,
    required List<Map<String, dynamic>> categoriasData,
    required List<Map<String, dynamic>> movimientosPorCategoriaData,
    required BuildContext context,
    required Function(bool) onProgress,
  }) async {
    onProgress(true);

    try {
      print('Iniciando generación de reporte con datos de pantalla...');
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

      print('Datos obtenidos de pantalla:');
      print('- Inventario: ${inventarioData.length} registros');
      print('- Movimientos: ${movimientosData.length} registros');
      print('- Bajo inventario: ${bajoInventarioData.length} registros');
      print('- Categorías: ${categoriasData.length} registros');
      print('- Movimientos por categoría: ${movimientosPorCategoriaData.length} registros');

      // Crear el PDF del reporte
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Encabezado
            pw.Text(
              'Reporte de Análisis de Inventario',
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
                  pw.Text('Resumen Ejecutivo', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Este reporte presenta un análisis completo del estado actual del inventario, '
                    'incluyendo movimientos recientes, distribución por categorías, y productos con bajo stock. '
                    'Los datos fueron generados automáticamente por el sistema de gestión de inventario.',
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
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${inventarioData.length}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Movimientos Recientes')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${movimientosData.length}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Productos con Bajo Stock')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${bajoInventarioData.length}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Categorías Activas')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${categoriasData.length}')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Inventario por Almacén
            if (inventarioData.isNotEmpty) ...[
              pw.Container(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Inventario por Almacén', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        // Encabezados
                        pw.TableRow(
                          children: inventarioData.first.keys
                              .where((key) => key != 'id' && key != 'created_at')
                              .map((key) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(
                                      key.replaceAll('_', ' ').toUpperCase(),
                                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                    ),
                                  ))
                              .toList(),
                        ),
                        // Datos
                        ...inventarioData.map((row) => pw.TableRow(
                          children: row.keys
                              .where((key) => key != 'id' && key != 'created_at')
                              .map((key) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(row[key]?.toString() ?? 'N/A'),
                                  ))
                              .toList(),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
            ],

            // Movimientos por Categoría
            if (movimientosPorCategoriaData.isNotEmpty) ...[
              pw.Container(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Movimientos por Categoría', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        // Encabezados
                        pw.TableRow(
                          children: movimientosPorCategoriaData.first.keys
                              .where((key) => key != 'id' && key != 'created_at')
                              .map((key) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(
                                      key.replaceAll('_', ' ').toUpperCase(),
                                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                    ),
                                  ))
                              .toList(),
                        ),
                        // Datos
                        ...movimientosPorCategoriaData.map((row) => pw.TableRow(
                          children: row.keys
                              .where((key) => key != 'id' && key != 'created_at')
                              .map((key) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(row[key]?.toString() ?? 'N/A'),
                                  ))
                              .toList(),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
            ],

            // Productos con Bajo Inventario
            if (bajoInventarioData.isNotEmpty) ...[
              pw.Container(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Productos con Bajo Inventario', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        // Encabezados
                        pw.TableRow(
                          children: bajoInventarioData.first.keys
                              .where((key) => key != 'id' && key != 'created_at')
                              .map((key) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(
                                      key.replaceAll('_', ' ').toUpperCase(),
                                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                    ),
                                  ))
                              .toList(),
                        ),
                        // Datos
                        ...bajoInventarioData.map((row) => pw.TableRow(
                          children: row.keys
                              .where((key) => key != 'id' && key != 'created_at')
                              .map((key) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(row[key]?.toString() ?? 'N/A'),
                                  ))
                              .toList(),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
            ],

            // Distribución por Categoría
            if (categoriasData.isNotEmpty) ...[
              pw.Container(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Distribución por Categoría', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        // Encabezados
                        pw.TableRow(
                          children: categoriasData.first.keys
                              .where((key) => key != 'id' && key != 'created_at')
                              .map((key) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(
                                      key.replaceAll('_', ' ').toUpperCase(),
                                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                    ),
                                  ))
                              .toList(),
                        ),
                        // Datos
                        ...categoriasData.map((row) => pw.TableRow(
                          children: row.keys
                              .where((key) => key != 'id' && key != 'created_at')
                              .map((key) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(row[key]?.toString() ?? 'N/A'),
                                  ))
                              .toList(),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ],

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
      final file = File('${directory.path}/reporte_analytics_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      print('Reporte guardado en: ${file.path}');

      // Abrir el archivo
      await OpenFile.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error al generar reporte: $e');
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
} 