import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mamapola_app_v1/logic/auth/auth_service.dart';
import 'package:mamapola_app_v1/logic/injection/theme_provider.dart';
import 'package:mamapola_app_v1/services/supabase_service.dart';
import 'package:mamapola_app_v1/services/deep_link_service.dart';
import 'package:mamapola_app_v1/config/app_routes.dart';
import 'package:mamapola_app_v1/config/app_theme.dart';
import 'package:mamapola_app_v1/config/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await SupabaseService.initialize();
    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    runApp(AppErrorHandler.buildInitialErrorWidget(e));
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    if (AuthService.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {});
    }
    // Inicializar deep links
    DeepLinkService.initialize(context);
  }

  @override
  void dispose() {
    AuthService.dispose();
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppTheme.appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.getRoutes(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        ErrorWidget.builder = (errorDetails) => 
            AppErrorHandler.buildErrorWidget(errorDetails, context);
        return child!;
      },
    );
  }
}