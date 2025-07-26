import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/logic/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mamapola_app_v1/logic/injection/theme_provider.dart';
import 'package:mamapola_app_v1/logic/utils/greetings_util.dart';
import 'package:mamapola_app_v1/logic/utils/role_manager.dart';
import 'package:mamapola_app_v1/services/tutorial_service.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;
  bool _showTutorial = false;

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
      return false;
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      // Inicio: ya estamos en el Dashboard
    } else if (index == 1) {
      // Estadísticas
      Navigator.pushNamed(context, '/estadisticas');
    } else if (index == 2) {
      // Ajustes: navegar a SettingsView
      Navigator.pushNamed(context, '/settings');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final shouldShow = await TutorialService.shouldShowTutorial();
    if (shouldShow && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  void _showUserMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
      items: [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                'Mi Perfil',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'notifications',
          child: Row(
            children: [
              Icon(Icons.notifications, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                'Notificaciones',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                'Cerrar sesión',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'login_register',
          child: Row(
            children: [
              Icon(Icons.person_add, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                'Iniciar con otro usuario',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ],
    ).then((value) async {
      if (value == 'profile') {
        Navigator.pushNamed(context, '/user_profile');
      } else if (value == 'notifications') {
        Navigator.pushNamed(context, '/user_notifications');
      } else if (value == 'logout') {
        await AuthService.logout(context);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/letsstart');
      } else if (value == 'login_register') {
        await AuthService.logout(context);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final greeting = GreetingUtils.getGreeting();
    final colorScheme = Theme.of(context).colorScheme;

    final fullEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Usuario';
    final userEmail = fullEmail.split('@').first;

    return SafeArea(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              elevation: 3,
              surfaceTintColor: colorScheme.surfaceContainer,
              backgroundColor: colorScheme.surface,
              title: Row(
                children: [
                  Icon(Icons.person, size: 24, color: colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FutureBuilder<bool>(
                      future: _isCurrentUserAdmin(),
                      builder: (context, snapshot) {
                        final isAdmin = snapshot.hasData && snapshot.data!;
                        return Text(
                          isAdmin ? userEmail : userEmail,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  FutureBuilder<bool>(
                    future: _isCurrentUserAdmin(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!) {
                        return Icon(
                          Icons.verified,
                          size: 18,
                          color: Colors.blue,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  color: colorScheme.onSurface,
                  tooltip: 'Cambiar tema',
                  onPressed: () => toggleTheme(ref),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  color: colorScheme.onSurface,
                  tooltip: 'Opciones de usuario',
                  onPressed: _showUserMenu,
                ),
              ],
            ),
            body: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Sugerencias para hoy',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<bool>(
                        future: _isCurrentUserAdmin(),
                        builder: (context, snapshot) {
                          final isAdmin = snapshot.hasData && snapshot.data!;
                          return Row(
                            children: [
                              Expanded(
                                child: _SuggestionCard(
                                  icon: Icons.bar_chart,
                                  label: 'Ver estadísticas',
                                  backgroundColor: colorScheme.primaryContainer,
                                  foregroundColor: colorScheme.onPrimaryContainer,
                                  onTap: () => Navigator.pushNamed(context, '/estadisticas'),
                                ),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SuggestionCard(
                                    icon: Icons.admin_panel_settings,
                                    label: 'Gestionar usuarios',
                                    backgroundColor: colorScheme.secondaryContainer,
                                    foregroundColor: colorScheme.onSecondaryContainer,
                                    onTap: () => Navigator.pushNamed(context, '/user_management'),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Acciones Generales',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            childAspectRatio: 1.0,
                            children: [
                              _ModuleCard(
                                icon: Icons.inventory,
                                label: 'Inventario',
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.onPrimaryContainer,
                                onTap: () => Navigator.pushNamed(context, '/inventario'),
                              ),
                              _ModuleCard(
                                icon: Icons.swap_horiz,
                                label: 'Movimientos de Inventario',
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.onPrimaryContainer,
                                onTap: () => Navigator.pushNamed(context, '/movimientos'),
                              ),
                              _ModuleCard(
                                icon: Icons.bar_chart,
                                label: 'Estadísticas',
                                backgroundColor: colorScheme.secondaryContainer,
                                foregroundColor: colorScheme.onSecondaryContainer,
                                onTap: () => Navigator.pushNamed(context, '/estadisticas'),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      FutureBuilder<bool>(
                        future: _isCurrentUserAdmin(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox();
                          }
                          if (snapshot.hasData && snapshot.data!) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Administración',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
                                    return GridView.count(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      physics: const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      childAspectRatio: 1.0,
                                      children: [
                                        _ModuleCard(
                                          icon: Icons.people,
                                          label: 'Gestión de Usuarios',
                                          backgroundColor: colorScheme.tertiaryContainer,
                                          foregroundColor: colorScheme.onTertiaryContainer,
                                          onTap: () => Navigator.pushNamed(context, '/user_management'),
                                        ),
                                        _ModuleCard(
                                          icon: Icons.history,
                                          label: 'Historial de Actividad',
                                          backgroundColor: colorScheme.tertiaryContainer,
                                          foregroundColor: colorScheme.onTertiaryContainer,
                                          onTap: () => Navigator.pushNamed(context, '/user_activity_log'),
                                        ),

                                      ],
                                    );
                                  },
                                ),
                              ],
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: colorScheme.surfaceContainer,
              elevation: 3,
              indicatorColor: colorScheme.primaryContainer,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: colorScheme.onSurfaceVariant),
                  selectedIcon: Icon(Icons.home, color: colorScheme.onPrimaryContainer),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined, color: colorScheme.onSurfaceVariant),
                  selectedIcon: Icon(Icons.bar_chart, color: colorScheme.onPrimaryContainer),
                  label: 'Estadísticas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined, color: colorScheme.onSurfaceVariant),
                  selectedIcon: Icon(Icons.settings, color: colorScheme.onPrimaryContainer),
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
          // Tutorial overlay
          if (_showTutorial)
            TutorialOverlay(
              steps: [
                TutorialStep(
                  title: '¡Bienvenido a Mamapola!',
                  description: 'Te guiaremos a través de las principales funciones del sistema de gestión de inventario.',
                  icon: Icons.home,
                  actionText: 'Comenzar',
                ),
                TutorialStep(
                  title: 'Inventario',
                  description: 'Aquí puedes ver y gestionar todos los productos en tu inventario. Revisa el stock disponible y la información de cada producto.',
                  icon: Icons.inventory,
                  actionText: 'Entendido',
                ),
                TutorialStep(
                  title: 'Movimientos de Inventario',
                  description: 'Registra entradas, salidas y ajustes de inventario. Cada movimiento queda registrado como historial permanente.',
                  icon: Icons.swap_horiz,
                  actionText: 'Entendido',
                ),
                TutorialStep(
                  title: 'Estadísticas',
                  description: 'Visualiza métricas importantes como inventario por almacén, productos con bajo stock y movimientos recientes.',
                  icon: Icons.bar_chart,
                  actionText: 'Entendido',
                ),
                TutorialStep(
                  title: 'Productos',
                  description: 'Gestiona tu catálogo de productos. Agrega nuevos productos, edita información y genera catálogos en PDF.',
                  icon: Icons.category,
                  actionText: 'Entendido',
                ),
                TutorialStep(
                  title: 'Categorías y Proveedores',
                  description: 'Organiza tus productos por categorías y mantén información actualizada de tus proveedores.',
                  icon: Icons.business,
                  actionText: 'Entendido',
                ),
                TutorialStep(
                  title: 'Reportes',
                  description: 'Genera reportes detallados en PDF para análisis de inventario y toma de decisiones.',
                  icon: Icons.picture_as_pdf,
                  actionText: 'Entendido',
                ),
                TutorialStep(
                  title: '¡Listo para empezar!',
                  description: 'Ya conoces las funciones principales. Puedes acceder a cada sección desde el menú principal. ¡Que tengas éxito con tu gestión de inventario!',
                  icon: Icons.check_circle,
                  actionText: 'Finalizar',
                ),
              ],
              onComplete: () {
                setState(() {
                  _showTutorial = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('¡Tutorial completado! Ya puedes usar todas las funciones.'),
                    backgroundColor: colorScheme.primary,
                  ),
                );
              },
              onSkip: () {
                setState(() {
                  _showTutorial = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Tutorial omitido. Puedes acceder a la ayuda desde Configuración.'),
                    backgroundColor: colorScheme.secondary,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;

  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: foregroundColor,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;

  const _SuggestionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}