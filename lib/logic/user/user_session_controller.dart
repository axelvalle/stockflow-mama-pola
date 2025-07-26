import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/model/repository/user_session_repository.dart';
import 'package:mamapola_app_v1/model/entities/user_session.dart';
import 'package:mamapola_app_v1/model/repository/user_activity_log_repository.dart';

class UserSessionState {
  final bool isLoading;
  final List<UserSession> userSessions;
  final List<UserSession> allActiveSessions;
  final String? error;
  final String? currentSessionId;

  const UserSessionState({
    this.isLoading = false,
    this.userSessions = const [],
    this.allActiveSessions = const [],
    this.error,
    this.currentSessionId,
  });

  UserSessionState copyWith({
    bool? isLoading,
    List<UserSession>? userSessions,
    List<UserSession>? allActiveSessions,
    String? error,
    String? currentSessionId,
  }) {
    return UserSessionState(
      isLoading: isLoading ?? this.isLoading,
      userSessions: userSessions ?? this.userSessions,
      allActiveSessions: allActiveSessions ?? this.allActiveSessions,
      error: error,
      currentSessionId: currentSessionId ?? this.currentSessionId,
    );
  }
}

final userSessionControllerProvider = StateNotifierProvider<UserSessionController, UserSessionState>((ref) {
  return UserSessionController(
    UserSessionRepository(),
    UserActivityLogRepository(),
  );
});

class UserSessionController extends StateNotifier<UserSessionState> {
  final UserSessionRepository _sessionRepository;
  final UserActivityLogRepository _activityRepository;

  UserSessionController(this._sessionRepository, this._activityRepository)
      : super(const UserSessionState());

  Future<void> loadUserSessions(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sessions = await _sessionRepository.getUserSessions(userId);
      state = state.copyWith(isLoading: false, userSessions: sessions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAllActiveSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sessions = await _sessionRepository.getAllActiveSessions();
      state = state.copyWith(isLoading: false, allActiveSessions: sessions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createSession(String userId, String sessionToken, {
    String? deviceInfo,
    String? ipAddress,
    String? location,
  }) async {
    try {
      final session = UserSession(
        userId: userId,
        sessionToken: sessionToken,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
        location: location,
      );

      await _sessionRepository.createSession(session);
      
      // Registrar actividad de login
      await _activityRepository.logLoginActivity(
        userId,
        ipAddress ?? 'Unknown',
        deviceInfo ?? 'Unknown',
      );

      // Actualizar la lista de sesiones
      await loadUserSessions(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateLastActivity(String sessionId) async {
    try {
      await _sessionRepository.updateLastActivity(sessionId);
      
      // Actualizar la sesión en el estado local
      final updatedSessions = state.userSessions.map((session) {
        if (session.id == sessionId) {
          return UserSession(
            id: session.id,
            userId: session.userId,
            sessionToken: session.sessionToken,
            deviceInfo: session.deviceInfo,
            ipAddress: session.ipAddress,
            location: session.location,
            createdAt: session.createdAt,
            lastActivity: DateTime.now(),
            isActive: session.isActive,
          );
        }
        return session;
      }).toList();

      state = state.copyWith(userSessions: updatedSessions);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> terminateSession(String sessionId, String userId) async {
    try {
      await _sessionRepository.terminateSession(sessionId);
      
      // Registrar actividad de logout si es la sesión actual
      if (sessionId == state.currentSessionId) {
        await _activityRepository.logLogoutActivity(
          userId,
          'Unknown',
          'Unknown',
        );
      }

      // Actualizar la lista de sesiones
      await loadUserSessions(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> terminateAllUserSessions(String userId) async {
    try {
      await _sessionRepository.terminateAllUserSessions(userId);
      
      // Registrar actividad de logout
      await _activityRepository.logLogoutActivity(
        userId,
        'Unknown',
        'Unknown',
      );

      // Actualizar la lista de sesiones
      await loadUserSessions(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> terminateOtherUserSessions(String userId, String currentSessionId) async {
    try {
      await _sessionRepository.terminateOtherUserSessions(userId, currentSessionId);
      
      // Actualizar la lista de sesiones
      await loadUserSessions(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setCurrentSessionId(String sessionId) {
    state = state.copyWith(currentSessionId: sessionId);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
} 