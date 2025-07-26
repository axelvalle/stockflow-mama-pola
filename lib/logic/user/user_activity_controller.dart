import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/model/repository/user_activity_log_repository.dart';
import 'package:mamapola_app_v1/model/entities/user_activity_log.dart';

class UserActivityState {
  final bool isLoading;
  final List<UserActivityLog> userActivityLog;
  final List<UserActivityLog> allActivityLog;
  final String? error;
  final String? selectedUserId;
  final String? selectedActionType;
  final DateTime? startDate;
  final DateTime? endDate;

  const UserActivityState({
    this.isLoading = false,
    this.userActivityLog = const [],
    this.allActivityLog = const [],
    this.error,
    this.selectedUserId,
    this.selectedActionType,
    this.startDate,
    this.endDate,
  });

  UserActivityState copyWith({
    bool? isLoading,
    List<UserActivityLog>? userActivityLog,
    List<UserActivityLog>? allActivityLog,
    String? error,
    String? selectedUserId,
    String? selectedActionType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return UserActivityState(
      isLoading: isLoading ?? this.isLoading,
      userActivityLog: userActivityLog ?? this.userActivityLog,
      allActivityLog: allActivityLog ?? this.allActivityLog,
      error: error,
      selectedUserId: selectedUserId ?? this.selectedUserId,
      selectedActionType: selectedActionType ?? this.selectedActionType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

final userActivityControllerProvider = StateNotifierProvider<UserActivityController, UserActivityState>((ref) {
  return UserActivityController(UserActivityLogRepository());
});

class UserActivityController extends StateNotifier<UserActivityState> {
  final UserActivityLogRepository _activityRepository;

  UserActivityController(this._activityRepository)
      : super(const UserActivityState());

  Future<void> loadUserActivityLog(String userId, {int? limit}) async {
    state = state.copyWith(isLoading: true, error: null, selectedUserId: userId);
    try {
      final activities = await _activityRepository.getUserActivityLog(userId, limit: limit);
      state = state.copyWith(isLoading: false, userActivityLog: activities);
    } catch (e) {
      print('Error en loadUserActivityLog: $e'); // Debug
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAllActivityLog({int? limit}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final activities = await _activityRepository.getAllActivityLog(limit: limit);
      state = state.copyWith(isLoading: false, allActivityLog: activities);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadActivityByType(String userId, String actionType, {int? limit}) async {
    state = state.copyWith(isLoading: true, error: null, selectedActionType: actionType);
    try {
      final activities = await _activityRepository.getActivityByType(userId, actionType, limit: limit);
      state = state.copyWith(isLoading: false, userActivityLog: activities);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadActivityByDateRange(String userId, DateTime startDate, DateTime endDate) async {
    state = state.copyWith(
      isLoading: true, 
      error: null, 
      startDate: startDate, 
      endDate: endDate
    );
    try {
      final activities = await _activityRepository.getActivityByDateRange(userId, startDate, endDate);
      state = state.copyWith(isLoading: false, userActivityLog: activities);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logActivity(String userId, String actionType, {
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      await _activityRepository.logActionActivity(
        userId,
        actionType,
        details,
        ipAddress,
        userAgent,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logLoginActivity(String userId, String ipAddress, String userAgent) async {
    try {
      await _activityRepository.logLoginActivity(userId, ipAddress, userAgent);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logLogoutActivity(String userId, String ipAddress, String userAgent) async {
    try {
      await _activityRepository.logLogoutActivity(userId, ipAddress, userAgent);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearFilters() {
    state = state.copyWith(
      selectedActionType: null,
      startDate: null,
      endDate: null,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  List<UserActivityLog> getFilteredActivities() {
    List<UserActivityLog> activities = state.userActivityLog;

    if (state.selectedActionType != null) {
      activities = activities.where((activity) => 
        activity.actionType == state.selectedActionType
      ).toList();
    }

    if (state.startDate != null) {
      activities = activities.where((activity) => 
        activity.createdAt != null && 
        activity.createdAt!.isAfter(state.startDate!)
      ).toList();
    }

    if (state.endDate != null) {
      activities = activities.where((activity) => 
        activity.createdAt != null && 
        activity.createdAt!.isBefore(state.endDate!.add(const Duration(days: 1)))
      ).toList();
    }

    return activities;
  }

  Map<String, int> getActivitySummary() {
    final Map<String, int> summary = {};
    
    for (final activity in state.userActivityLog) {
      summary[activity.actionType] = (summary[activity.actionType] ?? 0) + 1;
    }
    
    return summary;
  }
} 