// Enhanced Beacon Scanner Screen with Improved Permission Handling
// Includes app lifecycle monitoring and comprehensive pre-scan checks

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/beacon.dart';
import '../../services/api_service.dart';
import '../../services/bluetooth_service.dart';
import '../../services/ble_service.dart';
import '../../services/permission_service.dart';
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

class _BeaconScannerScreenState extends State<BeaconScannerScreen>
    with WidgetsBindingObserver {  // ✅ NEW: Add lifecycle observer
  final _bluetoothService = BluetoothService();
  final _permissionService = PermissionService();
  final _apiService = ApiService();

  int get courseId => widget.courseId;
  String get courseTitle => widget.courseTitle;

  List<Beacon> _beacons = [];
  bool _isScanning = false;
  String _statusMessage = 'Ready to scan';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // ✅ NEW: Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    _checkInitialState();
    _listenToScanResults();
    _listenToScanningState();
  }

  @override
  void dispose() {
    // ✅ NEW: Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    _bluetoothService.stopScan();
    super.dispose();
  }

  // ✅ NEW: Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // User returned to app (possibly from Settings)
      print('📱 App resumed - re-checking permissions and services');
      _recheckPermissionsAndServices();
    } else if (state == AppLifecycleState.paused) {
      // App went to background
      print('📱 App paused');
    }
  }

  // ✅ NEW: Re-check everything when user returns from settings
  Future<void> _recheckPermissionsAndServices() async {
    final result = await _permissionService.performComprehensiveCheck();
    
    if (mounted) {
      if (result.isReady) {
        // Everything is now ready!
        setState(() {
          _errorMessage = null;
          _statusMessage = 'Ready to scan';
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ All permissions and services are enabled'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Still missing something
        setState(() {
          _errorMessage = result.userMessage;
          _statusMessage = result.userMessage ?? 'Not ready';
        });
      }
    }
  }

  // ✅ IMPROVED: Initial state check
  Future<void> _checkInitialState() async {
    final result = await _permissionService.performComprehensiveCheck();
    
    if (!mounted) return;
    
    setState(() {
      if (!result.isReady) {
        _statusMessage = result.userMessage ?? 'Not ready to scan';
        _errorMessage = result.userMessage;
      } else {
        _statusMessage = 'Ready to scan';
        _errorMessage = null;
      }
    });
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
          if (!isScanning) {
            _statusMessage = _beacons.isEmpty
                ? 'No beacons found'
                : 'Found ${_beacons.length} beacon${_beacons.length > 1 ? 's' : ''}';
          }
        });
      }
    });
  }

  // ✅ IMPROVED: Comprehensive scan start with all checks
  Future<void> _startScan() async {
    HapticFeedback.lightImpact();
    print('🚀 Start Scan button pressed');

    // ✅ NEW: Perform comprehensive check
    final check = await _permissionService.performComprehensiveCheck();
    print('📋 Comprehensive check result: ${check.isReady}');

    // Step 1: Check permissions
    if (!check.hasPermissions) {
      print('❌ Permissions not granted');
      
      // Check if permanently denied
      final permanentlyDenied = await _permissionService.hasPermissionsPermanentlyDenied();
      if (permanentlyDenied) {
        _showPermissionsPermanentlyDeniedDialog();
      } else {
        _showPermissionDialog();
      }
      return;
    }

    // Step 2: Check Bluetooth adapter
    if (!check.isBluetoothEnabled) {
      print('❌ Bluetooth is disabled');
      final enabled = await _showBluetoothEnableDialog();
      if (!enabled) {
        return; // User declined or failed to enable
      }
      // Wait a moment for Bluetooth to stabilize
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Step 3: Check Location services
    if (!check.isLocationEnabled) {
      print('❌ Location services disabled');
      _showLocationServiceDialog();
      return;
    }

    // ✅ All checks passed - safe to scan!
    print('✅ All checks passed - starting scan');
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
      
      // Show error in snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start scan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _handleMarkAttendance(Beacon beacon) async {
    // Stop scanning to save battery
    await _stopScan();
    
    if (!mounted) return;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    
    final result = await _apiService.markAttendance(
      courseId: widget.courseId,
      beaconUuid: beacon.uuid,
      beaconMajor: beacon.major,
      beaconMinor: beacon.minor,
      rssi: beacon.rssi,
      distance: beacon.accuracy,
    );
    
    if (!mounted) return;
    Navigator.pop(context); // Close loading
    
    if (result['success']) {
      // Success Dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Attendance Marked!'),
          content: Text(result['message']),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Return to Dashboard
              },
              child: const Text('Done'),
            )
          ],
        ),
      );
    } else {
      // Error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ IMPROVED: Better permission dialog
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
            'This app needs Bluetooth and Location permissions to scan for beacons.\n\n'
            'Location is required by Android for BLE scanning.\n\n'
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
                // Request permissions again
                final granted = await _permissionService.requestBluetoothPermissions();
                if (granted && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Permissions granted!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _checkInitialState();
                }
              },
              child: const Text('Grant Permissions'),
            ),
          ],
        );
      },
    );
  }

  // ✅ NEW: Dialog for permanently denied permissions
  void _showPermissionsPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(
            Icons.block_rounded,
            size: 48,
            color: colorScheme.error,
          ),
          title: const Text(
            'Permissions Denied',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'You have permanently denied required permissions.\n\n'
            'Please open Settings and manually enable:\n'
            '• Bluetooth\n'
            '• Location\n\n'
            'Then return to this app.',
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

  // ✅ NEW: Bluetooth enable dialog with Android auto-enable
  Future<bool> _showBluetoothEnableDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    
    // On Android, try to enable automatically first
    final enabledAutomatically = await _permissionService.promptEnableBluetooth();
    if (enabledAutomatically) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Bluetooth enabled!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return true;
    }

    // If auto-enable failed or on iOS, show dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(
            Icons.bluetooth_disabled_rounded,
            size: 48,
            color: colorScheme.error,
          ),
          title: const Text(
            'Bluetooth Disabled',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Please enable Bluetooth to scan for beacons.\n\n'
            'You can enable it in your device settings or quick settings panel.',
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

  // ✅ IMPROVED: Location service dialog with better guidance
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
            'Please enable Location Services in your device settings.\n\n'
            'Location is required by Android for Bluetooth beacon scanning.\n\n'
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

  @override
  Widget build(BuildContext context) {
    // Sort beacons by signal strength (strongest first)
    _beacons.sort((a, b) => b.rssi.compareTo(a.rssi));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
        actions: [
          // ✅ NEW: Diagnostics button (optional - for debugging)
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Permission Status',
            onPressed: () async {
              final diagnostics = await _permissionService.getDiagnostics();
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Permission Diagnostics'),
                    content: SingleChildScrollView(
                      child: Text(diagnostics.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join('\n')),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!_isScanning) {
            await _startScan();
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Control panel
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

            // Error banner
            if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildErrorBanner(),
                ),
              ),

            // Header
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

            // Beacon list or empty state
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
                            : 'Tap "Start Scan" to begin searching',
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
                            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final beacon = _beacons[index];
                    final isUniBeacon = beacon.uuid.toLowerCase() == 
                        BLEService.beaconUUID.toLowerCase();
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: BeaconCard(
                        beacon: beacon,
                        index: index + 1,
                        isUniversityBeacon: isUniBeacon,
                        onMarkAttendance: () => _handleMarkAttendance(beacon),
                        isMarking: false,
                      ),
                    );
                  },
                  childCount: _beacons.length,
                ),
              ),
          ],
        ),
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
}
