class User2FAConfig {
  final String userId;
  final bool isEnabled;
  final String? secretKey;
  final List<String>? backupCodes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User2FAConfig({
    required this.userId,
    this.isEnabled = false,
    this.secretKey,
    this.backupCodes,
    this.createdAt,
    this.updatedAt,
  });

  factory User2FAConfig.fromMap(Map<String, dynamic> map) => User2FAConfig(
    userId: map['user_id'],
    isEnabled: map['is_enabled'] ?? false,
    secretKey: map['secret_key'],
    backupCodes: map['backup_codes'] != null 
        ? List<String>.from(map['backup_codes'])
        : null,
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
  );

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'is_enabled': isEnabled,
    'secret_key': secretKey,
    'backup_codes': backupCodes,
  };
} 