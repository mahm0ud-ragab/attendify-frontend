import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/beacon.dart';
import '../../services/bluetooth_service.dart';
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

class _BeaconScannerScreenState extends State<BeaconScannerScreen> {
  final _bluetoothService = BluetoothService();
  final _permissionService = PermissionService();

  int get courseId => widget.courseId;
  String get courseTitle => widget.courseTitle;

  List<Beacon> _beacons = [];
  bool _isScanning = false;
  String _statusMessage = 'Ready to scan';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
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

  Future<void> _startScan() async {
    HapticFeedback.lightImpact();
    print('🚀 Start Scan button pressed');

    final hasPermissions = await _permissionService.requestBluetoothPermissions();
    if (!hasPermissions) {
      print('❌ Permissions not granted');
      _showPermissionDialog();
      return;
    }

    // Check if location services are enabled
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
    // Sort beacons by signal strength (strongest first)
    _beacons.sort((a, b) => b.rssi.compareTo(a.rssi));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
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
                      return BeaconCard(
                        beacon: _beacons[index],
                        index: index + 1,
                      );
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

  @override
  void dispose() {
    _bluetoothService.stopScan();
    super.dispose();
  }
}
