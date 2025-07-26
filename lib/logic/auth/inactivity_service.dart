import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/logic/auth/auth_service.dart';
import 'package:mamapola_app_v1/view/inicio/lets_startpage.dart';

final inactivityProvider = StateNotifierProvider<InactivityNotifier, DateTime>(
  (ref) => InactivityNotifier(),
);

class InactivityNotifier extends StateNotifier<DateTime> with WidgetsBindingObserver {
  InactivityNotifier() : super(DateTime.now()) {
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  Timer? _timer;
  DateTime? _backgroundTime;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      state = DateTime.now(); // Actualiza el estado periódicamente
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now();
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final diff = DateTime.now().difference(_backgroundTime!);
        if (diff.inMinutes >= 5) {
          // Notificar inactividad si el tiempo en segundo plano excede 5 minutos
          this.state = DateTime.now().subtract(const Duration(minutes: 5));
        }
      }
      _startTimer();
    }
  }

  void resetInactivityTime() {
    state = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class InactivityDetector extends ConsumerWidget {
  final Widget child;

  const InactivityDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<DateTime>(inactivityProvider, (previous, next) {
      final now = DateTime.now();
      final diff = now.difference(next);
      if (diff.inMinutes >= 5) {
        _logoutDueToInactivity(context);
      }
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => ref.read(inactivityProvider.notifier).resetInactivityTime(),
      onPointerMove: (_) => ref.read(inactivityProvider.notifier).resetInactivityTime(),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (_) => ref.read(inactivityProvider.notifier).resetInactivityTime(),
        child: child,
      ),
    );
  }

  Future<void> _logoutDueToInactivity(BuildContext context) async {
    try {
      await AuthService.logout(context);
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LetsStartPage()),
        (route) => false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
      debugPrint('Error al cerrar sesión por inactividad: $e');
    }
  }
}