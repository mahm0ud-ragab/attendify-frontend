// This service handles secure storage of authentication tokens

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Create a secure storage instance
  final _storage = const FlutterSecureStorage();

  // Keys for storing data
  static const String _tokenKey = 'auth_token';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  // Save the JWT token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get the JWT token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Save user information
  Future<void> saveUserInfo({
    required int userId,
    required String name,
    required String email,
    required String role,
  }) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userEmailKey, value: email);
    await _storage.write(key: _userRoleKey, value: role);
  }

  // Get user ID
  Future<int?> getUserId() async {
    final id = await _storage.read(key: _userIdKey);
    return id != null ? int.tryParse(id) : null;
  }

  // Get user name
  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  // Get user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  // Get user role
  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all stored data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}