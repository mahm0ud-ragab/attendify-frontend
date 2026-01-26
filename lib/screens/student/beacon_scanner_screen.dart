import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/beacon.dart';
import '../../services/bluetooth_service.dart';
import '../../services/permission_service.dart';
import '../../services/api_service.dart';
import '../../widgets/beacon_card.dart';
import '../../widgets/control_panel.dart';

class BeaconScannerScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const BeaconScannerScreen({
    Key? key,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  State<BeaconScannerScreen> createState() => _BeaconScannerScreenState();
}

class _BeaconScannerScreenState extends State<BeaconScannerScreen> {
  final _bluetoothService = BluetoothService();
  final _permissionService = PermissionService();
  final _apiService = ApiService();

  int get courseId => widget.courseId;
  String get courseTitle => widget.courseTitle;

  List<Beacon> _beacons = [];
  bool _isScanning = false;
  bool _isMarkingAttendance = false;
  bool _hasActiveSession = false;
  String _statusMessage = 'Ready to scan';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    _checkActiveSession();
    _listenToScanResults();
    _listenToScanningState();
  }

  void _checkBluetoothState() async {
    final isOn = await _bluetoothService.isBluetoothOn();
    if (!isOn && mounted) {
      setState(() {
        _statusMessage = 'Please enable Bluetooth';
        _errorMessage = 'Bluetooth is turned off';
      });
    }
  }

  Future<void> _checkActiveSession() async {
    final result = await _apiService.getActiveSessionForCourse(courseId);
    if (mounted) {
      setState(() {
        _hasActiveSession = result['has_active_session'] ?? false;
        if (!_hasActiveSession) {
          _statusMessage = 'No active session. Contact your lecturer.';
        }
      });
    }
  }

  void _listenToScanResults() {
    _bluetoothService.scanStream.listen((beacons) {
      if (mounted) {
        setState(() {
          _beacons = beacons;
        });
      }
    });
  }

  void _listenToScanningState() {
    _bluetoothService.isScanningStream.listen((isScanning) {
      if (mounted) {
        setState(() {
          _isScanning = isScanning;
          if (!isScanning && _hasActiveSession) {
            _statusMessage = _beacons.isEmpty
                ? 'No beacons found'
                : 'Found ${_beacons.length} beacon${_beacons.length > 1 ? 's' : ''}';
          }
        });
      }
    });
  }

  Future<void> _startScan() async {
    HapticFeedback.lightImpact();
    print('🚀 Start Scan button pressed');

    // Check if there's an active session first
    if (!_hasActiveSession) {
      _showNoSessionDialog();
      return;
    }

    final hasPermissions = await _permissionService.requestBluetoothPermissions();
    if (!hasPermissions) {
      print('❌ Permissions not granted');
      _showPermissionDialog();
      return;
    }

    final locationEnabled = await _permissionService.isLocationServiceEnabled();
    if (!locationEnabled) {
      _showLocationServiceDialog();
      return;
    }

    setState(() {
      _statusMessage = 'Scanning for beacons...';
      _errorMessage = null;
    });

    try {
      await _bluetoothService.startScan();
      print('✅ Scan started successfully');
    } catch (e) {
      print('❌ Scan failed: $e');
      setState(() {
        _statusMessage = 'Scan failed';
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _stopScan() async {
    HapticFeedback.mediumImpact();
    print('🛑 Stop Scan button pressed');
    await _bluetoothService.stopScan();
    setState(() {
      _statusMessage = 'Scan stopped';
    });
  }

  Future<void> _markAttendance(Beacon beacon) async {
    if (_isMarkingAttendance) return;

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(beacon);
    if (!confirmed) return;

    setState(() {
      _isMarkingAttendance = true;
    });

    HapticFeedback.mediumImpact();

    final result = await _apiService.markAttendanceWithBeacon(
      selectedCourseId: courseId,
      beaconMajor: beacon.major,
      beaconMinor: beacon.minor,
    );

    setState(() {
      _isMarkingAttendance = false;
    });

    if (result['success']) {
      _showSuccessDialog(result['message'] ?? 'Attendance marked successfully!');
      HapticFeedback.heavyImpact();
      // Stop scanning after successful marking
      await _bluetoothService.stopScan();
    } else {
      if (result['already_marked'] == true) {
        _showAlreadyMarkedDialog(result['message']);
      } else {
        _showErrorDialog(result['message'] ?? 'Failed to mark attendance');
      }
      HapticFeedback.vibrate();
    }
  }

  Future<bool> _showConfirmationDialog(Beacon beacon) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(
            Icons.qr_code_scanner,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text(
            'Mark Attendance?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mark attendance for:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      courseTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Beacon: ${beacon.major}/${beacon.minor}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Signal: ${beacon.signalStrength}',
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
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: Colors.green,
          ),
          title: const Text(
            'Success!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to course list
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: colorScheme.error,
          ),
          title: const Text(
            'Error',
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAlreadyMarkedDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.info_outline_rounded,
            size: 48,
            color: Colors.blue,
          ),
          title: const Text(
            'Already Marked',
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to course list
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showNoSessionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(
            Icons.event_busy_rounded,
            size: 48,
            color: Colors.orange,
          ),
          title: const Text(
            'No Active Session',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'There is no active attendance session for this course. Please contact your lecturer.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: colorScheme.error,
          ),
          title: const Text(
            'Permissions Required',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'This app needs Bluetooth and Location permissions to scan for beacons.\n\nLocation is required by Android for BLE scanning.',
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

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(
            Icons.location_off_rounded,
            size: 48,
            color: colorScheme.error,
          ),
          title: const Text(
            'Location Services Disabled',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Please enable Location Services in your device settings.\n\nLocation is required by Android for Bluetooth beacon scanning.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _beacons.sort((a, b) => b.rssi.compareTo(a.rssi));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
        actions: [
          if (!_hasActiveSession)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.event_busy, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'No Session',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _checkActiveSession();
          if (!_isScanning && _hasActiveSession) {
            await _startScan();
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ControlPanel(
                  isScanning: _isScanning,
                  statusMessage: _statusMessage,
                  onStartScan: _startScan,
                  onStopScan: _stopScan,
                ),
              ),
            ),

            if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildErrorBanner(),
                ),
              ),

            if (!_hasActiveSession)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildWarningBanner(),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detected Beacons',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_beacons.length}',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_beacons.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isScanning
                            ? Icons.bluetooth_searching
                            : Icons.bluetooth_disabled,
                        size: 80,
                        color: _isScanning
                            ? colorScheme.primary.withOpacity(0.6)
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isScanning ? 'Scanning...' : 'No beacons detected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isScanning
                            ? 'Looking for beacons nearby'
                            : _hasActiveSession
                            ? 'Tap "Start Scan" to begin searching'
                            : 'No active session available',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (_isScanning) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor:
                            AlwaysStoppedAnimation(colorScheme.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final beacon = _beacons[index];
                      return _buildBeaconCardWithButton(beacon, index + 1);
                    },
                    childCount: _beacons.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeaconCardWithButton(Beacon beacon, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          BeaconCard(beacon: beacon, index: index),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isMarkingAttendance || !_hasActiveSession
                    ? null
                    : () => _markAttendance(beacon),
                icon: _isMarkingAttendance
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : const Icon(Icons.qr_code_scanner),
                label: Text(
                  _isMarkingAttendance
                      ? 'Marking...'
                      : 'Mark Attendance',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onErrorContainer,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'No Active Session',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your lecturer has not started an attendance session yet.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bluetoothService.stopScan();
    super.dispose();
  }
}
