import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Enum para perfis de usuário
enum UserRole {
  superAdmin('super_admin', 'Super Administrador'),
  admin('admin', 'Administrador'),
  editor('editor', 'Editor'),
  viewer('viewer', 'Visualizador');

  final String value;
  final String displayName;

  const UserRole(this.value, this.displayName);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.viewer,
    );
  }
}

/// Modelo de usuário administrativo expandido
class UserModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? phone;
  final String passwordHash;
  final UserRole role;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime updatedAt;
  final String? updatedBy;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phone,
    required this.passwordHash,
    required this.role,
    this.isActive = true,
    this.mustChangePassword = false,
    this.lastLoginAt,
    required this.createdAt,
    this.createdBy,
    required this.updatedAt,
    this.updatedBy,
  });

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'password_hash': passwordHash,
      'role': role.value,
      'is_active': isActive ? 1 : 0,
      'must_change_password': mustChangePassword ? 1 : 0,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  /// Create from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String?,
      passwordHash: map['password_hash'] as String,
      role: UserRole.fromString(map['role'] as String),
      isActive: (map['is_active'] as int) == 1,
      mustChangePassword: (map['must_change_password'] as int) == 1,
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      updatedBy: map['updated_by'] as String?,
    );
  }

  /// Hash password with salt
  static String hashPassword(String password, [String? salt]) {
    final saltValue = salt ?? 'terra_vista_salt_2026';
    final bytes = utf8.encode(password + saltValue);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password
  bool verifyPassword(String password) {
    return hashPassword(password) == passwordHash;
  }

  /// Copy with method for updates
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? phone,
    String? passwordHash,
    UserRole? role,
    bool? isActive,
    bool? mustChangePassword,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Get display name for role
  String get roleDisplayName => role.displayName;

  /// Check if user is super admin
  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Check if user can manage other users
  bool get canManageUsers =>
      role == UserRole.superAdmin || role == UserRole.admin;

  /// Check if user can edit content
  bool get canEditContent => role != UserRole.viewer;

  /// Check if user can delete content
  bool get canDeleteContent =>
      role == UserRole.superAdmin || role == UserRole.admin;
}
