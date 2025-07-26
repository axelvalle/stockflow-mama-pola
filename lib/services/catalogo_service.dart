import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:mamapola_app_v1/model/entities/catalogo_producto.dart';
import 'package:mamapola_app_v1/model/repository/catalogo_producto_repository.dart';

class CatalogoService {
  /// Genera un catálogo de productos en formato PDF usando la vista de catálogo
  /// 
  /// [context] - Contexto de Flutter para mostrar mensajes
  /// [onProgress] - Callback para actualizar el estado de progreso
  /// [limitado] - Si es true, limita a los primeros 50 productos para evitar problemas de memoria
  static Future<void> generateCatalogo({
    required BuildContext context,
    required Function(bool) onProgress,
    bool limitado = false,
  }) async {
    onProgress(true);

    try {
      print('Iniciando generación de catálogo de productos...');
      
      // Obtener datos desde la vista
      final repository = CatalogoProductoRepository();
      final productos = await repository.getCatalogoProductos();
      
      print('Productos obtenidos de la vista: ${productos.length} registros');
      
      // Validación de datos
      if (productos.isEmpty) {
        print('No hay productos para generar catálogo');
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

      // Limitar productos para evitar problemas de memoria
      List<CatalogoProducto> productosParaProcesar = productos;
      if (limitado && productos.length > 50) {
        productosParaProcesar = productos.take(50).toList();
        print('Modo limitado activado: procesando solo ${productosParaProcesar.length} productos');
      } else if (productos.length > 200) {
        // Si hay más de 200 productos, limitar automáticamente para evitar problemas de memoria
        productosParaProcesar = productos.take(200).toList();
        print('Muchos productos detectados: limitando a ${productosParaProcesar.length} para evitar problemas de memoria');
      }

      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

      // Crear el PDF del catálogo optimizado
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(15),
          maxPages: 100, // Aumentar límite de páginas
          build: (context) => [
            // Encabezado simplificado
            pw.Text(
              'Catálogo de Productos',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Sistema de Gestión de Inventario - Mamapola',
              style: pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Generado el: ${dateFormat.format(now)}',
              style: pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.center,
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // Estadísticas simplificadas
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Resumen del Catálogo', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Total de Productos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('${productosParaProcesar.length}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Categorías Únicas')),
                          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('${_contarCategoriasUnicas(productosParaProcesar)}')),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Proveedores Únicos')),
                          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('${_contarProveedoresUnicos(productosParaProcesar)}')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Catálogo de Productos optimizado
            if (productosParaProcesar.isNotEmpty) ...[
              ..._generarTablasProductosPorPagina(productosParaProcesar),
            ],

            // Pie de página
            pw.SizedBox(height: 15),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Catálogo generado automáticamente por el Sistema Mamapola',
              style: pw.TextStyle(fontSize: 6, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );

      print('Guardando PDF...');
      
      // Guardar y abrir el PDF
      final bytes = await pdf.save();
      print('PDF generado: ${bytes.length} bytes');
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/catalogo_productos_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      print('Catálogo guardado en: ${file.path}');

      // Abrir el archivo
      await OpenFile.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catálogo generado exitosamente'),
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

  /// Cuenta categorías únicas optimizado
  static int _contarCategoriasUnicas(List<CatalogoProducto> productos) {
    try {
      final categorias = productos.map((p) => p.nombrecategoria).where((c) => c != null && c.isNotEmpty).toSet();
      return categorias.length;
    } catch (e) {
      print('Error al contar categorías únicas: $e');
      return 0;
    }
  }

  /// Cuenta proveedores únicos optimizado
  static int _contarProveedoresUnicos(List<CatalogoProducto> productos) {
    try {
      final proveedores = productos.map((p) => p.proveedor).where((p) => p != null && p.isNotEmpty).toSet();
      return proveedores.length;
    } catch (e) {
      print('Error al contar proveedores únicos: $e');
      return 0;
    }
  }

  /// Genera las filas de productos optimizadas para evitar problemas de memoria
  static List<pw.TableRow> _generarFilasProductosOptimizadas(List<CatalogoProducto> productos) {
    final filas = <pw.TableRow>[];
    
    try {
      print('Generando filas optimizadas para ${productos.length} productos...');
      
      // Procesar en lotes para evitar problemas de memoria
      const batchSize = 20;
      for (int i = 0; i < productos.length; i += batchSize) {
        final end = (i + batchSize < productos.length) ? i + batchSize : productos.length;
        final batch = productos.sublist(i, end);
        
        for (final producto in batch) {
          try {
            final fila = pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3), 
                  child: pw.Text(
                    _truncateText(producto.nombrecategoria ?? 'Sin categoría', 15),
                    style: pw.TextStyle(fontSize: 7),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3), 
                  child: pw.Text(
                    _truncateText(producto.nombreproducto ?? 'Sin nombre', 20),
                    style: pw.TextStyle(fontSize: 7),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3), 
                  child: pw.Text(
                    'C\$${(producto.precio ?? 0).toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 7),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3), 
                  child: pw.Text(
                    _truncateText(producto.estado ?? 'Activo', 8),
                    style: pw.TextStyle(fontSize: 7),
                  ),
                ),
              ],
            );
            
            filas.add(fila);
          } catch (e) {
            print('Error al procesar producto: $e');
            // Agregar fila de error simplificada
            filas.add(pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Error', style: pw.TextStyle(fontSize: 7))),
                pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('N/A', style: pw.TextStyle(fontSize: 7))),
                pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('N/A', style: pw.TextStyle(fontSize: 7))),
                pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Error', style: pw.TextStyle(fontSize: 7))),
              ],
            ));
          }
        }
        
        // Pequeña pausa para liberar memoria
        if (i + batchSize < productos.length) {
          // No hacer nada, solo dar tiempo al GC
        }
      }
      
      print('Filas generadas exitosamente: ${filas.length}');
      return filas;
    } catch (e) {
      print('Error general al generar filas de productos: $e');
      return [
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Error al generar tabla', style: pw.TextStyle(fontSize: 7))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('N/A', style: pw.TextStyle(fontSize: 7))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('N/A', style: pw.TextStyle(fontSize: 7))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Error', style: pw.TextStyle(fontSize: 7))),
          ],
        ),
      ];
    }
  }

  /// Genera tablas de productos divididas por páginas para evitar TooManyPagesException
  static List<pw.Widget> _generarTablasProductosPorPagina(List<CatalogoProducto> productos) {
    final widgets = <pw.Widget>[];
    const productosPorPagina = 25; // Máximo 25 productos por página
    
    for (int i = 0; i < productos.length; i += productosPorPagina) {
      final end = (i + productosPorPagina < productos.length) ? i + productosPorPagina : productos.length;
      final productosPagina = productos.sublist(i, end);
      
      widgets.add(
        pw.Container(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Catálogo de Productos (Página ${(i ~/ productosPorPagina) + 1})', 
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Encabezados
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('CATEGORÍA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('PRODUCTO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('PRECIO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('ESTADO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    ],
                  ),
                  // Datos de productos de esta página
                  ..._generarFilasProductosOptimizadas(productosPagina),
                ],
              ),
            ],
          ),
        ),
      );
      
      // Agregar espacio entre páginas si no es la última
      if (end < productos.length) {
        widgets.add(pw.SizedBox(height: 20));
      }
    }
    
    return widgets;
  }

  /// Trunca texto para evitar problemas de memoria
  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
} 