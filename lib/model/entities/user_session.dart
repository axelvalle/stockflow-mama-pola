class UserSession {
  final String? id;
  final String userId;
  final String sessionToken;
  final String? deviceInfo;
  final String? ipAddress;
  final String? location;
  final DateTime? createdAt;
  final DateTime? lastActivity;
  final bool isActive;

  UserSession({
    this.id,
    required this.userId,
    required this.sessionToken,
    this.deviceInfo,
    this.ipAddress,
    this.location,
    this.createdAt,
    this.lastActivity,
    this.isActive = true,
  });

  factory UserSession.fromMap(Map<String, dynamic> map) => UserSession(
    id: map['id'],
    userId: map['user_id'],
    sessionToken: map['session_token'],
    deviceInfo: map['device_info'],
    ipAddress: map['ip_address'],
    location: map['location'],
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    lastActivity: map['last_activity'] != null ? DateTime.parse(map['last_activity']) : null,
    isActive: map['is_active'] ?? true,
  );

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'session_token': sessionToken,
    'device_info': deviceInfo,
    'ip_address': ipAddress,
    'location': location,
    'is_active': isActive,
  };
} 