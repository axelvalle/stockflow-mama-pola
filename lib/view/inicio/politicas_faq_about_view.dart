import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PoliticasFaqAboutView extends StatefulWidget {
  const PoliticasFaqAboutView({super.key});

  @override
  State<PoliticasFaqAboutView> createState() => _PoliticasFaqAboutViewState();
}

class _PoliticasFaqAboutViewState extends State<PoliticasFaqAboutView> {
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
          title: const Text('Políticas, FAQ y Quiénes Somos'),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
        ),
        backgroundColor: colorScheme.surface,
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection(
              context,
              icon: Icons.security,
              title: 'Políticas de Seguridad',
              description: 'Tus datos están protegidos y solo accesibles para usuarios autorizados. No compartimos tu información con terceros. Utilizamos autenticación segura y cifrado en las comunicaciones. Recuerda cerrar sesión si usas un dispositivo compartido.',
              tips: [
                'Tus datos están protegidos y solo accesibles para usuarios autorizados.',
                'No compartimos tu información con terceros.',
                'Utilizamos autenticación segura y cifrado en las comunicaciones.',
                'Recuerda cerrar sesión si usas un dispositivo compartido.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.question_answer,
              title: 'Preguntas Frecuentes',
              description: '',
              tips: [
                '¿Cómo recupero mi contraseña? En la pantalla de inicio de sesión, pulsa en "¿Olvidaste tu contraseña?" y sigue los pasos.',
                '¿Puedo exportar mis reportes? Sí, en la sección de análisis puedes generar y descargar reportes en PDF.',
                '¿Cómo agrego un nuevo producto? Ve a la sección de productos y pulsa el botón "+" para registrar uno nuevo.',
                '¿Qué hago si tengo problemas técnicos? Contáctanos al correo de soporte que aparece abajo.',
                '¿Puedo cambiar el tema de la app? Sí, en Configuraciones puedes alternar entre modo claro y oscuro.',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.group,
              title: '¿Quiénes Somos?',
              description: 'Somos un grupo de programadores aficionados dedicados a hacer tu gestión de inventario más eficiente y sencilla.',
              tips: [
                'Axel Valle - Programador Full Stack',
                'Moises Zelaya - Programador Backend',
                'Milton Bell - Programador Frontend y DBA',
                'Contacto: stockflow.nicaragua@gmail.com',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, required String description, required List<String> tips}) {
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
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(description, style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, color: colorScheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip, style: TextStyle(fontSize: 16, color: colorScheme.onSurface))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
} 