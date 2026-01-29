import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'beacon_scanner_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  final String courseName;
  final bool isLecturer;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    this.isLecturer = false,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  late TabController _tabController;

  Map<String, dynamic>? _courseDetails;
  List<dynamic> _attendanceHistory = [];
  bool _isLoadingDetails = true;
  bool _isLoadingHistory = true;
  bool _hasActiveSession = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourseDetails();
    _loadAttendanceHistory();
    if (!widget.isLecturer) {
      _checkActiveSession();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoadingDetails = true;
      _errorMessage = null;
    });

    final result = await _apiService.getCourseDetails(widget.courseId);

    if (mounted) {
      setState(() {
        _isLoadingDetails = false;
        if (result['success']) {
          _courseDetails = result['course'];
          // Normalize course data to handle different key formats
          if (_courseDetails != null) {
            // Ensure we have course_name for backward compatibility
            _courseDetails!['course_name'] = _courseDetails!['course_name'] ??
                _courseDetails!['title'] ??
                widget.courseName;
            _courseDetails!['course_code'] = _courseDetails!['course_code'] ??
                _courseDetails!['code'] ??
                'N/A';
            // Handle lecturer info
            if (_courseDetails!['lecturer'] != null) {
              _courseDetails!['lecturer_name'] = _courseDetails!['lecturer']['name'];
            } else {
              _courseDetails!['lecturer_name'] = _courseDetails!['lecturer_name'] ?? 'Unknown';
            }
            // Handle enrollment count
            _courseDetails!['enrollment_count'] = _courseDetails!['enrollment_count'] ??
                _courseDetails!['enrolled_count'] ??
                0;
          }
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  Future<void> _loadAttendanceHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    final result = await _apiService.getAttendanceHistory(widget.courseId);

    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
        if (result['success']) {
          _attendanceHistory = result['attendance'] ?? [];
        }
      });
    }
  }

  Future<void> _checkActiveSession() async {
    try {
      print('🔍 Checking active session for course ${widget.courseId}...');
      final result = await _apiService.checkActiveSession(widget.courseId);
      print('📡 Active session result: $result');

      if (mounted) {
        setState(() {
          _hasActiveSession = result['has_active_session'] ?? false;
          print('✅ Active session status: $_hasActiveSession');
        });
      }
    } catch (e) {
      print('❌ Error checking active session: $e');
      // Don't block the user - let them try to scan anyway
      if (mounted) {
        setState(() {
          _hasActiveSession = false;
        });
      }
    }
  }

  Future<void> _navigateToScanner() async {
    // Always allow navigation - let the scanner screen handle session validation
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BeaconScannerScreen(
          courseId: widget.courseId,
          courseName: widget.courseName,
        ),
      ),
    );

    // If attendance was marked, reload history
    if (result == true) {
      _loadAttendanceHistory();
      _checkActiveSession();
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadCourseDetails(),
      _loadAttendanceHistory(),
      if (!widget.isLecturer) _checkActiveSession(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.info),
              text: widget.isLecturer ? 'Course Info' : 'Details',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: widget.isLecturer ? 'Attendance' : 'My History',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: !widget.isLecturer && _hasActiveSession
          ? FloatingActionButton.extended(
        onPressed: _navigateToScanner,
        icon: const Icon(Icons.bluetooth_searching),
        label: const Text('Scan Beacon'),
        backgroundColor: Colors.green,
      )
          : null,
    );
  }

  Widget _buildDetailsTab() {
    if (_isLoadingDetails) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading course details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCourseDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_courseDetails == null) {
      return const Center(
        child: Text('No course details available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student: Session Status Card
            if (!widget.isLecturer) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _hasActiveSession
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasActiveSession
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasActiveSession ? Icons.check_circle : Icons.cancel,
                      color: _hasActiveSession ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasActiveSession
                                ? 'Active Session'
                                : 'No Active Session',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _hasActiveSession
                                  ? Colors.green.shade900
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasActiveSession
                                ? 'You can mark attendance now'
                                : 'Wait for lecturer to start session',
                            style: TextStyle(
                              fontSize: 14,
                              color: _hasActiveSession
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Lecturer: Statistics Cards
            if (widget.isLecturer) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.people,
                      label: 'Enrolled',
                      value: '${_courseDetails!['enrollment_count'] ?? 0}',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.event,
                      label: 'Sessions',
                      value: '${_attendanceHistory.length}',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Course Information
            _buildSectionTitle('Course Information'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(
                Icons.book,
                'Course Name',
                _courseDetails!['course_name'] ?? widget.courseName,
              ),
              _buildInfoRow(
                Icons.code,
                'Course Code',
                _courseDetails!['course_code'] ?? 'N/A',
              ),
              _buildInfoRow(
                Icons.person,
                'Instructor',
                _courseDetails!['lecturer_name'] ?? 'Unknown',
              ),
              if (!widget.isLecturer)
                _buildInfoRow(
                  Icons.group,
                  'Enrolled Students',
                  '${_courseDetails!['enrollment_count'] ?? 0}',
                ),
            ]),

            const SizedBox(height: 24),

            // Quick Actions (Student Only) - FIXED VERSION
            if (!widget.isLecturer) ...[
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.bluetooth_searching,
                      label: 'Scan Beacon',
                      // FIXED: Always show green/blue color, always enabled
                      color: Colors.blue,  // Changed from conditional to always blue
                      onTap: _navigateToScanner,  // Changed from conditional to always enabled
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.history,
                      label: 'View History',
                      color: Colors.purple,
                      onTap: () {
                        _tabController.animateTo(1);
                      },
                    ),
                  ),
                ],
              ),
            ],

            // Lecturer: Course Description
            if (widget.isLecturer &&
                _courseDetails!['description'] != null &&
                _courseDetails!['description'].toString().isNotEmpty) ...[
              _buildSectionTitle('Description'),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _courseDetails!['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_attendanceHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.isLecturer
                  ? 'No Sessions Yet'
                  : 'No Attendance Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isLecturer
                  ? 'Start a session to track attendance'
                  : 'You haven\'t marked attendance yet',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAttendanceHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _attendanceHistory.length,
        itemBuilder: (context, index) {
          final record = _attendanceHistory[index];
          return widget.isLecturer
              ? _buildLecturerAttendanceCard(record, index)
              : _buildStudentAttendanceCard(record, index);
        },
      ),
    );
  }

  // Lecturer Statistics Card
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Button always looks enabled and clickable
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            // Add subtle gradient to make it look more attractive
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Student Attendance Card
  Widget _buildStudentAttendanceCard(Map<String, dynamic> record, int index) {
    final sessionId = record['session_id'] ?? 0;
    final scanTime = record['scan_time'] ?? record['timestamp'] ?? 'Unknown';

    // Parse and format the date
    String formattedDate = 'Unknown';
    String formattedTime = 'Unknown';

    try {
      final dateTime = DateTime.parse(scanTime);
      formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      formattedTime =
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      formattedDate = scanTime;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session #$sessionId',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Present',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Lecturer Attendance Card (shows session info and student count)
  Widget _buildLecturerAttendanceCard(
      Map<String, dynamic> record, int index) {
    final sessionId = record['session_id'] ?? 0;
    final sessionDate = record['session_date'] ?? record['created_at'] ?? 'Unknown';
    final attendanceCount = record['attendance_count'] ?? 0;
    final totalEnrolled = _courseDetails?['enrollment_count'] ?? 0;

    // Parse and format the date
    String formattedDate = 'Unknown';
    String formattedTime = 'Unknown';

    try {
      final dateTime = DateTime.parse(sessionDate);
      formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      formattedTime =
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      formattedDate = sessionDate;
    }

    // Calculate attendance percentage
    final percentage = totalEnrolled > 0
        ? ((attendanceCount / totalEnrolled) * 100).toStringAsFixed(0)
        : '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.event,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session #$sessionId',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$attendanceCount / $totalEnrolled',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getAttendanceColor(double.parse(percentage))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getAttendanceColor(double.parse(percentage)),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: _getAttendanceColor(double.parse(percentage)),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
