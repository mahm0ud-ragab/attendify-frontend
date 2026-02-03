// This service handles secure storage of authentication tokens and app settings

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  // Create a secure storage instance with platform-specific options
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // --------------------------------------------------------------------------
  // Storage Keys - Centralized for easy management
  // --------------------------------------------------------------------------

  // Authentication Keys
  static const String _tokenKey = 'auth_token';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  // Settings Keys
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _biometricsEnabledKey = 'biometrics_enabled';
  static const String _localeKey = 'locale';
  static const String _themeKey = 'theme';

  // Session Keys
  static const String _lastLoginKey = 'last_login';
  static const String _tokenExpiryKey = 'token_expiry';

  // --------------------------------------------------------------------------
  // Generic Storage Methods
  // --------------------------------------------------------------------------

  /// Save a boolean value
  Future<void> setBool(String key, bool value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (e) {
      debugPrint('Error saving boolean value for key $key: $e');
      rethrow;
    }
  }

  /// Get a boolean value with default fallback
  Future<bool?> getBool(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value == null) return null;
      return value.toLowerCase() == 'true';
    } catch (e) {
      debugPrint('Error reading boolean value for key $key: $e');
      return null;
    }
  }

  /// Save a string value
  Future<void> setString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('Error saving string value for key $key: $e');
      rethrow;
    }
  }

  /// Get a string value
  Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('Error reading string value for key $key: $e');
      return null;
    }
  }

  /// Save an integer value
  Future<void> setInt(String key, int value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (e) {
      debugPrint('Error saving integer value for key $key: $e');
      rethrow;
    }
  }

  /// Get an integer value
  Future<int?> getInt(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null ? int.tryParse(value) : null;
    } catch (e) {
      debugPrint('Error reading integer value for key $key: $e');
      return null;
    }
  }

  /// Save a double value
  Future<void> setDouble(String key, double value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (e) {
      debugPrint('Error saving double value for key $key: $e');
      rethrow;
    }
  }

  /// Get a double value
  Future<double?> getDouble(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null ? double.tryParse(value) : null;
    } catch (e) {
      debugPrint('Error reading double value for key $key: $e');
      return null;
    }
  }

  /// Delete a specific key
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('Error deleting key $key: $e');
      rethrow;
    }
  }

  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      debugPrint('Error checking key $key: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // Authentication Methods
  // --------------------------------------------------------------------------

  /// Save the JWT token with optional expiry
  Future<void> saveToken(String token, {DateTime? expiresAt}) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      if (expiresAt != null) {
        await _storage.write(
          key: _tokenExpiryKey,
          value: expiresAt.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error saving token: $e');
      rethrow;
    }
  }

  /// Get the JWT token
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Error reading token: $e');
      return null;
    }
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    try {
      final expiryString = await _storage.read(key: _tokenExpiryKey);
      if (expiryString == null) return false;

      final expiry = DateTime.parse(expiryString);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      debugPrint('Error checking token expiry: $e');
      return false;
    }
  }

  /// Get token expiry date
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryString = await _storage.read(key: _tokenExpiryKey);
      return expiryString != null ? DateTime.parse(expiryString) : null;
    } catch (e) {
      debugPrint('Error getting token expiry: $e');
      return null;
    }
  }

  /// Save user information
  Future<void> saveUserInfo({
    required int userId,
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _userIdKey, value: userId.toString()),
        _storage.write(key: _userNameKey, value: name),
        _storage.write(key: _userEmailKey, value: email),
        _storage.write(key: _userRoleKey, value: role),
        _storage.write(key: _lastLoginKey, value: DateTime.now().toIso8601String()),
      ]);
    } catch (e) {
      debugPrint('Error saving user info: $e');
      rethrow;
    }
  }

  /// Get user ID
  Future<int?> getUserId() async {
    try {
      final id = await _storage.read(key: _userIdKey);
      return id != null ? int.tryParse(id) : null;
    } catch (e) {
      debugPrint('Error reading user ID: $e');
      return null;
    }
  }

  /// Get user name
  Future<String?> getUserName() async {
    try {
      return await _storage.read(key: _userNameKey);
    } catch (e) {
      debugPrint('Error reading user name: $e');
      return null;
    }
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _userEmailKey);
    } catch (e) {
      debugPrint('Error reading user email: $e');
      return null;
    }
  }

  /// Get user role
  Future<String?> getUserRole() async {
    try {
      return await _storage.read(key: _userRoleKey);
    } catch (e) {
      debugPrint('Error reading user role: $e');
      return null;
    }
  }

  /// Get last login date
  Future<DateTime?> getLastLogin() async {
    try {
      final lastLogin = await _storage.read(key: _lastLoginKey);
      return lastLogin != null ? DateTime.parse(lastLogin) : null;
    } catch (e) {
      debugPrint('Error reading last login: $e');
      return null;
    }
  }

  /// Get complete user info as a map
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final userId = await getUserId();
      final userName = await getUserName();
      final userEmail = await getUserEmail();
      final userRole = await getUserRole();

      if (userId == null || userName == null || userEmail == null || userRole == null) {
        return null;
      }

      return {
        'id': userId,
        'name': userName,
        'email': userEmail,
        'role': userRole,
      };
    } catch (e) {
      debugPrint('Error getting user info: $e');
      return null;
    }
  }

  /// Check if user is logged in (with token validation)
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return false;

      // Check if token is expired
      final isExpired = await isTokenExpired();
      return !isExpired;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // Settings Methods (Strongly Typed)
  // --------------------------------------------------------------------------

  /// Save notification preference
  Future<void> setNotificationsEnabled(bool enabled) async {
    await setBool(_notificationsEnabledKey, enabled);
  }

  /// Get notification preference
  Future<bool> getNotificationsEnabled() async {
    return await getBool(_notificationsEnabledKey) ?? true; // Default: enabled
  }

  /// Save biometric preference
  Future<void> setBiometricsEnabled(bool enabled) async {
    await setBool(_biometricsEnabledKey, enabled);
  }

  /// Get biometric preference
  Future<bool> getBiometricsEnabled() async {
    return await getBool(_biometricsEnabledKey) ?? false; // Default: disabled
  }

  /// Save locale (language)
  Future<void> setLocale(String localeCode) async {
    await setString(_localeKey, localeCode);
  }

  /// Get locale (language)
  Future<String?> getLocale() async {
    return await getString(_localeKey);
  }

  /// Save theme preference
  Future<void> setTheme(String theme) async {
    await setString(_themeKey, theme);
  }

  /// Get theme preference
  Future<String?> getTheme() async {
    return await getString(_themeKey);
  }

  // --------------------------------------------------------------------------
  // Cleanup Methods
  // --------------------------------------------------------------------------

  /// Clear only authentication data (logout)
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _tokenExpiryKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _userNameKey),
        _storage.delete(key: _userEmailKey),
        _storage.delete(key: _userRoleKey),
        _storage.delete(key: _lastLoginKey),
      ]);
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
      rethrow;
    }
  }

  /// Clear all stored data (complete reset)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      rethrow;
    }
  }

  /// Clear all data except settings (useful for logout)
  Future<void> clearAllExceptSettings() async {
    try {
      // Save current settings
      final notifications = await getNotificationsEnabled();
      final biometrics = await getBiometricsEnabled();
      final locale = await getLocale();
      final theme = await getTheme();

      // Clear everything
      await clearAll();

      // Restore settings
      await setNotificationsEnabled(notifications);
      await setBiometricsEnabled(biometrics);
      if (locale != null) await setLocale(locale);
      if (theme != null) await setTheme(theme);
    } catch (e) {
      debugPrint('Error clearing data except settings: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // Debug & Development Methods
  // --------------------------------------------------------------------------

  /// Get all stored keys (for debugging)
  Future<Map<String, String>> getAllData() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      debugPrint('Error reading all data: $e');
      return {};
    }
  }

  /// Print all stored data (for debugging)
  Future<void> printAllData() async {
    if (kDebugMode) {
      final allData = await getAllData();
      debugPrint('=== Storage Contents ===');
      allData.forEach((key, value) {
        // Mask sensitive data
        if (key.contains('token') || key.contains('password')) {
          debugPrint('$key: ***HIDDEN***');
        } else {
          debugPrint('$key: $value');
        }
      });
      debugPrint('========================');
    }
  }
}
