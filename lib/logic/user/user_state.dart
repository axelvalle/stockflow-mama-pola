// logic/user/user_state.dart
import 'package:equatable/equatable.dart';

class UserState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> users;
  final String? error;

  const UserState({
    this.isLoading = false,
    this.users = const [],
    this.error,
  });

  UserState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? users,
    String? error,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, users, error];
}