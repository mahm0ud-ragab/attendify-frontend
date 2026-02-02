// This service handles all API calls to the backend

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'storage_service.dart';

class ApiService {
  // IMPORTANT: Replace this with your actual backend URL
  // For Real Android/iOS Device: 'http://YOUR_COMPUTER_IP:5000'
  // For Android Emulator: 'http://10.0.2.2:5000'
  // For iOS Simulator: 'http://localhost:5000'
  // For Windows Desktop or Chrome: 'http://localhost:5000'

  // TODO: Replace with your computer's IP address
  static const String baseUrl = 'http://192.168.1.5:5000';

  final StorageService _storage = StorageService();

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'confirm_password': password,
          'name': name,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final token = data['access_token'];
        final user = User.fromJson(data['user']);

        await _storage.saveToken(token);
        await _storage.saveUserInfo(
          userId: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
        );

        return {
          'success': true,
          'user': user,
          'message': data['message'] ?? 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['errors']?.toString() ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['access_token'];
        final user = User.fromJson(data['user']);

        await _storage.saveToken(token);
        await _storage.saveUserInfo(
          userId: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
        );

        return {
          'success': true,
          'user': user,
          'message': 'Login successful',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get current user info
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'user': User.fromJson(data)};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch user'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get enrolled courses for student
  Future<Map<String, dynamic>> getEnrolledCourses() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      final response = await http.get(
        Uri.parse('$baseUrl/auth/courses/enrolled'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'courses': data['courses']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch courses'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get courses taught by lecturer
  Future<Map<String, dynamic>> getLecturerCourses() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      final response = await http.get(
        Uri.parse('$baseUrl/auth/courses/teaching'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'courses': data['courses']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch courses'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get course details
  Future<Map<String, dynamic>> getCourseDetails(int courseId) async {
    try {
      final token = await _storage.getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      final response = await http.get(
        Uri.parse('$baseUrl/auth/courses/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'course': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch course details'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ------------------------------------------------------------------
  // ✅ FIXED: Create Attendance Session
  // Updated key from 'beacon_data' to 'beacon_config' to match Backend
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>> createAttendanceSession({required int courseId}) async {
    try {
      final token = await _storage.getToken();
      final userId = await _storage.getUserId();
      if (token == null || userId == null) return {'success': false, 'message': 'Not authenticated'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/sessions/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'course_id': courseId,
          'user_id': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'session_id': data['session_id'],

          // 🔥 THIS WAS THE FIX:
          'beacon_data': data['beacon_config'],

          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to create session',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ---------------------------------------------------------
  // ✅ UPDATED: Mark Attendance
  // Returns bool and accepts named parameters
  // ---------------------------------------------------------
  // ---------------------------------------------------------
  // ✅ UPDATED: Mark Attendance
  // Now returns the SERVER MESSAGE so you can see why it failed
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> markAttendance({
    required int courseId,
    required String beaconUuid,
    required int beaconMajor,
    required int beaconMinor,
    required int rssi,
    required double distance,
  }) async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        return {'success': false, 'message': 'Not authenticated. Please login again.'};
      }

      final body = {
        'selected_course_id': courseId,
        'scanned_data': {
          'uuid': beaconUuid,
          'major': beaconMajor,
          'minor': beaconMinor,
          'rssi': rssi,
        },
      };

      print("📤 Sending to Backend: $body");

      final response = await http.post(
        Uri.parse('$baseUrl/api/attendance/mark'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print("📥 Backend Response: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Attendance marked!'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Server Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print("❌ Network Error: $e");
      return {
        'success': false,
        'message': 'Connection failed. Check IP Address!'
      };
    }
  }
  // Get active session
  Future<Map<String, dynamic>> getActiveSession(int courseId) async {
    try {
      final token = await _storage.getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      final response = await http.get(
        Uri.parse('$baseUrl/api/attendance/active/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'session': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'No active session'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // End session
  Future<Map<String, dynamic>> endAttendanceSession({required int sessionId}) async {
    try {
      final token = await _storage.getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/sessions/end'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'session_id': sessionId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Session ended successfully'};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to end session'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}
