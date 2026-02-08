// Course Detail Screen - Modernized

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/ble_service.dart';
import '../../services/permission_service.dart';


class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;
  final bool isLecturer;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.isLecturer = false,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _bleService = BLEService();
  final _permissionService = PermissionService(); 

  Map<String, dynamic>? _courseData;
  bool _isLoading = true;

  // Broadcasting State
  bool _isBroadcasting = false;
  Map<String, dynamic>? _beaconData;
  int? _sessionId;

  // Animation for the "Live" indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();

    // Setup pulse animation for the broadcasting state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    if (_isBroadcasting) {
      _bleService.stopBroadcasting();
    }
    _pulseController.dispose();
    super.dispose();
  }

  // --- Logic Section (Kept exactly as your original) ---

  Future<void> _startBroadcasting() async {
    if (_beaconData == null) return;
    try {
      await _bleService.startBroadcasting(
        major: _beaconData!['major'],
        minor: _beaconData!['minor'],
      );
      print('Started broadcasting: ${_beaconData}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _stopBroadcasting() async {
    if (_sessionId == null) return;
    final result = await _apiService.endAttendanceSession(sessionId: _sessionId!);

    if (!mounted) return;

    if (result['success']) {
      await _bleService.stopBroadcasting();
      setState(() {
        _isBroadcasting = false;
        _beaconData = null;
        _sessionId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.orange),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _generateBeacon() async {
    print('🎯 Generate Beacon button pressed');
    
    // Comprehensive permission check (like student screen)
    final check = await _permissionService.performComprehensiveCheck();
    print('📋 Comprehensive check result: ${check.isReady}');
    
    // Check permissions
    if (!check.hasPermissions) {
      print('❌ Permissions not granted');
      final permanentlyDenied = await _permissionService.hasPermissionsPermanentlyDenied();
      if (permanentlyDenied) {
        _showPermissionsPermanentlyDeniedDialog();
      } else {
        _showPermissionDialog();
      }
      return;
    }
    
    // Check Bluetooth adapter
    if (!check.isBluetoothEnabled) {
      print('❌ Bluetooth is disabled');
      final enabled = await _showBluetoothEnableDialog();
      if (!enabled) return;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Check Location services
    if (!check.isLocationEnabled) {
      print('❌ Location services disabled');
      _showLocationServiceDialog();
      return;
    }
    
    // All checks passed - create session
    print('✅ All checks passed - creating session');
    
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _apiService.createAttendanceSession(courseId: widget.courseId);

    if (!mounted) return;
    Navigator.pop(context);

    if (result['success']) {
      setState(() {
        _sessionId = result['session_id'];
        _beaconData = result['beacon_data'];
        _isBroadcasting = true;
      });
      await _startBroadcasting();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Session Active'), backgroundColor: Colors.green)
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _loadCourseDetails() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getCourseDetails(widget.courseId);
    setState(() {
      if (result['success']) {
        _courseData = result['course'];
      }
      _isLoading = false;
    });
  }

    // ✅ Permission dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Icon(Icons.warning_amber_rounded, size: 48, color: colorScheme.error),
          title: const Text('Permissions Required', textAlign: TextAlign.center),
          content: const Text(
            'This app needs Bluetooth and Location permissions to broadcast beacons.\n\n'
            'Please grant the requested permissions.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                final granted = await _permissionService.requestBluetoothPermissions();
                if (granted && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Permissions granted!'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Grant Permissions'),
            ),
          ],
        );
      },
    );
  }

  // ✅ Permanently denied dialog
  void _showPermissionsPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Icon(Icons.block_rounded, size: 48, color: colorScheme.error),
          title: const Text('Permissions Denied', textAlign: TextAlign.center),
          content: const Text(
            'You have permanently denied required permissions.\n\n'
            'Please open Settings and manually enable:\n• Bluetooth\n• Location',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
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
        );
      },
    );
  }

  // ✅ Bluetooth enable dialog
  Future<bool> _showBluetoothEnableDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Try auto-enable on Android
    final enabledAutomatically = await _permissionService.promptEnableBluetooth();
    if (enabledAutomatically) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Bluetooth enabled!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
        );
      }
      return true;
    }

    // Show dialog if auto-enable failed
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Icon(Icons.bluetooth_disabled_rounded, size: 48, color: colorScheme.error),
          title: const Text('Bluetooth Disabled', textAlign: TextAlign.center),
          content: const Text(
            'Please enable Bluetooth to broadcast the beacon signal.\n\n'
            'You can enable it in Quick Settings or device settings.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // ✅ Location service dialog
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Icon(Icons.location_off_rounded, size: 48, color: colorScheme.error),
          title: const Text('Location Services Disabled', textAlign: TextAlign.center),
          content: const Text(
            'Please enable Location Services to broadcast beacons.\n\n'
            'Location is required by Android for Bluetooth operations.\n\n'
            'Tap "Open Settings" to enable it now.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _permissionService.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Helper to match Dashboard colors
  Color _getCourseColor(int id) {
    final colors = [
      Colors.blue.shade100, Colors.orange.shade100, Colors.purple.shade100,
      Colors.teal.shade100, Colors.pink.shade100, Colors.indigo.shade100,
    ];
    return colors[id % colors.length];
  }

  Color _getCourseTextColor(int id) {
    final colors = [
      Colors.blue.shade900, Colors.orange.shade900, Colors.purple.shade900,
      Colors.teal.shade900, Colors.pink.shade900, Colors.indigo.shade900,
    ];
    return colors[id % colors.length];
  }

  // --- UI Section ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine header colors based on Course ID
    final headerColor = _getCourseColor(widget.courseId);
    final headerTextColor = _getCourseTextColor(widget.courseId);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text('Course Details'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courseData == null
          ? const Center(child: Text('Failed to load course details'))
          : RefreshIndicator(
        onRefresh: _loadCourseDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Modern Header Card
              _buildCourseHeader(headerColor, headerTextColor),
              const SizedBox(height: 24),

              // 2. Broadcasting Controls (Only for Lecturer)
              if (widget.isLecturer) ...[
                _buildBroadcastingSection(),
                const SizedBox(height: 32),
              ],

              // 3. Student List Section
              _buildStudentListSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseHeader(Color bgColor, Color textColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor, // Pastel color
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.class_rounded, color: textColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _courseData!['title'],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description with better typography
                Text(
                  _courseData!['description'] ?? 'No description available.',
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),
                // Lecturer badge
                if (_courseData!['lecturer'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_rounded, size: 16, color: textColor),
                        const SizedBox(width: 6),
                        Text(
                          'Dr. ${_courseData!['lecturer']['name']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastingSection() {
    if (_isBroadcasting) {
      // ACTIVE SESSION CARD
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.2 * _pulseAnimation.value),
                  blurRadius: 20 * _pulseAnimation.value,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'SESSION LIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Broadcasting Beacon',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your device is currently acting as a beacon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Technical Data Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildTechRow('Major', '${_beaconData?['major']}'),
                      const Divider(height: 16),
                      _buildTechRow('Minor', '${_beaconData?['minor']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stop Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _stopBroadcasting,
                    icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
                    label: const Text('End Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // GENERATE BUTTON
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton.icon(
              onPressed: _generateBeacon,
              icon: const Icon(Icons.bluetooth_audio, size: 24),
              label: const Text(
                'Generate Attendance Beacon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to turn your phone into a beacon for students to scan.',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      );
    }
  }

  Widget _buildTechRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildStudentListSection(ThemeData theme) {
    final students = _courseData!['enrolled_students'] as List;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Enrolled Students',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${students.length} Total',
                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (students.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text('No students enrolled', style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final student = students[index];
              final initial = student['name'][0].toUpperCase();

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade50,
                    child: Text(
                      initial,
                      style: TextStyle(color: Colors.deepPurple.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    student['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    student['email'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
