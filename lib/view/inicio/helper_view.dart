import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelperView extends StatefulWidget {
  const HelperView({super.key});

  @override
  State<HelperView> createState() => _HelperViewState();
}

class _HelperViewState extends State<HelperView> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manual de Usuario'),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection(
              context,
              icon: Icons.info_outline,
              title: 'Bienvenido/a a Mamapola App',
              description: 'Esta aplicación te permite gestionar inventarios, productos, proveedores y mucho más de forma sencilla y segura. Si es tu primera vez, ¡no te preocupes! Aquí te guiamos paso a paso.',
              example: 'Explora el menú y descubre todas las funciones disponibles.',
              tips: [
                'Manual pensado para principiantes y usuarios avanzados.',
                'Cada sección tiene iconos y ejemplos visuales.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.login,
              title: 'LoginPage (Iniciar sesión)',
              description: 'Pantalla donde ingresas tu correo y contraseña para acceder a la app. Puedes alternar entre modo claro y oscuro.',
              example: 'Ejemplo: Ingresa tu correo y contraseña, luego pulsa "Iniciar sesión".',
              tips: [
                '¿Olvidaste tu contraseña? Usa la opción de recuperación.',
                '¿No tienes cuenta? Pulsa en "Regístrate".',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.person_add_alt_1,
              title: 'SignUpPage (Registro)',
              description: 'Permite crear una nueva cuenta de usuario. Recibirás un correo de verificación.',
              example: 'Ejemplo: Ingresa tu correo y una contraseña segura, luego revisa tu correo.',
              tips: [
                'Si ya tienes cuenta, vuelve a la pantalla de inicio de sesión.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.dashboard_customize,
              title: 'DashboardPage (Inicio / Panel Principal)',
              description: 'Pantalla principal tras iniciar sesión. Muestra un resumen general y acceso rápido a las funciones principales.',
              example: 'Ejemplo: Desde aquí puedes ir a estadísticas, ajustes o ver tu perfil.',
              tips: [
                'Usa la barra inferior para navegar entre secciones.',
                'Accede a tu perfil y notificaciones desde el menú superior.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.analytics_outlined,
              title: 'AnalyticsPage (Análisis/Reportes)',
              description: 'Consulta estadísticas y reportes visuales del inventario. Genera reportes PDF y revisa alertas importantes.',
              example: 'Ejemplo: Pulsa el botón PDF para descargar un reporte de inventario.',
              tips: [
                'Revisa los badges de alerta para identificar productos críticos.',
                'Explora las tablas para ver detalles por almacén y categoría.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.business,
              title: 'EmpresaPage (Empresas)',
              description: 'Gestiona las empresas registradas en el sistema. Agrega, edita o elimina empresas según tus necesidades.',
              example: 'Ejemplo: Pulsa el botón "+" para agregar una nueva empresa.',
              tips: [
                'Solo los administradores pueden eliminar empresas.',
                'Usa el botón de refrescar para actualizar la lista.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.category,
              title: 'CategoriaPage (Categorías)',
              description: 'Administra las categorías de productos para organizar mejor tu inventario.',
              example: 'Ejemplo: Crea una categoría "Bebidas" para agrupar productos similares.',
              tips: [
                'Puedes editar o eliminar categorías existentes.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.inventory_2,
              title: 'ProductoPage (Productos)',
              description: 'Visualiza y gestiona todos los productos del inventario. Usa la barra de búsqueda y los filtros.',
              example: 'Ejemplo: Busca "agua" para ver todos los productos relacionados.',
              tips: [
                'Agrega nuevos productos desde el botón "+".',
                'Edita o elimina productos según sea necesario.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.list_alt,
              title: 'CatalogoPage (Catálogo de Productos)',
              description: 'Consulta el catálogo completo de productos y exporta listados.',
              example: 'Ejemplo: Descarga el catálogo en PDF para compartirlo.',
              tips: [
                'Ideal para ver información detallada de todos los productos.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.people,
              title: 'ProveedorPage (Proveedores)',
              description: 'Administra los proveedores de tu empresa. Relaciona productos con proveedores para un mejor control.',
              example: 'Ejemplo: Agrega un nuevo proveedor y asígnale productos.',
              tips: [
                'Edita o elimina proveedores desde la lista.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.storage,
              title: 'InventarioPage (Inventario)',
              description: 'Consulta el stock disponible en cada almacén. Visualiza cantidades, ubicaciones y alertas de bajo inventario.',
              example: 'Ejemplo: Filtra por almacén para ver el stock específico.',
              tips: [
                'Utiliza los filtros para encontrar productos rápidamente.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.swap_horiz,
              title: 'MovimientoInventarioPage (Movimientos de Inventario)',
              description: 'Registra y consulta entradas, salidas y ajustes de inventario. Cada movimiento queda registrado para control y auditoría.',
              example: 'Ejemplo: Registra una entrada de productos nuevos al almacén.',
              tips: [
                'Filtra por tipo de movimiento, fecha o producto.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.admin_panel_settings,
              title: 'UserManagementPage (Gestión de Usuarios)',
              description: 'Solo para administradores. Agrega, edita o elimina usuarios y asigna roles.',
              example: 'Ejemplo: Cambia el rol de un usuario a administrador.',
              tips: [
                'Gestiona permisos y acceso desde esta sección.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.person,
              title: 'UserProfilePage (Mi Perfil)',
              description: 'Edita tu información personal y cambia tu contraseña para mayor seguridad.',
              example: 'Ejemplo: Actualiza tu correo o cambia tu contraseña.',
              tips: [
                'Mantén tus datos actualizados.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.history,
              title: 'UserActivityLogPage (Historial de Actividad)',
              description: 'Consulta el historial de acciones realizadas por el usuario. Útil para auditoría y seguimiento.',
              example: 'Ejemplo: Revisa cuándo y qué cambios realizaste en el sistema.',
              tips: [
                'Solo visible para administradores.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.settings,
              title: 'SettingsView (Configuraciones)',
              description: 'Ajusta las preferencias de la app, cambia el tema, accede al manual y otras opciones.',
              example: 'Ejemplo: Cambia al modo oscuro desde aquí.',
              tips: [
                'Cierra sesión de forma segura desde esta sección.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.help_outline,
              title: 'HelperView (Manual de Usuario)',
              description: 'Aquí puedes consultar tips, glosario, preguntas frecuentes y explicación de cada sección de la app.',
              example: 'Ejemplo: Lee este manual para aprender a usar la app.',
              tips: [
                'Manual siempre disponible desde Configuraciones.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, required String description, required String example, required List<String> tips}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb, color: colorScheme.secondary, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    example,
                    style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: colorScheme.secondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
} 