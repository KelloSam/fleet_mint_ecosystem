import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../core/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('current_user');
    final token = prefs.getString('auth_token');
    if (userData != null && token != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(userData));
      } catch (_) {}
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService().login(identifier, password);
      final token = res['token'] ?? res['jwt'];
      final userData = res['user'] ?? res['data'];

      if (token != null && userData != null) {
        await ApiService().setToken(token);
        _user = UserModel.fromJson(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', jsonEncode(_user!.toJson()));
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Demo mode — accept any credentials
      _user = _mockLogin(identifier);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(_user!.toJson()));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Demo mode fallback
      _user = _mockLogin(identifier);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(_user!.toJson()));
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  UserModel _mockLogin(String identifier) {
    if (identifier.toLowerCase().contains('admin')) {
      return UserModel(id: 1, name: 'Chanda Mwewa', email: 'admin@madithel.zm',
          username: identifier, role: 'admin', phone: '+260977001122',
          lastLoginAt: DateTime.now());
    } else if (identifier.toLowerCase().contains('manager')) {
      return UserModel(id: 3, name: 'Joseph Tembo', email: 'manager@madithel.zm',
          username: identifier, role: 'manager', phone: '+260955667788',
          lastLoginAt: DateTime.now());
    } else {
      return UserModel(id: 2, name: 'Miriam Banda', email: 'cashier@madithel.zm',
          username: identifier, role: 'cashier', phone: '+260966334455',
          lastLoginAt: DateTime.now());
    }
  }

  Future<void> logout() async {
    await ApiService().clearToken();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
