import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isVisitorMode = false;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isVisitorMode => _isVisitorMode;
  bool get isLoading => _isLoading;

  // Check if current user is admin (has elevated privileges)
  bool get isAdmin =>
      _isAuthenticated &&
      !_isVisitorMode &&
      _currentUser != null &&
      (_currentUser!.role == UserRole.admin ||
          _currentUser!.role == UserRole.superAdmin);

  // Check if current user is super admin
  bool get isSuperAdmin =>
      _isAuthenticated &&
      !_isVisitorMode &&
      _currentUser != null &&
      _currentUser!.role == UserRole.superAdmin;

  // Check login status from shared preferences
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('username')) return;

    final username = prefs.getString('username');
    if (username == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final user = await DatabaseService.instance.getUserByUsername(username);
      if (user != null && user.isActive) {
        _currentUser = user;
        _isAuthenticated = true;
        _isVisitorMode = false;
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login as user
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await DatabaseService.instance.authenticateUser(
        username,
        password,
      );
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        _isVisitorMode = false;

        // Save session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', user.username);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MANAGING USERS (Admin Only)

  Future<List<UserModel>> getAllUsers() async {
    if (!isAdmin) return [];
    try {
      return await DatabaseService.instance.getAllUsers();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  Future<bool> createUser(UserModel user) async {
    if (!isAdmin) return false;
    try {
      return await DatabaseService.instance.createUser(user);
    } catch (e) {
      debugPrint('Error creating user: $e');
      return false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    if (!isAdmin) return false;
    try {
      final success = await DatabaseService.instance.updateUser(user);
      // Update local state if updating self
      if (success && _currentUser?.id == user.id) {
        _currentUser = user;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    if (!isAdmin) return false;
    try {
      return await DatabaseService.instance.deleteUser(id);
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  // Enter visitor mode
  void enterVisitorMode() {
    _isVisitorMode = true;
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    _isVisitorMode = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');

    notifyListeners();
  }
}
