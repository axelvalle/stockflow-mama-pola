class UserActivityLog {
  final String? id;
  final String userId;
  final String actionType;
  final Map<String, dynamic>? actionDetails;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;

  UserActivityLog({
    this.id,
    required this.userId,
    required this.actionType,
    this.actionDetails,
    this.ipAddress,
    this.userAgent,
    this.createdAt,
  });

  factory UserActivityLog.fromMap(Map<String, dynamic> map) => UserActivityLog(
    id: map['id'],
    userId: map['user_id'],
    actionType: map['action_type'],
    actionDetails: map['action_details'],
    ipAddress: map['ip_address'],
    userAgent: map['user_agent'],
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
  );

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'action_type': actionType,
    'action_details': actionDetails,
    'ip_address': ipAddress,
    'user_agent': userAgent,
  };
} 