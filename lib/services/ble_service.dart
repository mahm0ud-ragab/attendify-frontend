// BLE Beacon Service for Broadcasting and Scanning
// Using flutter_beacon for both broadcasting and scanning

import 'dart:async';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:permission_handler/permission_handler.dart';

class BLEService {
  // University UUID from backend
  static const String beaconUUID = '123e4567-e89b-12d3-a456-426614174000';

  StreamSubscription<RangingResult>? _rangingSubscription;
  final StreamController<List<Beacon>> _beaconController =
  StreamController<List<Beacon>>.broadcast();

  bool _isBroadcasting = false;
  bool _isScanning = false;
  int? _currentMajor;
  int? _currentMinor;
  bool _isInitialized = false;

  // ============================================================================
  // PERMISSIONS
  // ============================================================================

  /// Check and request all necessary permissions
  Future<bool> checkPermissions() async {
    try {
      // Request all permissions at once
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      // Check if critical permissions are granted
      bool bluetoothGranted = statuses[Permission.bluetooth]?.isGranted ?? false;
      bool bluetoothScanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? true; // True for older Android
      bool bluetoothConnectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? true;
      bool bluetoothAdvertiseGranted = statuses[Permission.bluetoothAdvertise]?.isGranted ?? true;
      bool locationGranted = statuses[Permission.location]?.isGranted ??
          statuses[Permission.locationWhenInUse]?.isGranted ??
          false;

      // For Android 12+, need specific Bluetooth permissions
      bool hasBluetoothPermissions = bluetoothGranted &&
          (bluetoothScanGranted || bluetoothConnectGranted || bluetoothAdvertiseGranted);

      if (!hasBluetoothPermissions || !locationGranted) {
        // Check for permanently denied
        bool anyPermanentlyDenied =
        statuses.values.any((status) => status.isPermanentlyDenied);
        if (anyPermanentlyDenied) {
          await openAppSettings();
        }

        return false;
      }

      // Check Location Services are enabled
      final serviceEnabled = await Permission.location.serviceStatus.isEnabled;

      if (!serviceEnabled) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize flutter_beacon
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        return true; // Already initialized
      }

      // Initialize the beacon plugin for scanning
      await flutterBeacon.initializeScanning;

      // Initialize broadcasting (Android only)
      try {
        await flutterBeacon.initializeAndCheckScanning;
      } catch (e) {
        // Broadcasting initialization warning - normal on some devices
        // This is expected on iOS and some Android devices
      }

      // Check Bluetooth authorization (iOS)
      try {
        final authorizationStatus = await flutterBeacon.authorizationStatus;

        if (authorizationStatus == AuthorizationStatus.notDetermined) {
          await flutterBeacon.requestAuthorization;
        } else if (authorizationStatus == AuthorizationStatus.denied) {
          return false;
        }
      } catch (e) {
        // Authorization check might fail on Android - that's okay
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  // ============================================================================
  // BROADCASTING (for Lecturers)
  // ============================================================================

  /// Start broadcasting iBeacon
  Future<void> startBroadcasting({
    required int major,
    required int minor,
  }) async {
    try {
      // Ensure initialized
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception('Failed to initialize BLE service');
        }
      }

      // Stop previous broadcast if any
      if (_isBroadcasting) {
        await stopBroadcasting();
        // Small delay to ensure previous broadcast is stopped
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Create beacon data
      final beacon = BeaconBroadcast(
        proximityUUID: beaconUUID,
        major: major,
        minor: minor,
        identifier: 'Attendify-Beacon',
        // Optional: add transmission power if needed
        // transmissionPower: -59, // Adjust based on your needs
      );

      // Start broadcasting
      await flutterBeacon.startBroadcast(beacon);

      _isBroadcasting = true;
      _currentMajor = major;
      _currentMinor = minor;
    } catch (e) {
      _isBroadcasting = false;
      _currentMajor = null;
      _currentMinor = null;

      // Re-throw with more context
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('not supported') ||
          errorMessage.contains('unsupported')) {
        throw Exception(
            'Broadcasting not supported on this device. '
                'This is a hardware limitation. '
                'Please use a different device or QR code alternative.'
        );
      } else if (errorMessage.contains('permission')) {
        throw Exception(
            'Bluetooth permissions are required. '
                'Please grant all Bluetooth and Location permissions in Settings.'
        );
      } else if (errorMessage.contains('bluetooth') ||
          errorMessage.contains('adapter')) {
        throw Exception(
            'Bluetooth error. '
                'Please make sure Bluetooth is turned ON and try again.'
        );
      } else if (errorMessage.contains('location')) {
        throw Exception(
            'Location services must be enabled. '
                'Please turn ON Location in device settings.'
        );
      } else {
        throw Exception('Failed to start broadcasting: ${e.toString()}');
      }
    }
  }

  /// Stop broadcasting
  Future<void> stopBroadcasting() async {
    try {
      if (!_isBroadcasting) {
        return;
      }

      await flutterBeacon.stopBroadcast();

      _isBroadcasting = false;
      _currentMajor = null;
      _currentMinor = null;
    } catch (e) {
      // Force state update even if there's an error
      _isBroadcasting = false;
      _currentMajor = null;
      _currentMinor = null;
      // Don't throw - stopping should always succeed
    }
  }

  /// Check if currently broadcasting
  bool get isBroadcasting => _isBroadcasting;

  /// Get current broadcasting major value
  int? get currentMajor => _currentMajor;

  /// Get current broadcasting minor value
  int? get currentMinor => _currentMinor;

  // ============================================================================
  // SCANNING (for Students)
  // ============================================================================

  /// Start scanning for beacons
  Stream<List<Beacon>> startScanning() async* {
    try {
      // Ensure initialized
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception('Failed to initialize BLE service');
        }
      }

      if (_isScanning) {
        await stopScanning();
      }

      _isScanning = true;

      // Define regions to scan
      final regions = <Region>[
        Region(
          identifier: 'Attendify',
          proximityUUID: beaconUUID,
        ),
      ];

      // Start ranging
      _rangingSubscription = flutterBeacon.ranging(regions).listen(
            (RangingResult result) {
          if (result.beacons.isNotEmpty) {
            _beaconController.add(result.beacons);
          } else {
            _beaconController.add([]);
          }
        },
        onError: (error) {
          _beaconController.addError(error);
        },
      );

      // Yield results from the stream
      await for (final beacons in _beaconController.stream) {
        yield beacons;
      }
    } catch (e) {
      _isScanning = false;
      yield [];
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    try {
      await _rangingSubscription?.cancel();
      _rangingSubscription = null;
      _isScanning = false;
    } catch (e) {
      // Force state update
      _isScanning = false;
    }
  }

  /// Check if currently scanning
  bool get isScanning => _isScanning;

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get proximity string from Beacon proximity enum
  String getProximityString(Proximity proximity) {
    switch (proximity) {
      case Proximity.immediate:
        return 'Very Close';
      case Proximity.near:
        return 'Near';
      case Proximity.far:
        return 'Far';
      case Proximity.unknown:
      default:
        return 'Unknown';
    }
  }

  /// Check if broadcasting is supported on this device
  Future<bool> isBroadcastingSupported() async {
    try {
      // Try to initialize first
      if (!_isInitialized) {
        await initialize();
      }

      // Check authorization status
      final authStatus = await flutterBeacon.authorizationStatus;

      if (authStatus == AuthorizationStatus.denied) {
        return false;
      }

      // Try to check if device supports broadcasting
      // This is a heuristic - not 100% accurate
      try {
        await flutterBeacon.initializeAndCheckScanning;
        return true;
      } catch (e) {
        // If initialization fails, broadcasting might not be supported
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get detailed status information for debugging
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final authStatus = await flutterBeacon.authorizationStatus;

      return {
        'isInitialized': _isInitialized,
        'isBroadcasting': _isBroadcasting,
        'isScanning': _isScanning,
        'currentMajor': _currentMajor,
        'currentMinor': _currentMinor,
        'authorizationStatus': authStatus.toString(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Dispose and cleanup all resources
  Future<void> dispose() async {
    try {
      await stopBroadcasting();
      await stopScanning();
      await _beaconController.close();
      _isInitialized = false;
    } catch (e) {
      // Ignore errors during disposal
    }
  }
}
