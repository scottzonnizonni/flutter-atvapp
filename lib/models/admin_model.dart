import 'package:crypto/crypto.dart';
import 'dart:convert';

// Admin user model
class AdminModel {
  final String id;
  final String username;
  final String passwordHash;
  final String role;
  final DateTime createdAt;

  AdminModel({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      id: map['id'] as String,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      role: map['role'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Hash password
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify password
  bool verifyPassword(String password) {
    return hashPassword(password) == passwordHash;
  }
}
