import 'package:flutter/material.dart';

import 'dart:async'; // Necesario para Future.delayed

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos FutureBuilder para mostrar el splash y luego navegar.
    return Scaffold(
      body: FutureBuilder<void>( // Cambiado a Future<void> ya que no retorna un bool relevante
        future: _navigateToLetsStart(context), // Llama a la nueva función de navegación
        builder: (context, snapshot) {
          // Mientras el Future se está esperando, mostramos el splash screen.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 180, // Ajusta el tamaño del logo aquí
                      height: 180,
                      child: Image.asset(
                        'assets/logo1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    const Text(
                      'Cargando Mama Pola App...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Cuando el Future termina (después del delay), simplemente mostramos un SizedBox.shrink()
            // porque la navegación ya se ha iniciado dentro de _navigateToLetsStart.
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // Nueva función para manejar el retraso y la navegación
  Future<void> _navigateToLetsStart(BuildContext context) async {
    // Simula una carga de 2 segundos. Ajusta o elimina según sea necesario.
    await Future.delayed(const Duration(seconds: 2));

    // Asegúrate de que el contexto sigue siendo válido antes de navegar.
    if (!context.mounted) return;

    // Redirige a la página /letsstart.
    // Usamos pushReplacementNamed para que el usuario no pueda volver al splash.
    Navigator.pushReplacementNamed(context, '/letsstart');
  }
}