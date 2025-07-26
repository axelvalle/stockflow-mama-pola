import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/logic/inventario/inventario_controller.dart';
import 'package:mamapola_app_v1/logic/inventario/inventario_state.dart';
import 'package:mamapola_app_v1/model/entities/inventario.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mamapola_app_v1/services/reportes_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/logic/utils/role_manager.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

final vistaTablaProvider = StateProvider<bool>((ref) => false);

class InventarioPage extends ConsumerStatefulWidget {
  const InventarioPage({super.key});

  @override
  ConsumerState<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends ConsumerState<InventarioPage> {
  static bool _infoCardClosed = false; // Mantener cerrado durante la sesión
  final TextEditingController _searchController = TextEditingController();
  bool _filtersExpanded = false;
  bool _showInfoCard = !_infoCardClosed;
  late Future<bool> _isAdminFuture;
  bool _isExporting = false;
  bool _showResumen = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _isAdminFuture = _isCurrentUserAdmin();
    _loadViewMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventarioControllerProvider.notifier).cargarInventario();
    });
  }

  Future<bool> _isCurrentUserAdmin() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return false;
    try {
      final userData = await Supabase.instance.client
          .from('usuarios_app')
          .select('rol')
          .eq('id', currentUser.id)
          .single();
      return RoleManager.isAdmin(userData['rol']);
    } catch (e) {
      if (context.mounted) {
        UIErrorHandler.showError(
          context,
          e,
          displayType: ErrorDisplayType.snackBar,
          customTitle: 'Error verificando permisos',
        );
      }
      return false;
    }
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final viewMode = prefs.getString('inventarioViewMode') ?? 'cards';
    ref.read(vistaTablaProvider.notifier).state = viewMode == 'table';
  }

  Future<void> _saveViewMode(bool isTableView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inventarioViewMode', isTableView ? 'table' : 'cards');
  }

  @override
  void dispose() {
    _searchController.dispose();
    ref.read(inventarioControllerProvider.notifier).clearFiltros();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(inventarioControllerProvider.notifier).cargarInventario();
  }

  Future<void> _generarReporteInventario() async {
    setState(() => _isExporting = true);
    
    try {
      final controller = ref.read(inventarioControllerProvider);
      await ReportesService.generateInventarioReport(
        context: context,
        onProgress: (isGenerating) {
          if (mounted) {
            setState(() {
              _isExporting = isGenerating;
            });
          }
        },
        filtroAlmacen: controller.selectedAlmacen,
        filtroCategoria: controller.selectedCategoria,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<String> _getNextReportNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final dateFormat = DateFormat('yyyyMMdd');
    final currentDate = dateFormat.format(DateTime.now());
    final lastReportDate = prefs.getString('lastReportDateInventario') ?? '';
    int counter = prefs.getInt('reportCounterInventario') ?? 0;

    if (lastReportDate != currentDate) {
      counter = 1;
      await prefs.setString('lastReportDateInventario', currentDate);
    } else {
      counter++;
    }

    await prefs.setInt('reportCounterInventario', counter);
    return '$currentDate-${counter.toString().padLeft(3, '0')}';
  }

  Future<Uint8List> _generarReporteInventarioPDF(List<Inventario> inventarioMostrado) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSerifAhomRegular();
    final fontBold = await PdfGoogleFonts.notoSerifArmenianBlack();
    final dateFormat = DateFormat.yMMMMd('es').add_Hms();
    final currentDateTime = dateFormat.format(DateTime.now());
    final reportNumber = await _getNextReportNumber();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pw.PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(72),
        header: (pw.Context context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Comedor Mama Pola',
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                  pw.Text(
                    'Empalme Villa Japón, 400 metros carretera Malacatoya, Managua, Nicaragua',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.Text(
                    'Teléfono: +505 8994 3576',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.Text(
                    'Correo: marinaobando@mamapola.com',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
              pw.Text(
                'No.: $reportNumber',
                style: pw.TextStyle(font: fontBold, fontSize: 10),
              ),
            ],
          ),
        ),
        footer: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount} | Fecha: $currentDateTime',
            style: pw.TextStyle(font: font, fontSize: 10, color: pw.PdfColor(0.5, 0.5, 0.5)),
          ),
        ),
        build: (pw.Context context) => [
          pw.SizedBox(height: 20),
          pw.Text(
            'Reporte de Inventario Actual',
            style: pw.TextStyle(font: fontBold, fontSize: 14),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Fecha y Hora de Impresión: $currentDateTime',
            style: pw.TextStyle(font: font, fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 20),
          pw.Paragraph(
            text: 'Este informe detalla el estado actual del inventario en el Comedor Mama Pola, '
                'incluyendo información sobre productos, categorías, almacenes, cantidades disponibles y precios.',
            style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 1.5),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(width: 1),
            defaultColumnWidth: const pw.FlexColumnWidth(),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: pw.PdfColor(0.95, 0.95, 0.95)),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Producto', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Categoría', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Almacén', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Stock', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Precio', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                  ),
                ],
              ),
              ...inventarioMostrado.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          item.nombreProducto ?? 'Producto ${item.idproducto}',
                          style: pw.TextStyle(font: font, fontSize: 10),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          item.nombreCategoria ?? 'Sin categoría',
                          style: pw.TextStyle(font: font, fontSize: 10),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          item.nombreAlmacen ?? 'Almacén ${item.idalmacen}',
                          style: pw.TextStyle(font: font, fontSize: 10),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          item.cantidad.toString(),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: item.cantidad < 10 ? pw.PdfColor(1, 0, 0) : pw.PdfColor(0, 0, 0),
                          ),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          item.precio != null ? '\$${item.precio!.toStringAsFixed(2)}' : 'N/A',
                          style: pw.TextStyle(font: font, fontSize: 10),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                    ],
                  )),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Paragraph(
            text: 'Nota: Los valores presentados en este informe reflejan el estado del inventario al momento de la generación del reporte. '
                'Para más información, contacte al administrador del sistema en marinaobando@mamapola.com.',
            style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );

    return await pdf.save();
  }

  Future<void> _mostrarVistaPrevia(List<Inventario> inventarioMostrado) async {
    setState(() => _isExporting = true);
    final pdfBytes = await _generarReporteInventarioPDF(inventarioMostrado);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Vista Previa del Reporte'),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Compartir PDF',
                onPressed: () async {
                  await Printing.sharePdf(
                    bytes: pdfBytes,
                    filename: 'Reporte_Inventario_Actual_${await _getNextReportNumber()}.pdf',
                  );
                },
              ),
            ],
          ),
          body: PdfPreview(
            build: (format) => pdfBytes,
            allowPrinting: true,
            allowSharing: false,
            canChangePageFormat: false,
            canDebug: false,
          ),
        ),
      ),
    );

    setState(() => _isExporting = false);
  }

  Widget _buildResumenInventario(InventarioState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final inventarioMostrado = state.inventarioFiltrado.isNotEmpty 
        ? state.inventarioFiltrado 
        : state.inventarios;
    
    final totalProductos = inventarioMostrado.length;
    final stockBajo = inventarioMostrado.where((item) => item.cantidad < 10).length;
    final stockAgotado = inventarioMostrado.where((item) => item.cantidad == 0).length;
    final valorTotal = inventarioMostrado.fold<double>(
      0, (sum, item) => sum + (item.precio ?? 0) * item.cantidad
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Resumen del Inventario',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildResumenCard(
                  'Total Productos',
                  totalProductos.toString(),
                  Icons.inventory,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResumenCard(
                  'Stock Bajo',
                  stockBajo.toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResumenCard(
                  'Agotados',
                  stockAgotado.toString(),
                  Icons.error,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResumenCard(
                  'Valor Total',
                  '\$${valorTotal.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(inventarioControllerProvider);
    final notifier = ref.read(inventarioControllerProvider.notifier);
    final esVistaTabla = ref.watch(vistaTablaProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final inventarioMostrado = controller.inventarioFiltrado;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Inventario'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        actions: [
          Row(
            children: [
              Text('Mostrar resumen', style: TextStyle(color: colorScheme.onPrimary)),
              Switch(
                value: _showResumen,
                onChanged: (val) {
                  setState(() {
                    _showResumen = val;
                  });
                },
                activeColor: colorScheme.secondary,
              ),
            ],
          ),
          IconButton(
            onPressed: controller.isLoading ? null : _refresh,
            icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
            tooltip: 'Recargar inventario',
          ),
          IconButton(
            onPressed: _isExporting ? null : () => _generarReporteInventario(),
            icon: _isExporting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
                  )
                : Icon(Icons.picture_as_pdf, color: colorScheme.onPrimary),
            tooltip: 'Generar reporte PDF',
          ),
          PopupMenuButton<bool>(
            icon: Icon(
              esVistaTabla ? Icons.view_list : Icons.view_module,
              color: colorScheme.onPrimary,
            ),
            tooltip: 'Cambiar vista',
            onSelected: (value) {
              ref.read(vistaTablaProvider.notifier).state = value;
              _saveViewMode(value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(Icons.view_module, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text('Vista Cards', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text('Vista Tabla', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
            ],
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mensaje informativo sobre el inventario
            if (_showInfoCard)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El inventario muestra el estado actual de todos los productos en los almacenes.',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: colorScheme.onPrimaryContainer, size: 20),
                          onPressed: () {
                            setState(() {
                              _showInfoCard = false;
                              _InventarioPageState._infoCardClosed = true;
                            });
                          },
                          tooltip: 'Cerrar mensaje',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar por producto',
                  hintText: 'Escriba el nombre del producto...',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                          onPressed: () {
                            _searchController.clear();
                            notifier.setSearchTerm(null);
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                ),
                style: TextStyle(color: colorScheme.onSurface),
                onTap: () {
                  if (_filtersExpanded) {
                    setState(() => _filtersExpanded = false);
                  }
                },
                onChanged: (value) {
                  notifier.setSearchTerm(value.isEmpty ? null : value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              child: ExpansionTile(
                title: Text('Filtros', style: TextStyle(color: colorScheme.onSurface)),
                leading: Icon(Icons.filter_list, color: colorScheme.onSurfaceVariant),
                initiallyExpanded: _filtersExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _filtersExpanded = expanded;
                    if (expanded) FocusScope.of(context).unfocus();
                  });
                },
                children: [
                  Container(
                    constraints: BoxConstraints(maxHeight: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton2<int?>(
                          value: controller.selectedCategoria,
                          hint: Text('Filtrar por categoría', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          selectedItemBuilder: (context) {
                            return [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Todas las categorías', style: TextStyle(color: colorScheme.onSurface)),
                              ),
                              ...controller.categorias.map((categoria) => DropdownMenuItem<int>(
                                value: categoria.idcategoria,
                                child: Text(categoria.nombrecategoria, style: TextStyle(color: colorScheme.onSurface)),
                              )),
                            ];
                          },
                          isExpanded: true,
                          buttonStyleData: ButtonStyleData(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            width: 220,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 150,
                            offset: const Offset(0, 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: colorScheme.surfaceContainer,
                            ),
                            width: 220,
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Todas las categorías', style: TextStyle(color: colorScheme.onSurface)),
                            ),
                            ...controller.categorias.map((categoria) => DropdownMenuItem<int>(
                              value: categoria.idcategoria,
                              child: Text(categoria.nombrecategoria, style: TextStyle(color: colorScheme.onSurface)),
                            )),
                          ],
                          onChanged: (value) => notifier.setSelectedCategoria(value),
                          menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 16)),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton2<int?>(
                          value: controller.selectedAlmacen,
                          hint: Text('Filtrar por almacén', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          selectedItemBuilder: (context) {
                            return [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Todos los almacenes', style: TextStyle(color: colorScheme.onSurface)),
                              ),
                              ...controller.almacenes.map((almacen) => DropdownMenuItem<int>(
                                value: almacen.id,
                                child: Text(almacen.nombre, style: TextStyle(color: colorScheme.onSurface)),
                              )),
                            ];
                          },
                          isExpanded: true,
                          buttonStyleData: ButtonStyleData(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            width: 220,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 150,
                            offset: const Offset(0, 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: colorScheme.surfaceContainer,
                            ),
                            width: 220,
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Todos los almacenes', style: TextStyle(color: colorScheme.onSurface)),
                            ),
                            ...controller.almacenes.map((almacen) => DropdownMenuItem<int>(
                              value: almacen.id,
                              child: Text(almacen.nombre, style: TextStyle(color: colorScheme.onSurface)),
                            )),
                          ],
                          onChanged: (value) => notifier.setSelectedAlmacen(value),
                          menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 16)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            notifier.clearFiltros();
                          },
                          child: Text(
                            'Limpiar filtros',
                            style: TextStyle(color: colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (controller.errorMessage != null && !controller.isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Error: ${controller.errorMessage}',
                  style: TextStyle(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            // Mostrar el resumen de inventario si el toggle está activo
            if (_showResumen) _buildResumenInventario(controller),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: colorScheme.primary,
                child: controller.isLoading
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                    : inventarioMostrado.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 60, color: colorScheme.onSurfaceVariant),
                                const SizedBox(height: 12),
                                Text(
                                  'Producto no encontrado.',
                                  style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        : esVistaTabla
                            ? _InventarioTabla(
                                inventario: inventarioMostrado,
                                onEdited: _refresh,
                                isAdminFuture: _isAdminFuture,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: inventarioMostrado.length,
                                itemBuilder: (context, index) {
                                  final item = inventarioMostrado[index];
                                  return _InventarioCard(
                                    inventario: item,
                                    onEdited: _refresh,
                                    isAdminFuture: _isAdminFuture,
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: esVistaTabla
          ? FloatingActionButton(
              onPressed: _isExporting ? null : () => _mostrarVistaPrevia(inventarioMostrado),
              backgroundColor: _isExporting ? colorScheme.onSurface.withOpacity(0.5) : colorScheme.primary,
              tooltip: 'Generar Reporte',
              child: _isExporting
                  ? CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                      strokeWidth: 2,
                    )
                  : Icon(Icons.print, color: colorScheme.onPrimary),
            )
          : null,
    );
  }
}

class _InventarioTabla extends StatelessWidget {
  final List<Inventario> inventario;
  final VoidCallback onEdited;
  final Future<bool> isAdminFuture;

  const _InventarioTabla({
    required this.inventario,
    required this.onEdited,
    required this.isAdminFuture,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainer),
          headingTextStyle: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.surface;
          }),
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Producto')),
            DataColumn(label: Text('Categoría')),
            DataColumn(label: Text('Almacén')),
            DataColumn(label: Text('Stock')),
            DataColumn(label: Text('Precio')),
            DataColumn(label: Text('Estado')),
          ],
          rows: inventario.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return DataRow(
              color: WidgetStateProperty.all(
                index % 2 == 0 ? colorScheme.surfaceContainer.withOpacity(0.3) : colorScheme.surface,
              ),
              cells: [
                DataCell(Text(item.idinventario.toString(), style: TextStyle(color: colorScheme.onSurface))),
                DataCell(Text(
                  item.nombreProducto ?? 'Producto ${item.idproducto}',
                  style: TextStyle(color: colorScheme.onSurface),
                )),
                DataCell(Text(
                  item.nombreCategoria ?? 'Sin categoría',
                  style: TextStyle(color: colorScheme.onSurface),
                )),
                DataCell(Text(
                  item.nombreAlmacen ?? 'Almacén ${item.idalmacen}',
                  style: TextStyle(color: colorScheme.onSurface),
                )),
                DataCell(Text(
                  item.cantidad.toString(),
                  style: TextStyle(
                    color: item.cantidad < 10 ? colorScheme.error : colorScheme.onSurface,
                    fontWeight: item.cantidad < 10 ? FontWeight.w600 : FontWeight.normal,
                  ),
                )),
                DataCell(Text(
                  item.precio != null ? '\$${item.precio!.toStringAsFixed(2)}' : 'N/A',
                  style: TextStyle(color: colorScheme.onSurface),
                )),
                DataCell(
                  Row(
                    children: [
                      Icon(
                        item.cantidad == 0
                            ? Icons.error
                            : item.cantidad < 10
                                ? Icons.warning
                                : Icons.check_circle,
                        color: item.cantidad == 0
                            ? colorScheme.error
                            : item.cantidad < 10
                                ? colorScheme.tertiary
                                : colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.cantidad == 0
                            ? 'Agotado'
                            : item.cantidad < 10
                                ? 'Bajo'
                                : 'Disponible',
                        style: TextStyle(
                          color: item.cantidad == 0
                              ? colorScheme.error
                              : item.cantidad < 10
                                  ? colorScheme.tertiary
                                  : colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _InventarioCard extends StatelessWidget {
  final Inventario inventario;
  final VoidCallback onEdited;
  final Future<bool> isAdminFuture;

  const _InventarioCard({
    required this.inventario,
    required this.onEdited,
    required this.isAdminFuture,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: colorScheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8.0),
        leading: CircleAvatar(
          backgroundColor: inventario.cantidad == 0
              ? colorScheme.error
              : inventario.cantidad < 10
                  ? colorScheme.tertiary
                  : colorScheme.secondary,
          child: Icon(
            inventario.cantidad == 0
                ? Icons.error
                : inventario.cantidad < 10
                    ? Icons.warning
                    : Icons.inventory,
            color: colorScheme.onPrimary,
            size: 24,
          ),
        ),
        title: Text(
          inventario.nombreProducto ?? 'Producto ${inventario.idproducto}',
          style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Categoría: ${inventario.nombreCategoria ?? 'Sin categoría'}\n'
          'Almacén: ${inventario.nombreAlmacen ?? 'Almacén ${inventario.idalmacen}'}\n'
          'Stock: ${inventario.cantidad} unidades\n'
          'Precio: ${inventario.precio != null ? '\$${inventario.precio!.toStringAsFixed(2)}' : 'N/A'}',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              inventario.cantidad == 0
                  ? Icons.error
                  : inventario.cantidad < 10
                      ? Icons.warning
                      : Icons.check_circle,
              color: inventario.cantidad == 0
                  ? colorScheme.error
                  : inventario.cantidad < 10
                      ? colorScheme.tertiary
                      : colorScheme.secondary,
              size: 20,
            ),
            Text(
              inventario.cantidad == 0
                  ? 'Agotado'
                  : inventario.cantidad < 10
                      ? 'Bajo'
                      : 'OK',
              style: TextStyle(
                fontSize: 10,
                color: inventario.cantidad == 0
                    ? colorScheme.error
                    : inventario.cantidad < 10
                        ? colorScheme.tertiary
                        : colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}