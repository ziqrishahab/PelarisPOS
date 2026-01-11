import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  User? _currentUser;
  String? _token;

  AuthService()
    : _secureStorage = const FlutterSecureStorage(aOptions: AndroidOptions());

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    // Load token from secure storage
    _token = await _secureStorage.read(key: _tokenKey);

    // Load user data from shared prefs
    final userJson = _prefs?.getString(_userKey);
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(json.decode(userJson));
      } catch (e) {
        // Invalid data, clear it
        await clearAuth();
      }
    }
  }

  // Get current token
  Future<String?> getToken() async {
    _token ??= await _secureStorage.read(key: _tokenKey);
    return _token;
  }

  // Get current user
  User? get currentUser => _currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _token != null && _currentUser != null;

  // Get cabang ID
  String? get cabangId => _currentUser?.cabang?.id;

  // Save auth data after login
  Future<void> saveAuth(String token, User user) async {
    _token = token;
    _currentUser = user;

    // Save token securely
    await _secureStorage.write(key: _tokenKey, value: token);

    // Save user data
    await _prefs?.setString(_userKey, json.encode(user.toJson()));
  }

  // Update user data
  Future<void> updateUser(User user) async {
    _currentUser = user;
    await _prefs?.setString(_userKey, json.encode(user.toJson()));
  }

  // Clear auth data (logout)
  Future<void> logout() async {
    await clearAuth();
  }

  Future<void> clearAuth() async {
    _token = null;
    _currentUser = null;
    await _secureStorage.delete(key: _tokenKey);
    await _prefs?.remove(_userKey);
  }

  // Check user role
  bool get isOwner => _currentUser?.role == 'OWNER';
  bool get isManager => _currentUser?.role == 'MANAGER';
  bool get isAdmin => _currentUser?.role == 'ADMIN';
  bool get isKasir => _currentUser?.role == 'KASIR';
  bool get isOwnerOrManager => isOwner || isManager;
}
