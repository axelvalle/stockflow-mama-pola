import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:mamapola_app_v1/logic/movimiento_inventario/movimiento_inventario_controller.dart';
import 'package:mamapola_app_v1/model/entities/movimiento_inventario.dart';
import 'package:mamapola_app_v1/view/movimiento_inventario/movimiento_inventario_form.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/logic/utils/role_manager.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mamapola_app_v1/services/reportes_service.dart';

final vistaTablaProvider = StateProvider<bool>((ref) => false);

class MovimientoInventarioPage extends ConsumerStatefulWidget {
  const MovimientoInventarioPage({super.key});

  @override
  ConsumerState<MovimientoInventarioPage> createState() => _MovimientoInventarioPageState();
}

class _MovimientoInventarioPageState extends ConsumerState<MovimientoInventarioPage> {
  static bool _infoCardClosed = false; // Mantener cerrado durante la sesión
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();
  bool _filtersExpanded = false;
  bool _showInfoCard = !_infoCardClosed;
  late Future<bool> _isAdminFuture;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null); // Inicializa localización para 'es'
    _isAdminFuture = _isCurrentUserAdmin();
    _loadViewMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(movimientoInventarioControllerProvider.notifier).cargarMovimientos();
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
    final viewMode = prefs.getString('movimientoViewMode') ?? 'cards';
    ref.read(vistaTablaProvider.notifier).state = viewMode == 'table';
  }

  Future<void> _saveViewMode(bool isTableView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('movimientoViewMode', isTableView ? 'table' : 'cards');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    // Limpiar filtros al salir
    ref.read(movimientoInventarioControllerProvider.notifier).clearFiltros();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(movimientoInventarioControllerProvider.notifier).cargarMovimientos();
  }

  Future<void> _generarReporteMovimientos() async {
    setState(() => _isExporting = true);
    
    try {
      final controller = ref.read(movimientoInventarioControllerProvider);
      await ReportesService.generateMovimientosReport(
        context: context,
        onProgress: (isGenerating) {
          if (mounted) {
            setState(() {
              _isExporting = isGenerating;
            });
          }
        },
        filtroTipo: controller.filtroTipo,
        filtroFechaInicio: _fechaInicioController.text.isNotEmpty ? DateTime.parse(_fechaInicioController.text) : null,
        filtroFechaFin: _fechaFinController.text.isNotEmpty ? DateTime.parse(_fechaFinController.text) : null,
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

  Future<void> _selectFechaInicio(BuildContext context, WidgetRef ref) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme, dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.surface),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(movimientoInventarioControllerProvider.notifier).setFechaInicio(picked);
      _fechaInicioController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _selectFechaFin(BuildContext context, WidgetRef ref) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme, dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.surface),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(movimientoInventarioControllerProvider.notifier).setFechaFin(picked);
      _fechaFinController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<String> _getNextReportNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final dateFormat = DateFormat('yyyyMMdd');
    final currentDate = dateFormat.format(DateTime.now());
    final lastReportDate = prefs.getString('lastReportDateMovimientos') ?? '';
    int counter = prefs.getInt('reportCounterMovimientos') ?? 0;

    if (lastReportDate != currentDate) {
      counter = 1;
      await prefs.setString('lastReportDateMovimientos', currentDate);
    } else {
      counter++;
    }

    await prefs.setInt('reportCounterMovimientos', counter);
    return '$currentDate-${counter.toString().padLeft(3, '0')}';
  }

  Future<Uint8List> _generarReporteMovimientosInventario(List<MovimientoInventario> movimientosMostrados) async {
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
            'Reporte de Movimientos de Inventario',
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
            text: 'Este informe detalla los movimientos de inventario registrados en el Comedor Mama Pola, '
                'incluyendo información sobre los productos, almacenes, tipos de movimiento, cantidades, fechas y descripciones asociadas.',
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
                    child: pw.Text('Almacén', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Tipo Movimiento', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Cantidad', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Fecha', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Descripción', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                  ),
                ],
              ),
              ...movimientosMostrados.map((movimiento) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          movimiento.nombreProducto ?? 'Producto ${movimiento.idProducto}',
                          style: pw.TextStyle(font: font, fontSize: 10),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          movimiento.nombreAlmacen ?? 'Almacén ${movimiento.idAlmacen}',
                          style: pw.TextStyle(font: font, fontSize: 10),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          movimiento.tipoMovimiento,
                          style: pw.TextStyle(font: font, fontSize: 10),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          movimiento.cantidad.toString(),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: movimiento.cantidad < 0 ? pw.PdfColor(1, 0, 0) : pw.PdfColor(0, 0, 0),
                          ),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          DateFormat.yMd('es').format(movimiento.fecha),
                          style: pw.TextStyle(font: font, fontSize: 10),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          movimiento.descripcion ?? 'N/A',
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
            text: 'Nota: Este reporte refleja los movimientos de inventario registrados hasta la fecha de generación. '
                'Para más información, contacte al administrador en marinaobando@mamapola.com.',
            style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );

    return await pdf.save();
  }

  Future<void> _mostrarVistaPrevia(List<MovimientoInventario> movimientosMostrados) async {
    setState(() => _isExporting = true);
    final pdfBytes = await _generarReporteMovimientosInventario(movimientosMostrados);
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
                    filename: 'Reporte_Movimientos_Inventario_${await _getNextReportNumber()}.pdf',
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

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(movimientoInventarioControllerProvider);
    final notifier = ref.read(movimientoInventarioControllerProvider.notifier);
    final esVistaTabla = ref.watch(vistaTablaProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Historial de Movimientos'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: controller.isLoading ? null : _refresh,
            icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
            tooltip: 'Recargar movimientos',
          ),
          IconButton(
            onPressed: _isExporting ? null : () => _generarReporteMovimientos(),
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
                      // Mensaje informativo sobre que los movimientos no se pueden editar
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
                          'Los movimientos de inventario no se pueden editar ya que representan transacciones históricas.',
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
                            _MovimientoInventarioPageState._infoCardClosed = true;
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
                labelText: 'Buscar por descripción, producto o tipo',
                hintText: 'Ej. Entrada de manzanas',
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
                          notifier.setSearch('');
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
              onChanged: notifier.setSearch,
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
                    children: [
                      DropdownButton2<String?>(
                        value: controller.filtroTipo == null || controller.filtroTipo == '' ? null : controller.filtroTipo,
                        hint: Text('Filtrar por tipo', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        isExpanded: true,
                        buttonStyleData: ButtonStyleData(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 150,
                          offset: const Offset(0, 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: colorScheme.surfaceContainer,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos', style: TextStyle(color: colorScheme.onSurface)),
                          ),
                          DropdownMenuItem<String>(
                            value: 'entrada',
                            child: Text('Entrada', style: TextStyle(color: colorScheme.onSurface)),
                          ),
                          DropdownMenuItem<String>(
                            value: 'salida',
                            child: Text('Salida', style: TextStyle(color: colorScheme.onSurface)),
                          ),
                          DropdownMenuItem<String>(
                            value: 'ajuste',
                            child: Text('Ajuste', style: TextStyle(color: colorScheme.onSurface)),
                          ),
                        ],
                        onChanged: (value) => notifier.setFiltroTipo(value),
                        menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 16)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fechaInicioController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Fecha Inicio',
                          hintText: 'Selecciona fecha',
                          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                          prefixIcon: Icon(Icons.calendar_today, color: colorScheme.onSurfaceVariant),
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
                          suffixIcon: _fechaInicioController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                                  onPressed: () {
                                    _fechaInicioController.clear();
                                    notifier.setFechaInicio(null);
                                  },
                                )
                              : null,
                        ),
                        style: TextStyle(color: colorScheme.onSurface),
                        onTap: () => _selectFechaInicio(context, ref),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fechaFinController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Fecha Fin',
                          hintText: 'Selecciona fecha',
                          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                          prefixIcon: Icon(Icons.calendar_today, color: colorScheme.onSurfaceVariant),
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
                          suffixIcon: _fechaFinController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                                  onPressed: () {
                                    _fechaFinController.clear();
                                    notifier.setFechaFin(null);
                                  },
                                )
                              : null,
                        ),
                        style: TextStyle(color: colorScheme.onSurface),
                        onTap: () => _selectFechaFin(context, ref),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _fechaInicioController.clear();
                          _fechaFinController.clear();
                          notifier.clearFiltrosFechas();
                        },
                        child: Text(
                          'Limpiar fechas',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (controller.error != null && !controller.isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error: ${controller.error}',
                style: TextStyle(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: colorScheme.primary,
              child: controller.isLoading
                  ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                  : controller.movimientosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: colorScheme.onSurfaceVariant),
                              const SizedBox(height: 12),
                              Text(
                                'Movimiento de inventario no encontrado.',
                                style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : esVistaTabla
                          ? _MovimientoTabla(
                              movimientos: controller.movimientosFiltrados,
                              onEdited: _refresh,
                              isAdminFuture: _isAdminFuture,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: controller.movimientosFiltrados.length,
                              itemBuilder: (context, index) {
                                final movimiento = controller.movimientosFiltrados[index];
                                return _MovimientoCard(
                                  movimiento: movimiento,
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
              onPressed: _isExporting ? null : () => _mostrarVistaPrevia(controller.movimientosFiltrados),
              backgroundColor: _isExporting ? colorScheme.onSurface.withOpacity(0.5) : colorScheme.primary,
              tooltip: 'Generar Reporte',
              child: _isExporting
                  ? CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                      strokeWidth: 2,
                    )
                  : Icon(Icons.print, color: colorScheme.onPrimary),
            )
          : FutureBuilder<bool>(
              future: _isAdminFuture,
              builder: (context, snapshot) {
                final isAdmin = snapshot.hasData && snapshot.data!;
                return FloatingActionButton.extended(
                  tooltip: 'Agregar movimiento',
                  onPressed: isAdmin
                      ? () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const MovimientoInventarioForm()),
                          );
                          if (result == true) await _refresh();
                        }
                      : null,
                  backgroundColor: isAdmin ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.4),
                  foregroundColor: isAdmin ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.6),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                );
              },
            ),
    );
  }
}

class _MovimientoTabla extends StatelessWidget {
  final List<MovimientoInventario> movimientos;
  final VoidCallback onEdited;
  final Future<bool> isAdminFuture;

  const _MovimientoTabla({
    required this.movimientos,
    required this.onEdited,
    required this.isAdminFuture,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final tipoColor = {
      'entrada': colorScheme.secondary,
      'salida': colorScheme.error,
      'ajuste': colorScheme.tertiary,
    };

    final tipoIcon = {
      'entrada': Icons.call_received,
      'salida': Icons.call_made,
      'ajuste': Icons.sync_alt,
    };

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
            DataColumn(label: Text('Almacén')),
            DataColumn(label: Text('Cantidad')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Descripción')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: movimientos.asMap().entries.map((entry) {
            final index = entry.key;
            final movimiento = entry.value;
            return DataRow(
              color: WidgetStateProperty.all(
                index % 2 == 0 ? colorScheme.surfaceContainer.withOpacity(0.3) : colorScheme.surface,
              ),
              cells: [
                DataCell(Text(movimiento.id.toString(), style: TextStyle(color: colorScheme.onSurface))),
                DataCell(Text(
                  movimiento.nombreProducto ?? 'Producto ${movimiento.idProducto}',
                  style: TextStyle(color: colorScheme.onSurface),
                )),
                DataCell(Text(
                  movimiento.nombreAlmacen ?? 'Almacén ${movimiento.idAlmacen}',
                  style: TextStyle(color: colorScheme.onSurface),
                )),
                DataCell(Text(
                  movimiento.cantidad.toString(),
                  style: TextStyle(color: colorScheme.onSurface),
                )),
                DataCell(
                  Row(
                    children: [
                      Icon(
                        tipoIcon[movimiento.tipoMovimiento] ?? Icons.help,
                        color: tipoColor[movimiento.tipoMovimiento] ?? colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        movimiento.tipoMovimiento.toUpperCase(),
                        style: TextStyle(
                          color: tipoColor[movimiento.tipoMovimiento] ?? colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(
                  DateFormat('dd/MM/yyyy').format(movimiento.fecha),
                  style: TextStyle(color: colorScheme.onSurface),
                )),
                DataCell(
                  Text(
                    movimiento.descripcion?.isNotEmpty ?? false
                        ? movimiento.descripcion!
                        : '(Sin descripción)',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                // Los movimientos de inventario no se pueden editar (son historial)
                const DataCell(SizedBox.shrink()),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MovimientoCard extends StatelessWidget {
  final MovimientoInventario movimiento;
  final VoidCallback onEdited;
  final Future<bool> isAdminFuture;

  const _MovimientoCard({
    required this.movimiento,
    required this.onEdited,
    required this.isAdminFuture,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final tipoColor = {
      'entrada': colorScheme.secondary,
      'salida': colorScheme.error,
      'ajuste': colorScheme.tertiary,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: colorScheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8.0),
        leading: CircleAvatar(
          backgroundColor: tipoColor[movimiento.tipoMovimiento] ?? colorScheme.onSurfaceVariant,
          child: Icon(
            movimiento.tipoMovimiento == 'entrada'
                ? Icons.call_received
                : movimiento.tipoMovimiento == 'salida'
                    ? Icons.call_made
                    : Icons.sync_alt,
            color: colorScheme.onPrimary,
            size: 24,
          ),
        ),
        title: Text(
          movimiento.descripcion?.isNotEmpty ?? false
              ? movimiento.descripcion!
              : '(Sin descripción)',
          style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${movimiento.nombreProducto ?? 'Producto ${movimiento.idProducto}'} - '
          '${movimiento.nombreAlmacen ?? 'Almacén ${movimiento.idAlmacen}'}\n'
          '${movimiento.tipoMovimiento.toUpperCase()} - ${movimiento.cantidad} unidades\n'
          '${DateFormat('dd/MM/yyyy').format(movimiento.fecha)}',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        // Los movimientos de inventario no se pueden editar (son historial)
        trailing: const SizedBox.shrink(),
      ),
    );
  }
}