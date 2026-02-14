// Lecturer Dashboard Screen - Royal Purple Theme

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../student/course_detail_screen.dart';
import '../common/settings_screen.dart';
import 'qr_generator_screen.dart';
import 'attendance_stats_screen.dart';
import '../../services/permission_service.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _permissionService = PermissionService();

  String _userName = '';
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // ✅ ADD THIS NEW METHOD
  Future<void> _initializeApp() async {
    // Request permissions first (including BLUETOOTH_ADVERTISE for broadcasting)
    print('🔐 Requesting Bluetooth permissions for Lecturer...');
    final permissionsGranted = await _permissionService.requestBluetoothPermissions();

    if (!permissionsGranted) {
      print('⚠️ Some permissions were denied');
      // Optionally show a warning dialog
      if (mounted) {
        _showPermissionWarning();
      }
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


  // Warm & Royal color palette for lecturer courses
  Color _getCourseColor(int id) {
    final colors = [
      Colors.orange.shade100,      // Warmth
      Colors.purple.shade100,      // Theme match
      Colors.pink.shade100,        // Vibrant contrast
      Colors.indigo.shade100,      // Deep tone
      Colors.teal.shade100,        // Cool accent
      Colors.deepOrange.shade100,  // Extra warmth
    ];
    return colors[id % colors.length];
  }

  Color _getCourseTextColor(int id) {
    final colors = [
      Colors.orange.shade900,
      Colors.purple.shade900,
      Colors.pink.shade900,
      Colors.indigo.shade900,
      Colors.teal.shade900,
      Colors.deepOrange.shade900,
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
          // Layer 1: Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.shade900,
                  Colors.deepPurple.shade800,
                  Colors.purple.shade700,
                ],
              ),
            ),
          ),

          // Layer 2: Circle pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _CirclePatternPainter(),
            ),
          ),

          // Layer 3: Content
          SafeArea(
            child: Column(
              children: [
                // Custom header (replaces AppBar)
                _buildCustomHeader(textTheme),

                // Scrollable content
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
                          // Hero Welcome Card (Glassmorphic)
                          _buildGlassmorphicWelcomeCard(theme, textTheme),
                          const SizedBox(height: 32),

                          // Courses Section (White Glass Card)
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
            'Lecturer Dashboard',
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
                    builder: (context) => const SettingsScreen(isLecturer: true),
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
            'Dr. $_userName',
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.deepPurple.shade900,
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
              color: Colors.deepPurple.shade50,
              border: Border.all(
                color: Colors.deepPurple.shade300,
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
                  color: Colors.deepPurple.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Lecturer',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.deepPurple.shade700,
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

  // Courses Glass Card Container
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
            color: Colors.deepPurple.shade900,
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

  // Enhanced Empty State with Royal Purple
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            // Large Icon with Opacity
            Icon(
              Icons.auto_stories_rounded,
              size: 140,
              color: Colors.deepPurple.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 24),
            Text(
              'No courses assigned yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your courses will appear here once assigned',
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
                builder: (context) => CourseDetailScreen(
                  courseId: course['id'],
                  courseTitle: course['title'],
                  isLecturer: true,
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
                    // Color-Coded Icon (Warm & Royal palette)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: courseColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.class_rounded,
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

                // ── Student count row ──
                Row(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${course['enrolled_count'] ?? 0} students',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Action chips row ──
                Row(
                  children: [
                    // Left half: Stats + QR (stacked or side-by-side)
                    Expanded(
                      child: Row(
                        children: [
                          // Stats chip
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AttendanceStatsScreen(
                                      courseId: course['id'],
                                      courseTitle: course['title'] ?? 'Course',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade100,
                                  border: Border.all(
                                    color: Colors.deepPurple.shade300,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bar_chart_rounded,
                                      size: 15,
                                      color: Colors.deepPurple.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    // Text(
                                    //   'Stats',
                                    //   style: textTheme.labelMedium?.copyWith(
                                    //     color: Colors.deepPurple.shade700,
                                    //     fontWeight: FontWeight.w600,
                                    //     fontSize: 12,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // QR chip
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QrGeneratorScreen(
                                      courseTitle: course['title'],
                                      courseId: course['id'].toString(),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50,
                                  border: Border.all(
                                    color: Colors.deepPurple.shade200,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_rounded,
                                      size: 15,
                                      color: Colors.deepPurple.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    // Text(
                                    //   'QR',
                                    //   style: textTheme.labelMedium?.copyWith(
                                    //     color: Colors.deepPurple.shade700,
                                    //     fontWeight: FontWeight.w600,
                                    //     fontSize: 12,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right half: View Details
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: courseColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'View Details',
                          textAlign: TextAlign.center,
                          style: textTheme.labelMedium?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
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
