import 'package:flutter/material.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/ble_service.dart';
import '../../services/permission_service.dart';
import '../../widgets/beacon_card.dart';

class BeaconScannerScreen extends StatefulWidget {
  final int courseId;
  final String courseName;

  const BeaconScannerScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<BeaconScannerScreen> createState() => _BeaconScannerScreenState();
}

class _BeaconScannerScreenState extends State<BeaconScannerScreen> {
  final ApiService _apiService = ApiService();
  final BLEService _bleService = BLEService();
  final PermissionService _permissionService = PermissionService();

  bool _isScanning = false;
  bool _isMarking = false;
  List<Beacon> _beacons = [];
  StreamSubscription<List<Beacon>>? _scanSubscription;
  String? _statusMessage;
  bool _hasActiveSession = false;
  int _scanAttempts = 0;

  // University Beacon UUID
  static const String universityUUID = '123e4567-e89b-12d3-a456-426614174000';

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _bleService.dispose();
    super.dispose();
  }

  // Check if there's an active session for this course
  Future<void> _checkActiveSession() async {
    setState(() {
      _statusMessage = 'Checking for active session...';
    });

    final result = await _apiService.checkActiveSession(widget.courseId);

    if (mounted) {
      setState(() {
        _hasActiveSession = result['has_active_session'] ?? false;
        if (_hasActiveSession) {
          _statusMessage = 'Active session found! Ready to scan.';
        } else {
          _statusMessage = 'No active session. Wait for lecturer to start.';
        }
      });
    }
  }

  Future<void> _startScanning() async {
    setState(() {
      _statusMessage = 'Checking permissions...';
      _scanAttempts++;
    });

    // Check Location Services first
    final locationEnabled = await _permissionService.isLocationServiceEnabled();
    if (!locationEnabled) {
      if (mounted) {
        _showErrorDialog(
          'Location Services Required',
          'Please enable Location services in your device settings.\n\n'
              'Location is required for Bluetooth beacon scanning on Android.',
        );
      }
      return;
    }

    // Request permissions
    final hasPermissions = await _permissionService.requestBluetoothPermissions();
    if (!hasPermissions) {
      if (mounted) {
        final diagnostics = await _permissionService.getDiagnostics();
        _showPermissionDialog(diagnostics);
      }
      return;
    }

    setState(() {
      _statusMessage = 'Initializing Bluetooth...';
    });

    // Initialize BLE
    final initialized = await _bleService.initialize();
    if (!initialized) {
      if (mounted) {
        _showErrorDialog(
          'Bluetooth Error',
          'Failed to initialize Bluetooth.\n\n'
              'Please make sure:\n'
              '• Bluetooth is turned ON\n'
              '• Location is turned ON\n'
              '• All permissions are granted',
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for beacons...';
      _beacons.clear();
    });

    try {
      // Start scanning and listen to stream
      _scanSubscription = _bleService.startScanning().listen(
            (beacons) {
          if (mounted) {
            setState(() {
              _beacons = beacons;
              if (_beacons.isEmpty) {
                _statusMessage = 'Scanning... No beacons found yet (${_scanAttempts * 5}s)';
              } else {
                _statusMessage = 'Found ${_beacons.length} beacon(s)!';
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isScanning = false;
              _statusMessage = 'Scan error: ${error.toString()}';
            });
            _showErrorDialog(
              'Scanning Error',
              'An error occurred while scanning:\n\n${error.toString()}',
            );
          }
        },
      );

      // Auto-refresh status every 5 seconds
      Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!_isScanning || !mounted) {
          timer.cancel();
          return;
        }
        if (_beacons.isEmpty) {
          setState(() {
            _scanAttempts++;
            _statusMessage = 'Still scanning... (${_scanAttempts * 5}s)';
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Error: ${e.toString()}';
        });
        _showErrorDialog(
          'Failed to Start Scanning',
          e.toString(),
        );
      }
    }
  }

  Future<void> _stopScanning() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _bleService.stopScanning();

    if (mounted) {
      setState(() {
        _isScanning = false;
        _scanAttempts = 0;
        _statusMessage = 'Scanning stopped';
      });
    }
  }

  Future<void> _markAttendance(Beacon beacon) async {
    if (_isMarking) return;

    // Check if this is the university beacon
    if (beacon.proximityUUID.toLowerCase() != universityUUID.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is not a valid university beacon'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isMarking = true;
    });

    try {
      final result = await _apiService.markAttendance(
        courseId: widget.courseId,
        major: beacon.major,
        minor: beacon.minor,
      );

      if (mounted) {
        if (result['success']) {
          // Stop scanning after successful mark
          await _stopScanning();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Attendance marked successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Go back to course details
          Navigator.pop(context, true); // true indicates attendance was marked
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to mark attendance'),
              backgroundColor: result['already_marked'] == true ? Colors.orange : Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMarking = false;
        });
      }
    }
  }

  void _showPermissionDialog(Map<String, dynamic> diagnostics) {
    final platform = diagnostics['platform'] ?? 'Unknown';
    final diagText = diagnostics.entries
        .where((e) => e.key != 'platform')
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bluetooth and Location permissions are required for beacon scanning.',
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
          ElevatedButton(
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
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _isUniversityBeacon(Beacon beacon) {
    return beacon.proximityUUID.toLowerCase() == universityUUID.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        centerTitle: true,
        actions: [
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () async {
                final status = await _bleService.getStatus();
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Scanner Status'),
                      content: Text(status.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _hasActiveSession ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasActiveSession ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _hasActiveSession ? Icons.check_circle : Icons.info,
                  color: _hasActiveSession ? Colors.green : Colors.orange,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _statusMessage ?? 'Checking session status...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _hasActiveSession ? Colors.green.shade900 : Colors.orange.shade900,
                  ),
                ),
                if (!_hasActiveSession && !_isScanning) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _checkActiveSession,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check Again'),
                  ),
                ],
                if (_isScanning) ...[
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),

          // Scan Button
          if (_hasActiveSession)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? _stopScanning : _startScanning,
                  icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
                  label: Text(
                    _isScanning ? 'Stop Scanning' : 'Start Scanning',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScanning ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Beacons List
          Expanded(
            child: _beacons.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isScanning
                        ? 'Searching for beacons...\n\nMake sure:\n• You are near the lecturer\n• Bluetooth is ON\n• Location is ON'
                        : 'Press "Start Scanning" to begin',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  if (_isScanning && _scanAttempts > 2) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _stopScanning();
                        await Future.delayed(const Duration(milliseconds: 500));
                        await _startScanning();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Restart Scan'),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _beacons.length,
              itemBuilder: (context, index) {
                final beacon = _beacons[index];
                final isUniversityBeacon = _isUniversityBeacon(beacon);

                return BeaconCard(
                  beacon: beacon,
                  index: index + 1,
                  isUniversityBeacon: isUniversityBeacon,
                  isMarking: _isMarking,
                  onMarkAttendance: isUniversityBeacon
                      ? () => _markAttendance(beacon)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
