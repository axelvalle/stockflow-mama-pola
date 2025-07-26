import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/logic/auth/auth_service.dart';
import 'package:mamapola_app_v1/logic/injection/theme_provider.dart';
import 'package:mamapola_app_v1/logic/utils/role_manager.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  Future<bool> _isCurrentUserAdmin() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;
    try {
      final userData = await Supabase.instance.client
          .from('usuarios_app')
          .select('rol')
          .eq('id', currentUser.id)
          .single();
      return RoleManager.isAdmin(userData['rol']);
    } catch (e) {
      // No usar context aquí para evitar el warning
      return false;
    }
  }

  void _toggleTheme(WidgetRef ref) {
    final currentTheme = ref.read(themeModeProvider);
    ref.read(themeModeProvider.notifier).state =
        currentTheme == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.logout(context);
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        UIErrorHandler.showError(
          context,
          e,
          displayType: ErrorDisplayType.snackBar,
          customTitle: 'Error al cerrar sesión',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configuraciones'),
          centerTitle: true,
          elevation: 2,
        ),
        body: ListView(
          children: [
            // Sección: Gestión
            const ListTile(
              title: Text(
                'Gestión',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Empresas'),
              onTap: () => Navigator.pushNamed(context, '/empresas'),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categorías'),
              onTap: () => Navigator.pushNamed(context, '/categorias'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Productos'),
              onTap: () => Navigator.pushNamed(context, '/productos'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Proveedores'),
              onTap: () => Navigator.pushNamed(context, '/proveedores'),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Movimientos de Inventario'),
              onTap: () => Navigator.pushNamed(context, '/movimientos'),
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Inventario'),
              onTap: () => Navigator.pushNamed(context, '/inventario'),
            ), // Added InventarioPage
            FutureBuilder<bool>(
              future: _isCurrentUserAdmin(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('Cargando permisos...'),
                  );
                }
                if (snapshot.hasData && snapshot.data!) {
                  return ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Usuarios'),
                    onTap: () => Navigator.pushNamed(context, '/user_management'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Divider(),

            // Sección: Reportes
            const ListTile(
              title: Text(
                'Reportes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Catálogo de Productos'),
              subtitle: const Text('Ver catálogo de productos'),
              onTap: () => Navigator.pushNamed(context, '/catalogo'),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Reporte de Análisis'),
              subtitle: const Text('Generar reporte de analytics'),
              onTap: () => Navigator.pushNamed(context, '/analytics'),
            ),
            const Divider(),

            // Sección: Cuenta
            const ListTile(
              title: Text(
                'Cuenta',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Mi Perfil'),
              subtitle: Text(AuthService.currentUser?.email ?? "Usuario"),
              onTap: () => Navigator.pushNamed(context, '/user_profile'),
            ),

            FutureBuilder<bool>(
              future: _isCurrentUserAdmin(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasData && snapshot.data!) {
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Historial de Actividad'),
                    subtitle: const Text('Ver mi historial de actividad'),
                    onTap: () => Navigator.pushNamed(context, '/user_activity_log'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () => _logout(context),
            ),
            const Divider(),

            // Sección: Administración (solo para admins)
            FutureBuilder<bool>(
              future: _isCurrentUserAdmin(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasData && snapshot.data!) {
                  return Column(
                    children: [
                      const ListTile(
                        title: Text(
                          'Administración',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        dense: true,
                      ),
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings),
                        title: const Text('Gestión de Usuarios'),
                        subtitle: const Text('Administrar usuarios del sistema'),
                        onTap: () => Navigator.pushNamed(context, '/user_management'),
                      ),

                      const Divider(),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Sección: Ajustes
            const ListTile(
              title: Text(
                'Ajustes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Tema'),
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: (_) => _toggleTheme(ref),
              ),
            ),

            // Sección: Ayuda y Manual
            const ListTile(
              title: Text(
                'Ayuda',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Manual de Usuario'),
              subtitle: const Text('Tips y funcionalidades para usuarios y administradores'),
              onTap: () => Navigator.pushNamed(context, '/helper_view'),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Políticas, FAQ y Quiénes Somos'),
              subtitle: const Text('Seguridad, preguntas frecuentes y nuestro equipo'),
              onTap: () => Navigator.pushNamed(context, '/politicas_faq_about'),
            ),
          ],
        ),
      ),
    );
  }
}