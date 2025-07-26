import 'package:flutter/material.dart';
import 'package:mamapola_app_v1/model/exceptions/ui_errorhandle.dart';

class AppErrorHandler {
  static Widget buildErrorWidget(FlutterErrorDetails errorDetails, BuildContext context) {
    UIErrorHandler.showError(
      context,
      errorDetails.exception,
      displayType: ErrorDisplayType.dialog,
      customTitle: 'Error crítico',
    );
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  static Widget buildInitialErrorWidget(dynamic error) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error inicial: ${UIErrorHandler.getFriendlyMessage(error)}'),
        ),
      ),
    );
  }
} 