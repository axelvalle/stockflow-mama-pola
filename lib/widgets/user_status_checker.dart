import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/auth/auth_service.dart';

class UserStatusChecker extends ConsumerStatefulWidget {
  final Widget child;
  
  const UserStatusChecker({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<UserStatusChecker> createState() => _UserStatusCheckerState();
}

class _UserStatusCheckerState extends ConsumerState<UserStatusChecker> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });

    try {
      // Verificar si el usuario está baneado
      final isBanned = await AuthService.isCurrentUserBanned();
      
      if (isBanned && mounted) {
        // Cerrar sesión y mostrar mensaje
        await AuthService.logout(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu cuenta ha sido suspendida. Contacta al administrador para más información.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );

        // Navegar al login
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    } catch (e) {
      print('Error verificando estado del usuario: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
} 