import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/injection/theme_provider.dart';

class LetsStartPage extends ConsumerWidget {
  const LetsStartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkTheme = themeMode == ThemeMode.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    void showHelpDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Necesitas ayuda?'),
          content: const Text('Bienvenido a StockFlow. Aquí puedes gestionar tus inventarios de forma sencilla y eficiente. Usa los botones para iniciar sesión o registrarte. Si tienes dudas, contáctanos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: showHelpDialog,
        backgroundColor: colorScheme.primary,
        tooltip: 'Ayuda',
        child: Icon(
          Icons.help_outline,
          color: isDarkTheme ? colorScheme.onPrimary : Colors.white,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeIn,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo con fondo degradado
                      Container(
                        width: size.width * 0.38,
                        height: size.width * 0.38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withOpacity(0.7),
                              colorScheme.secondary.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: ClipOval(
                            child: Image.asset('assets/logo1.png'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Gestión eficiente y sencilla de inventarios',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '¡Optimiza tu almacén y ahorra tiempo con StockFlow!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Powered by StockFlow v1.0',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.normal,
                            ),
                      ),
                      const SizedBox(height: 32),
                      // Tarjeta de botones
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 3,
                        color: colorScheme.surface.withOpacity(0.85),
                        shadowColor: colorScheme.shadow.withOpacity(0.10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.login_outlined),
                                  label: const Text(
                                    'Iniciar sesión',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/login');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.app_registration_outlined),
                                  label: const Text(
                                    'Registrarse',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                    side: BorderSide(
                                      color: colorScheme.primary,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '© Derechos Reservados Axel Valle 2025',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Selector de tema más elegante
            Positioned(
              top: 12,
              right: 12,
              child: Tooltip(
                message: isDarkTheme ? 'Tema oscuro' : 'Tema claro',
                child: IconButton(
                  icon: Icon(
                    isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                    color: colorScheme.primary,
                  ),
                  onPressed: () => toggleTheme(ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}