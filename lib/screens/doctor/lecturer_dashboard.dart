// Lecturer Dashboard Screen with Beacon Broadcasting (flutter_beacon)

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/ble_service.dart';
import '../../services/permission_service.dart';
import '../auth/login_screen.dart';
import '../student/course_detail_screen.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _bleService = BLEService();
  final _permissionService = PermissionService();

  String _userName = '';
  List<dynamic> _courses = [];
  bool _isLoading = true;

  // Active session tracking
  int? _activeSessionId;
  int? _activeCourseId;
  Map<String, dynamic>? _activeBeaconData;
  bool _isBroadcasting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load user name
    final name = await _storageService.getUserName();

    // Load teaching courses
    final result = await _apiService.getLecturerCourses();

    setState(() {
      _userName = name ?? 'Lecturer';
      if (result['success']) {
        _courses = result['courses'] ?? [];
      }
      _isLoading = false;
    });
  }

  // Start attendance session with beacon broadcasting
  Future<void> _startAttendanceSession(int courseId, String courseTitle) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Check Location Services first
      final locationEnabled = await _permissionService.isLocationServiceEnabled();
      if (!locationEnabled) {
        Navigator.pop(context); // Close loading
        _showLocationServicesDialog();
        return;
      }

      // Check permissions with PermissionService
      final hasPermissions = await _permissionService.requestBluetoothPermissions();
      if (!hasPermissions) {
        Navigator.pop(context); // Close loading

        // Get diagnostics
        final diagnostics = await _permissionService.getDiagnostics();
        _showDetailedPermissionDialog(diagnostics);
        return;
      }

      // Initialize BLE
      final initialized = await _bleService.initialize();
      if (!initialized) {
        Navigator.pop(context);
        _showErrorDialog(
            'Bluetooth Error',
            'Please turn on Bluetooth and try again.\n\n'
                'Make sure:\n'
                '• Bluetooth is ON\n'
                '• Location is ON\n'
                '• All permissions are granted'
        );
        return;
      }

      // Create session on backend
      final sessionResult = await _apiService.startAttendanceSession(
        courseId: courseId,
      );

      Navigator.pop(context); // Close loading

      if (!sessionResult['success']) {
        _showErrorDialog(
          'Session Error',
          sessionResult['message'] ?? 'Failed to create session',
        );
        return;
      }

      // Get beacon data from backend
      final sessionId = sessionResult['session_id'];
      final beaconData = sessionResult['beacon_config'];

      int major;
      int minor;

      // Check if backend provided beacon data
      if (beaconData != null &&
          beaconData['major'] != null &&
          beaconData['minor'] != null) {
        // Use backend data
        major = beaconData['major'] as int;
        minor = beaconData['minor'] as int;
      } else {
        // Fallback: Generate from course and session IDs
        major = courseId;
        minor = sessionId;

        // Show warning to user
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Using fallback beacon data'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Start broadcasting
      try {
        await _bleService.startBroadcasting(
          major: major,
          minor: minor,
        );

        // Update state
        setState(() {
          _activeSessionId = sessionId;
          _activeCourseId = courseId;
          _activeBeaconData = {'major': major, 'minor': minor};
          _isBroadcasting = true;
        });

        // Show success dialog
        _showSessionActiveDialog(courseTitle, major, minor);
      } catch (e) {
        final errorMessage = e.toString();

        if (errorMessage.contains('not supported')) {
          _showErrorDialog(
              'Broadcasting Not Supported',
              'Your device does not support beacon broadcasting.\n\n'
                  'This is a hardware limitation. You can:\n'
                  '• Use a different device\n'
                  '• Use QR Code alternative (coming soon)'
          );
        } else {
          _showErrorDialog(
              'Broadcasting Error',
              'Failed to start beacon broadcasting:\n\n$errorMessage\n\n'
                  'Please try:\n'
                  '• Restart Bluetooth\n'
                  '• Restart the app\n'
                  '• Check permissions in Settings'
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading if open
      _showErrorDialog('Unexpected Error', e.toString());
    }
  }

  // End attendance session
  Future<void> _endAttendanceSession() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text(
          'Are you sure you want to end the attendance session?\n\n'
              'Students will no longer be able to mark attendance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (shouldEnd != true) return;

    try {
      // Stop broadcasting
      await _bleService.stopBroadcasting();

      // End session on backend
      if (_activeSessionId != null) {
        await _apiService.endAttendanceSession(
          sessionId: _activeSessionId!,
        );
      }

      setState(() {
        _activeSessionId = null;
        _activeCourseId = null;
        _activeBeaconData = null;
        _isBroadcasting = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Session ended successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog('Error', 'Error ending session: ${e.toString()}');
    }
  }

  void _showSessionActiveDialog(String courseTitle, int major, int minor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 60,
        ),
        title: const Text(
          'Session Active',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              courseTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.wifi_tethering,
                    color: Colors.green,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '📡 Broadcasting Beacon',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Major: $major\nMinor: $minor',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Students can now scan and mark attendance',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(
          Icons.location_off,
          size: 48,
          color: Colors.red,
        ),
        title: const Text(
          'Location Services Disabled',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Location services must be enabled for Bluetooth beacon broadcasting to work.\n\n'
              'Please enable Location in your device settings.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _permissionService.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showDetailedPermissionDialog(Map<String, dynamic> diagnostics) {
    final platform = diagnostics['platform'] ?? 'Unknown';
    final diagText = diagnostics.entries
        .where((e) => e.key != 'platform')
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: Colors.orange,
        ),
        title: const Text(
          'Permissions Required',
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The app needs the following permissions to broadcast beacon signals:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform: $platform',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      diagText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _permissionService.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(
          Icons.error_outline,
          size: 48,
          color: Colors.red,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Check if there's an active session
    if (_isBroadcasting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please end the active session before logging out'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _apiService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple,
                        Colors.deepPurple.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Dr. $_userName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Lecturer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Active Session Banner
              if (_isBroadcasting && _activeBeaconData != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.wifi_tethering,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📡 Active Session',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Broadcasting beacon signals',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: _endAttendanceSession,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('End'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Teaching Courses Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Courses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_courses.length} courses',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Course List
              _courses.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.subject_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No courses assigned yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  final courseId = course['id'] as int;
                  final isActiveCourse = courseId == _activeCourseId;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isActiveCourse ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isActiveCourse
                          ? const BorderSide(
                        color: Colors.green,
                        width: 2,
                      )
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isActiveCourse
                              ? Colors.green.withOpacity(0.2)
                              : Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isActiveCourse
                              ? Icons.wifi_tethering
                              : Icons.class_,
                          color: isActiveCourse
                              ? Colors.green
                              : Colors.deepPurple,
                        ),
                      ),
                      title: Text(
                        course['title'] ?? 'Unknown Course',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              course['description'] ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (isActiveCourse)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '● LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Text(
                                '${course['enrolled_count'] ?? 0} students',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      trailing: isActiveCourse
                          ? null
                          : FilledButton.icon(
                        onPressed: _isBroadcasting
                            ? null
                            : () => _startAttendanceSession(
                          courseId,
                          course['title'] ?? 'Unknown',
                        ),
                        icon: const Icon(
                          Icons.play_arrow,
                          size: 16,
                        ),
                        label: const Text('Start'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailScreen(
                              courseId: courseId,
                              courseName: course['title'] ?? 'Unknown Course',
                              isLecturer: true,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
