import 'package:flutter/material.dart';
import 'package:mamapola_app_v1/view/inicio/analytics_page.dart';
import 'package:mamapola_app_v1/view/inicio/settings_view.dart';
import 'package:mamapola_app_v1/view/movimiento_inventario/movimiento_inventario_form.dart';
import 'package:mamapola_app_v1/view/movimiento_inventario/movimiento_inventario_page.dart';
import 'package:mamapola_app_v1/view/inicio/dashboard_page.dart';
import 'package:mamapola_app_v1/view/auth/login_page.dart';
import 'package:mamapola_app_v1/view/auth/signup_page.dart';
import 'package:mamapola_app_v1/view/inicio/lets_startpage.dart';
import 'package:mamapola_app_v1/view/inicio/splashscreen.dart';
import 'package:mamapola_app_v1/view/proveedor/proveedor_page.dart';
import 'package:mamapola_app_v1/view/proveedor/proveedor_form.dart';
import 'package:mamapola_app_v1/view/empresa/empresa_page.dart';
import 'package:mamapola_app_v1/view/empresa/empresa_form.dart';
import 'package:mamapola_app_v1/view/producto/producto_page.dart';
import 'package:mamapola_app_v1/view/producto/producto_form.dart';
import 'package:mamapola_app_v1/view/categoria/categoria_page.dart';
import 'package:mamapola_app_v1/view/categoria/categoria_form.dart';
import 'package:mamapola_app_v1/logic/auth/inactivity_service.dart';
import 'package:mamapola_app_v1/view/inventario/inventario_page.dart';
import 'package:mamapola_app_v1/view/producto/catalogo_page.dart';
import 'package:mamapola_app_v1/view/user/user_profile_page.dart';
import 'package:mamapola_app_v1/view/user/user_management_page.dart';
import 'package:mamapola_app_v1/view/user/user_activity_log_page.dart';
import 'package:mamapola_app_v1/widgets/user_status_checker.dart';
import 'package:mamapola_app_v1/view/inicio/helper_view.dart';
import 'package:mamapola_app_v1/view/inicio/politicas_faq_about_view.dart';
import 'package:mamapola_app_v1/view/auth/reset_password_page.dart';
import 'package:mamapola_app_v1/view/auth/forgot_password_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String letsStart = '/letsstart';
  static const String proveedores = '/proveedores';
  static const String proveedorForm = '/proveedor_form';
  static const String empresas = '/empresas';
  static const String empresaForm = '/empresa_form';
  static const String productos = '/productos';
  static const String productoForm = '/producto_form';
  static const String categorias = '/categorias';
  static const String categoriaForm = '/categoria_form';
  static const String movimientos = '/movimientos';
  static const String movimientoForm = '/movimiento_form';
  static const String userManagement = '/user_management';
  static const String userProfile = '/user_profile';
  static const String userActivityLog = '/user_activity_log';
  static const String settings = '/settings';
  static const String inventario = '/inventario';
  static const String estadisticas = '/estadisticas';
  static const String analytics = '/analytics';
  static const String catalogo = '/catalogo';
  static const String helperView = '/helper_view';
  static const String politicasFaqAbout = '/politicas_faq_about';
  static const String resetPassword = '/reset-password';
  static const String forgotPassword = '/forgot-password';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginPage(),
      signup: (context) => const SignUpPage(),
      dashboard: (context) => const InactivityDetector(
            child: UserStatusChecker(
              child: DashboardPage(),
            ),
          ),
      letsStart: (context) => const LetsStartPage(),
      proveedores: (context) => const InactivityDetector(
            child: UserStatusChecker(
              child: ProveedorPage(),
            ),
          ),
      proveedorForm: (context) => const InactivityDetector(
            child: ProveedorForm(),
          ),
      empresas: (context) => const InactivityDetector(
            child: EmpresaPage(),
          ),
      empresaForm: (context) => const InactivityDetector(
            child: EmpresaForm(),
          ),
      productos: (context) => const InactivityDetector(
            child: UserStatusChecker(
              child: ProductoPage(),
            ),
          ),
      productoForm: (context) => const InactivityDetector(
            child: ProductoForm(),
          ),
      categorias: (context) => const InactivityDetector(
            child: CategoriaPage(),
          ),
      categoriaForm: (context) => const InactivityDetector(
            child: CategoriaForm(),
          ),
      movimientos: (context) => InactivityDetector(
            child: MovimientoInventarioPage(),
          ),
      movimientoForm: (context) => InactivityDetector(
            child: MovimientoInventarioForm(),
          ),
      userManagement: (context) => const InactivityDetector(
            child: UserStatusChecker(
              child: UserManagementPage(),
            ),
          ),
      userProfile: (context) => const InactivityDetector(child: UserProfilePage()),
      userActivityLog: (context) => const InactivityDetector(child: UserActivityLogPage()),
      settings: (context) => const InactivityDetector(child: SettingsView()),
      inventario: (context) => const InventarioPage(),
      estadisticas: (context) => const AnalyticsPage(),
      analytics: (context) => const AnalyticsPage(),
      catalogo: (context) => const CatalogoPage(),
      helperView: (context) => const HelperView(),
      politicasFaqAbout: (context) => const PoliticasFaqAboutView(),
      forgotPassword: (context) => const ForgotPasswordPage(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == resetPassword) {
      final args = settings.arguments as Map<String, dynamic>?;
      final token = args?['token'] as String?;
      final email = args?['email'] as String?;
      return MaterialPageRoute(
        builder: (context) => ResetPasswordPage(token: token, email: email),
      );
    }
    return null;
  }
} 