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

  // ============================================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================================

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
          'confirm_password': password, // Backend requires this
          'name': name,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Registration successful - backend returns token immediately
        final token = data['access_token'];
        final user = User.fromJson(data['user']);

        // Save token and user info
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
        // Registration failed
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
        // Login successful
        final token = data['access_token'];
        final user = User.fromJson(data['user']);

        // Save token and user info
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
        // Login failed
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

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': User.fromJson(data),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearAll();
  }

  // ============================================================================
  // COURSE ENDPOINTS
  // ============================================================================

  // Get enrolled courses for student
  Future<Map<String, dynamic>> getEnrolledCourses() async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/courses/enrolled'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'courses': data['courses'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch courses',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get courses taught by lecturer
  Future<Map<String, dynamic>> getLecturerCourses() async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/courses/teaching'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'courses': data['courses'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch courses',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get course details
  Future<Map<String, dynamic>> getCourseDetails(int courseId) async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/courses/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'course': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch course details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ============================================================================
  // SESSION ENDPOINTS (with /api prefix)
  // ============================================================================

  // Start attendance session (for lecturers)
  // POST /api/sessions/start
  Future<Map<String, dynamic>> startAttendanceSession({
    required int courseId,
  }) async {
    try {
      final token = await _storage.getToken();
      final userId = await _storage.getUserId();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      print('🚀 Starting session for course $courseId');

      final requestBody = {
        'course_id': courseId,
      };

      // Add user_id if available
      if (userId != null) {
        requestBody['user_id'] = userId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/sessions/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 Start session response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'session_id': data['session_id'],
          'beacon_config': data['beacon_config'] ?? data['beacon_data'],
          'message': data['message'] ?? 'Session started successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Failed to start session',
        };
      }
    } catch (e) {
      print('❌ Error starting session: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // End attendance session (for lecturers)
  // POST /api/sessions/end
  Future<Map<String, dynamic>> endAttendanceSession({
    required int sessionId,
  }) async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      print('🛑 Ending session $sessionId');

      final response = await http.post(
        Uri.parse('$baseUrl/api/sessions/end'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      print('📡 End session response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Session ended successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Failed to end session',
        };
      }
    } catch (e) {
      print('❌ Error ending session: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ============================================================================
  // ATTENDANCE ENDPOINTS (WITHOUT /api prefix) - FIXED!
  // ============================================================================

  // Check if there's an active session for a course (for students)
  // GET /attendance/active/<course_id>
  Future<Map<String, dynamic>> checkActiveSession(int courseId) async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      print('🔍 Checking active session: /attendance/active/$courseId');

      final response = await http.get(
        Uri.parse('$baseUrl/attendance/active/$courseId'), // FIXED: No /api prefix
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Response status: ${response.statusCode}');

      // FIXED: Check status code BEFORE attempting to decode JSON
      if (response.statusCode == 200) {
        print('📡 Response body: ${response.body}');
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'has_active_session': true,
          'session': data,
        };
      }

      if (response.statusCode == 404) {
        // FIXED: Return structured response without trying to parse HTML 404 page
        print('ℹ️  No active session found (404)');
        return {
          'success': true,
          'has_active_session': false,
        };
      }

      // Any other unexpected status
      print('⚠️  Unexpected response: ${response.statusCode}');
      return {
        'success': false,
        'message': 'Unexpected server response (${response.statusCode})',
      };
    } catch (e) {
      print('❌ Error checking active session: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Mark attendance with beacon data (for students)
  // POST /attendance/mark
  Future<Map<String, dynamic>> markAttendance({
    required int courseId,
    required int major,
    required int minor,
  }) async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      print('📍 Marking attendance: /attendance/mark');
      print('   Course ID: $courseId, Major: $major, Minor: $minor');

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/mark'), // FIXED: No /api prefix
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'selected_course_id': courseId,
          'scanned_data': {
            'major': major,
            'minor': minor,
          },
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      // FIXED: Check status code BEFORE attempting to decode JSON
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Attendance marked successfully',
          'session_id': data['data']?['session_id'],
          'student_id': data['data']?['student_id'],
        };
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'already_marked') {
          return {
            'success': false,
            'already_marked': true,
            'message': data['message'] ?? 'Attendance already recorded',
          };
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Attendance marked successfully',
        };
      } else if (response.statusCode == 404) {
        // FIXED: Don't try to parse HTML 404 page as JSON
        return {
          'success': false,
          'message': 'No active session found for this course',
        };
      } else {
        // Try to parse error message if it's JSON, otherwise use generic message
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['error'] ?? data['message'] ?? 'Failed to mark attendance',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Failed to mark attendance (Status: ${response.statusCode})',
          };
        }
      }
    } catch (e) {
      print('❌ Error marking attendance: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get attendance history for a course (for students)
  Future<Map<String, dynamic>> getAttendanceHistory(int courseId) async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/attendance/history/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'attendance': data['attendance'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch attendance history',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ============================================================================
  // LEGACY/DEPRECATED METHODS (kept for backward compatibility)
  // ============================================================================

  // Alias for startAttendanceSession
  Future<Map<String, dynamic>> createAttendanceSession({
    required int courseId,
  }) async {
    return startAttendanceSession(courseId: courseId);
  }

  // Get active session for a course (for lecturers) - uses auth route
  Future<Map<String, dynamic>> getActiveSession(int courseId) async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/attendance/active/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'session': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'No active session',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
