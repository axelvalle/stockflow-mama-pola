import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _tutorialSkippedKey = 'tutorial_skipped';

  /// Verifica si el usuario ha completado o saltado el tutorial
  static Future<bool> hasCompletedTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  /// Verifica si el usuario ha saltado el tutorial
  static Future<bool> hasSkippedTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialSkippedKey) ?? false;
  }

  /// Marca el tutorial como completado
  static Future<void> markTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  /// Marca el tutorial como saltado
  static Future<void> markTutorialSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialSkippedKey, true);
  }

  /// Verifica si debe mostrar el tutorial
  static Future<bool> shouldShowTutorial() async {
    final completed = await hasCompletedTutorial();
    final skipped = await hasSkippedTutorial();
    return !completed && !skipped;
  }

  /// Resetea el estado del tutorial (útil para testing)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialCompletedKey);
    await prefs.remove(_tutorialSkippedKey);
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final String actionText;
  final VoidCallback? onAction;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.actionText,
    this.onAction,
  });
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const TutorialOverlay({
    super.key,
    required this.steps,
    this.onComplete,
    this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _completeTutorial() async {
    await TutorialService.markTutorialCompleted();
    if (mounted) {
      widget.onComplete?.call();
    }
  }

  void _skipTutorial() async {
    await TutorialService.markTutorialSkipped();
    if (mounted) {
      widget.onSkip?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentStep = widget.steps[_currentStep];

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Icono del paso actual
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        currentStep.icon,
                        size: 32,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Título
                    Text(
                      currentStep.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Descripción
                    Text(
                      currentStep.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Indicadores de progreso
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.steps.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentStep
                                ? colorScheme.primary
                                : colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Botones de acción
                    Row(
                      children: [
                        // Botón Saltar
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _skipTutorial,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Saltar Tutorial'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Botón de acción principal
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              currentStep.onAction?.call();
                              _nextStep();
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(currentStep.actionText),
                          ),
                        ),
                      ],
                    ),
                    
                    // Botón anterior (solo si no es el primer paso)
                    if (_currentStep > 0) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _previousStep,
                        child: const Text('Anterior'),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
} 