import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/user/user_activity_controller.dart';
import '../logic/auth/auth_service.dart';

class ActivityLoggerService {
  static final Provider<ActivityLoggerService> provider = Provider<ActivityLoggerService>((ref) {
    return ActivityLoggerService(ref);
  });

  final Ref _ref;
  ActivityLoggerService(this._ref);

  /// Registra una actividad del usuario
  Future<void> logActivity(String actionType, {
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        await _ref.read(userActivityControllerProvider.notifier).logActivity(
          currentUser.id,
          actionType,
          details: details,
          ipAddress: ipAddress,
          userAgent: userAgent,
        );
      }
    } catch (e) {
      print('Error registrando actividad: $e');
    }
  }

  /// Registra actividad de login
  Future<void> logLogin({String? ipAddress, String? userAgent}) async {
    await logActivity('login', 
      details: {'status': 'success'},
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
  }

  /// Registra actividad de logout
  Future<void> logLogout({String? ipAddress, String? userAgent}) async {
    await logActivity('logout',
      details: {'status': 'success'},
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
  }

  /// Registra creación de un elemento
  Future<void> logCreate(String entityType, String entityName, {Map<String, dynamic>? additionalDetails}) async {
    await logActivity('create',
      details: {
        'entity_type': entityType,
        'entity_name': entityName,
        ...?additionalDetails,
      },
    );
  }

  /// Registra actualización de un elemento
  Future<void> logUpdate(String entityType, String entityName, {Map<String, dynamic>? additionalDetails}) async {
    await logActivity('update',
      details: {
        'entity_type': entityType,
        'entity_name': entityName,
        ...?additionalDetails,
      },
    );
  }

  /// Registra eliminación de un elemento
  Future<void> logDelete(String entityType, String entityName, {Map<String, dynamic>? additionalDetails}) async {
    await logActivity('delete',
      details: {
        'entity_type': entityType,
        'entity_name': entityName,
        ...?additionalDetails,
      },
    );
  }

  /// Registra visualización de una página
  Future<void> logView(String pageName, {Map<String, dynamic>? additionalDetails}) async {
    await logActivity('view',
      details: {
        'page_name': pageName,
        ...?additionalDetails,
      },
    );
  }

  /// Registra cambio de contraseña
  Future<void> logPasswordChange() async {
    await logActivity('password_change',
      details: {'status': 'success'},
    );
  }

  /// Registra activación/desactivación de 2FA
  Future<void> log2FAToggle(bool enabled) async {
    await logActivity('2fa_toggle',
      details: {
        'action': enabled ? 'enable' : 'disable',
        'status': 'success',
      },
    );
  }

  /// Registra gestión de usuarios
  Future<void> logUserManagement(String action, String targetUserEmail, {Map<String, dynamic>? additionalDetails}) async {
    await logActivity('user_management',
      details: {
        'action': action,
        'target_user_email': targetUserEmail,
        ...?additionalDetails,
      },
    );
  }

  /// Registra gestión de inventario
  Future<void> logInventoryAction(String action, String productName, {Map<String, dynamic>? additionalDetails}) async {
    await logActivity('inventory_action',
      details: {
        'action': action,
        'product_name': productName,
        ...?additionalDetails,
      },
    );
  }

  /// Registra gestión de productos
  Future<void> logProductAction(String action, String productName, {Map<String, dynamic>? additionalDetails}) async {
    await logActivity('product_action',
      details: {
        'action': action,
        'product_name': productName,
        ...?additionalDetails,
      },
    );
  }

  /// Registra gestión de proveedores
  Future<void> logProviderAction(String action, String providerName, {Map<String, dynamic>? additionalDetails}) async {
    await logActivity('provider_action',
      details: {
        'action': action,
        'provider_name': providerName,
        ...?additionalDetails,
      },
    );
  }

  /// Registra gestión de categorías
  Future<void> logCategoryAction(String action, String categoryName, {Map<String, dynamic>? additionalDetails}) async {
    await logActivity('category_action',
      details: {
        'action': action,
        'category_name': categoryName,
        ...?additionalDetails,
      },
    );
  }

  /// Registra gestión de empresas
  Future<void> logCompanyAction(String action, String companyName, {Map<String, dynamic>? additionalDetails}) async {
    await logActivity('company_action',
      details: {
        'action': action,
        'company_name': companyName,
        ...?additionalDetails,
      },
    );
  }

  /// Registra gestión de almacenes
  Future<void> logWarehouseAction(String action, String warehouseName, {Map<String, dynamic>? additionalDetails}) async {
    await logActivity('warehouse_action',
      details: {
        'action': action,
        'warehouse_name': warehouseName,
        ...?additionalDetails,
      },
    );
  }
} 