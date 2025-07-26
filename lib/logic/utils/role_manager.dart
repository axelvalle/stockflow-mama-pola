// logic/utils/role_manager.dart
class RoleManager {
  static const String adminRole = 'admin';
  static const String userRole = 'user';

  // Check if the user is an admin
  static bool isAdmin(String? role) {
    return role == adminRole;
  }

  // Check if the user is a regular user
  static bool isUser(String? role) {
    return role == userRole || role == null;
  }

  // Get role display name
  static String getRoleDisplayName(String? role) {
    if (role == adminRole) return 'Administrator';
    return 'User';
  }
}