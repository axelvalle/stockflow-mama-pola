import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/services/analytics_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _inventarioFuture;
  late Future<List<Map<String, dynamic>>> _movimientosFuture;
  late Future<List<Map<String, dynamic>>> _bajoInventarioFuture;
  late Future<List<Map<String, dynamic>>> _categoriasFuture;
  late Future<List<Map<String, dynamic>>> _movimientosPorCategoriaFuture;
  
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _reloadData(showSnackbar: false);
  }

  void _reloadData({bool showSnackbar = true}) {
    setState(() {
      _inventarioFuture = _fetchData('vw_inventario_por_almacen');
      _movimientosFuture = _fetchData('vw_movimientos_recientes');
      _bajoInventarioFuture = _fetchData('vw_productos_bajo_inventario');
      _categoriasFuture = _fetchData('vw_productos_por_categoria');
      _movimientosPorCategoriaFuture = _fetchMovimientosPorCategoria();
    });

    if (showSnackbar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Datos recargados'),
              backgroundColor: colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchData(String viewName) async {
    final response = await _supabase.from(viewName).select('*');
    return response;
  }

  Future<List<Map<String, dynamic>>> _fetchMovimientosPorCategoria() async {
    try {
      final response = await _supabase
          .from('movimiento_inventario')
          .select('''
            tipo_movimiento,
            cantidad,
            producto!inner(
              categoria!inner(nombrecategoria)
            )
          ''');

      final data = response as List<dynamic>;
      final categoriasMap = <String, Map<String, int>>{};

      for (var item in data) {
        // Verificar que todos los campos necesarios existan
        if (item['producto'] == null || 
            item['producto']['categoria'] == null || 
            item['producto']['categoria']['nombrecategoria'] == null ||
            item['tipo_movimiento'] == null ||
            item['cantidad'] == null) {
          continue; // Saltar este item si falta algún dato
        }

        final categoria = item['producto']['categoria']['nombrecategoria'] as String;
        final tipo = item['tipo_movimiento'] as String;
        final cantidad = item['cantidad'] as int;

        categoriasMap.putIfAbsent(categoria, () => {'entrada': 0, 'salida': 0, 'ajuste': 0});
        categoriasMap[categoria]![tipo] = (categoriasMap[categoria]![tipo] ?? 0) + cantidad;
      }

      return categoriasMap.entries.map((entry) => {
        'categoria': entry.key,
        'entrada': entry.value['entrada'] ?? 0,
        'salida': entry.value['salida'] ?? 0,
        'ajuste': entry.value['ajuste'] ?? 0,
        'total': (entry.value['entrada'] ?? 0) + (entry.value['salida'] ?? 0) + (entry.value['ajuste'] ?? 0),
      }).toList();
    } catch (e) {
      print('Error al obtener movimientos por categoría: $e');
      return [];
    }
  }

  Future<void> _generateReport() async {
    // Obtener los datos que ya están cargados en las tablas
    final inventarioData = await _inventarioFuture;
    final movimientosData = await _movimientosFuture;
    final bajoInventarioData = await _bajoInventarioFuture;
    final categoriasData = await _categoriasFuture;
    final movimientosPorCategoriaData = await _movimientosPorCategoriaFuture;

    // Llamar al servicio de analytics
    await AnalyticsService.generateAnalyticsReport(
      inventarioData: inventarioData,
      movimientosData: movimientosData,
      bajoInventarioData: bajoInventarioData,
      categoriasData: categoriasData,
      movimientosPorCategoriaData: movimientosPorCategoriaData,
      context: context,
      onProgress: (isGenerating) {
        if (mounted) {
          setState(() {
            _isGeneratingReport = isGenerating;
          });
        }
      },
    );
  }

  Widget _buildDataTable(String title, Future<List<Map<String, dynamic>>> futureData) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: colorScheme.surfaceContainer,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: futureData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text(
                    'Error al cargar datos',
                    style: TextStyle(color: colorScheme.error),
                  );
                }

                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return Text(
                    'No hay datos disponibles',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  );
                }



                final firstRow = data.first;
                final keys = firstRow.keys;
                
                if (keys.isEmpty) {
                  return Text(
                    'No hay columnas disponibles',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  );
                }

                final columns = keys
                    .where((key) => key != 'id' && key != 'created_at')
                    .map((key) => DataColumn(
                          label: Text(
                            key.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ))
                    .toList();

                final rows = data
                    .map((row) => DataRow(
                          cells: keys
                              .where((key) => key != 'id' && key != 'created_at')
                              .map((key) => DataCell(
                                    Text(
                                      row[key]?.toString() ?? 'N/A',
                                      style: TextStyle(color: colorScheme.onSurface),
                                    ),
                                  ))
                              .toList(),
                        ))
                    .toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: columns,
                    rows: rows,
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    dataTextStyle: TextStyle(color: colorScheme.onSurface),
                    border: TableBorder.all(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String description,
    required Future<List<Map<String, dynamic>>> futureData,
    Color? badgeColor,
    int? badgeCount,
    String? tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: colorScheme.surfaceContainer,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Tooltip(
                    message: tooltip ?? '',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor ?? colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            _buildDataTable(title, futureData),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Inventario'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          Tooltip(
            message: 'Recargar datos',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _reloadData(),
            ),
          ),
          Tooltip(
            message: 'Generar reporte PDF',
            child: IconButton(
              icon: _isGeneratingReport
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: _isGeneratingReport ? null : _generateReport,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reloadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _bajoInventarioFuture,
              builder: (context, bajoInvSnapshot) {
                int bajoInvCount = bajoInvSnapshot.data?.length ?? 0;
                Color? badgeColor;
                if (bajoInvCount > 0) {
                  badgeColor = Colors.redAccent;
                } else {
                  badgeColor = Colors.green;
                }
                return Column(
                  children: [
                    _buildSection(
                      icon: Icons.warning_amber_rounded,
                      title: 'Productos con Bajo Inventario',
                      description: 'Estos productos requieren atención inmediata para evitar quiebres de stock.',
                      futureData: _bajoInventarioFuture,
                      badgeColor: badgeColor,
                      badgeCount: bajoInvCount,
                      tooltip: bajoInvCount > 0 ? 'Productos críticos' : 'Sin productos críticos',
                    ),
                    _buildSection(
                      icon: Icons.warehouse,
                      title: 'Inventario por Almacén',
                      description: 'Resumen del stock disponible en cada almacén.',
                      futureData: _inventarioFuture,
                      tooltip: 'Stock total por almacén',
                    ),
                    _buildSection(
                      icon: Icons.history,
                      title: 'Movimientos Recientes',
                      description: 'Últimas entradas y salidas registradas.',
                      futureData: _movimientosFuture,
                      tooltip: 'Entradas y salidas recientes',
                    ),
                    _buildSection(
                      icon: Icons.category,
                      title: 'Movimientos por Categoría',
                      description: 'Flujo de productos agrupado por categoría.',
                      futureData: _movimientosPorCategoriaFuture,
                      tooltip: 'Entradas, salidas y ajustes por categoría',
                    ),
                    _buildSection(
                      icon: Icons.pie_chart,
                      title: 'Distribución por Categoría',
                      description: 'Cantidad de productos por cada categoría.',
                      futureData: _categoriasFuture,
                      tooltip: 'Distribución de productos',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
