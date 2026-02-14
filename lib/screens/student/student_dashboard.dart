// Student Dashboard Screen - Sky Blue Theme with Full Glassmorphism

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'beacon_scanner_screen.dart';
import '../common/settings_screen.dart';
import 'qr_scanner_screen.dart';
import '../../services/permission_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _permissionService = PermissionService(); // ✅ ADD THIS

  String _userName = '';
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp(); // ✅ CHANGE THIS
  }

  // ✅ ADD THIS NEW METHOD
  Future<void> _initializeApp() async {
    // Request permissions first
    print('🔐 Requesting Bluetooth permissions...');
    final permissionsGranted = await _permissionService.requestBluetoothPermissions();

    if (!permissionsGranted) {
      print('⚠️ Some permissions were denied');
      // Optionally show a warning dialog
      if (mounted) {
        _showPermissionWarning();
      }
    }

    // Then load dashboard data
    await _loadData();
  }

  Future<void> _loadData() async {
    // Load user name
    final name = await _storageService.getUserName();
    // Load enrolled courses
    final result = await _apiService.getEnrolledCourses();

    setState(() {
      _userName = name ?? 'Student';
      if (result['success']) {
        _courses = result['courses'] ?? [];
      }
      _isLoading = false;
    });
  }


  // Helper to generate consistent colors based on Course ID - SKY BLUE PALETTE
  Color _getCourseColor(int id) {
    final colors = [
      Colors.lightBlue.shade100,
      Colors.cyan.shade100,
      Colors.blue.shade100,
      Colors.teal.shade100,
      Colors.indigo.shade100,
      Colors.blueGrey.shade100,
    ];
    return colors[id % colors.length];
  }

  Color _getCourseTextColor(int id) {
    final colors = [
      Colors.lightBlue.shade900,
      Colors.cyan.shade900,
      Colors.blue.shade900,
      Colors.teal.shade900,
      Colors.indigo.shade900,
      Colors.blueGrey.shade900,
    ];
    return colors[id % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Sky Blue Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade600,
                  Colors.lightBlue.shade500,
                ],
              ),
            ),
          ),

          // Layer 2: Circle Pattern Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _CirclePatternPainter(),
            ),
          ),

          // Layer 3: Content
          SafeArea(
            child: Column(
              children: [
                // Custom Header (replaces AppBar)
                _buildCustomHeader(textTheme),

                // Scrollable Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Glassmorphic Welcome Card
                          _buildGlassmorphicWelcomeCard(theme, textTheme),
                          const SizedBox(height: 32),

                          // Glassmorphic Courses Card
                          _buildCoursesGlassCard(theme, textTheme),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // FAB — quick-launch QR scanner from anywhere on the dashboard
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        tooltip: 'Scan Attendance',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QrScannerScreen(
                courseId: "0",
                courseTitle: "Scan Attendance",
              ),
            ),
          );
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  // Custom Header (replaces AppBar)
  Widget _buildCustomHeader(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Student Dashboard',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded),
              color: Colors.white,
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(isLecturer: false),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Glassmorphic Welcome Card
  Widget _buildGlassmorphicWelcomeCard(ThemeData theme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Text
          Text(
            'Welcome back,',
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),

          // Name
          Text(
            _userName,
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(
                color: Colors.blue.shade300,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.school_rounded,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Student',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Glassmorphic Courses Card Container
  Widget _buildCoursesGlassCard(ThemeData theme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _buildSectionHeader(textTheme),
          const SizedBox(height: 20),

          // Course List or Empty State
          _courses.isEmpty ? _buildEmptyState(theme) : _buildCourseList(),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'My Courses',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: Colors.blue.shade900,
          ),
        ),
        Text(
          '${_courses.length} ${_courses.length == 1 ? 'course' : 'courses'}',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Enhanced Empty State - SKY BLUE
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            // Large Icon with Opacity
            Icon(
              Icons.school_outlined,
              size: 140,
              color: Colors.blue.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 24),
            Text(
              'No courses enrolled yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your enrolled courses will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Course List with Enhanced Cards
  Widget _buildCourseList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        final courseId = course['id'] ?? index;
        final courseColor = _getCourseColor(courseId);
        final textColor = _getCourseTextColor(courseId);

        return _buildCourseCard(
          course: course,
          courseColor: courseColor,
          textColor: textColor,
        );
      },
    );
  }

  // Enhanced Course Card with Glassmorphism
  Widget _buildCourseCard({
    required Map<String, dynamic> course,
    required Color courseColor,
    required Color textColor,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BeaconScannerScreen(
                  courseId: course['id'],
                  courseTitle: course['title'] ?? 'Unknown Course',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Icon + Title
                Row(
                  children: [
                    // Color-Coded Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: courseColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.book_rounded,
                        color: textColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['title'] ?? 'Unknown Course',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                if (course['description'] != null &&
                    course['description'].toString().isNotEmpty) ...[
                  Text(
                    course['description'],
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],

                // Divider
                Divider(
                  color: Colors.grey[200],
                  height: 1,
                ),
                const SizedBox(height: 14),

                // Footer: Mark Attendance Badge
                Row(
                  children: [
                    Icon(
                      Icons.bluetooth_searching_rounded,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to mark attendance',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    // Scan Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: courseColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Scan',
                            style: textTheme.labelMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Circle Pattern Background
class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.2),
      60,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.8),
      45,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 1.05, size.height * 0.85),
      80,
      paint,
    );

    // Draw curved wave-like path
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.4);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.4 + math.sin((i / size.width) * 2 * math.pi) * 20,
      );
    }

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
