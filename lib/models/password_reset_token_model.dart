/// Modelo para tokens de redefinição de senha
class PasswordResetTokenModel {
  final String id;
  final String userId;
  final String token;
  final DateTime expiresAt;
  final bool used;
  final DateTime createdAt;

  PasswordResetTokenModel({
    required this.id,
    required this.userId,
    required this.token,
    required this.expiresAt,
    this.used = false,
    required this.createdAt,
  });

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
      'used': used ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from Map
  factory PasswordResetTokenModel.fromMap(Map<String, dynamic> map) {
    return PasswordResetTokenModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      token: map['token'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      used: (map['used'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Check if token is valid
  bool get isValid {
    return !used && DateTime.now().isBefore(expiresAt);
  }

  /// Check if token is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }
}
