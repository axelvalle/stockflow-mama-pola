// logic/user/user_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/repository/user_repository.dart';
import 'user_state.dart';

final userControllerProvider = StateNotifierProvider<UserController, UserState>((ref) {
  return UserController(UserRepository());
});

class UserController extends StateNotifier<UserState> {
  final UserRepository _userRepository;

  UserController(this._userRepository) : super(const UserState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true);
    try {
      final users = await _userRepository.getAllUsers();
      state = state.copyWith(isLoading: false, users: users);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _userRepository.deleteUser(userId);
      await loadUsers(); // Refrescar la lista
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateUserProfile(String userId, String nombre, String telefono) async {
    try {
      await _userRepository.updateUserProfile(userId, nombre, telefono);
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _userRepository.updateUserRole(userId, newRole);
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateUserStatus(String userId, String newStatus) async {
    try {
      await _userRepository.updateUserStatus(userId, newStatus);
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}