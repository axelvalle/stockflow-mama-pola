import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_links/app_links.dart';
import 'dart:async';

class DeepLinkService {
  static AppLinks? _appLinks;
  static StreamSubscription? _subscription;

  static void initialize(BuildContext context) {
    if (kIsWeb) return;

    _appLinks = AppLinks();
    _subscription = _appLinks!.uriLinkStream.listen(
      (Uri? uri) => _handleDeepLink(uri, context),
      onError: (err) {
        // Manejo de errores de deep link
        debugPrint('Error en deep link: $err');
      },
    );
  }

  static void _handleDeepLink(Uri? uri, BuildContext context) {
    if (uri == null) return;

    if (uri.path == '/reset-password') {
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'];
      
      if (token != null && email != null) {
        Navigator.pushNamed(context, '/reset-password', arguments: {
          'token': token,
          'email': email,
        });
      }
    }
    // Aquí puedes agregar más rutas de deep link según sea necesario
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
} 