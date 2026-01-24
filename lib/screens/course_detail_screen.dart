// Course Detail Screen

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/ble_service.dart';

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

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _apiService = ApiService();
  final _bleService = BLEService();
  Map<String, dynamic>? _courseData;
  bool _isLoading = true;
  bool _isBroadcasting = false;
  Map<String, dynamic>? _beaconData;
  int? _sessionId;

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
  }

  @override
  void dispose() {
    if (_isBroadcasting) {
      _bleService.stopBroadcasting();
    }
    super.dispose();
  }

  Future<void> _startBroadcasting() async {
    if (_beaconData == null) return;

    try {
      await _bleService.startBroadcasting(
        major: _beaconData!['major'],
        minor: _beaconData!['minor'],
      );
      print('Started broadcasting: ${_beaconData}');
    } catch (e) {
      print('Broadcasting error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start broadcasting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopBroadcasting() async {
    if (_sessionId == null) return; // Safety check

    // Call API to end session
    final result = await _apiService.endAttendanceSession(sessionId: _sessionId!);

    if (!mounted) return;

    if (result['success']) {
      // Stop broadcasting locally
      await _bleService.stopBroadcasting();
      setState(() {
        _isBroadcasting = false;
        _beaconData = null;
        _sessionId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      // Show error if ending session failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _generateBeacon() async {
    print('Generate beacon tapped');

    // Check permissions
    final hasPermission = await _bleService.checkPermissions();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth and Location permissions are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if Bluetooth is enabled
    final isBluetoothOn = await _bleService.isBluetoothEnabled();
    if (!isBluetoothOn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable Bluetooth'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    print('Creating attendance session for course ${widget.courseId}');

    // Create session on backend
    final result = await _apiService.createAttendanceSession(
      courseId: widget.courseId,
    );

    print('Backend response: $result');

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (result['success']) {
      setState(() {
        _sessionId = result['session_id'];
        _beaconData = result['beacon_data'];
        _isBroadcasting = true;
      });

      print('Session created successfully: $_beaconData');

      // Start broadcasting
      await _startBroadcasting();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance session started successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print('Failed to create session: ${result['message']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.getCourseDetails(widget.courseId);

    setState(() {
      if (result['success']) {
        _courseData = result['course'];
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseTitle),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courseData == null
          ? const Center(
        child: Text('Failed to load course details'),
      )
          : RefreshIndicator(
        onRefresh: _loadCourseDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.book,
                              color: Theme.of(context).primaryColor,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _courseData!['title'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                if (_courseData!['lecturer'] != null)
                                  Text(
                                    'Dr. ${_courseData!['lecturer']['name']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _courseData!['description'] ??
                            'No description available',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Lecturer View: Generate/Stop Beacon Button
              if (widget.isLecturer) ...[
                if (_isBroadcasting) ...[
                  // Active session card
                  Card(
                    color: Colors.green.shade50,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Broadcasting Attendance Beacon',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_beaconData != null) ...[
                            Text(
                              'Major: ${_beaconData!['major']} | Minor: ${_beaconData!['minor']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'UUID: ${_beaconData!['uuid']}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _stopBroadcasting,
                              icon: const Icon(Icons.stop),
                              label: const Text('End Session'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Generate beacon button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _generateBeacon,
                      icon: const Icon(Icons.bluetooth, size: 28),
                      label: const Text(
                        'Generate Attendance Beacon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              // Enrolled Students Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Enrolled Students',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .primaryColor
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_courseData!['enrolled_count']} students',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Students List
              if (_courseData!['enrolled_students'].isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'No students enrolled yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                  _courseData!['enrolled_students'].length,
                  itemBuilder: (context, index) {
                    final student =
                    _courseData!['enrolled_students'][index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.1),
                          child: Text(
                            student['name'][0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          student['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(student['email']),
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