// BLE Beacon Service for Broadcasting and Scanning

import 'dart:async';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:permission_handler/permission_handler.dart';

class BLEService {
  // University UUID from backend
  static const String beaconUUID = '123e4567-e89b-12d3-a456-426614174000';

  StreamSubscription<RangingResult>? _rangingSubscription;
  bool _isBroadcasting = false;

  // Check and request permissions
  Future<bool> checkPermissions() async {
    print('🔐 Checking permissions...');

    try {
      // Request all permissions at once
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();

      // Check if all are granted
      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        print('❌ Some permissions denied');
        return false;
      }

      // Check Location Services are enabled
      final serviceEnabled = await Permission.location.serviceStatus.isEnabled;
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled!');
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Error checking permissions: $e');
      return false;
    }
  }

  // Initialize BLE
  Future<bool> initialize() async {
    try {
      print('🔧 Initializing flutter_beacon...');
      await flutterBeacon.initializeScanning;

      // Check if Bluetooth is available
      final state = await flutterBeacon.bluetoothState;
      if (state == BluetoothState.stateOff) {
        print('⚠️ Bluetooth is OFF');
        return false;
      }
      return true;
    } catch (e) {
      print('❌ BLE initialization error: $e');
      return false;
    }
  }

  // Broadcast beacon (for lecturers)
  Future<void> startBroadcasting({
    required int major,
    required int minor,
  }) async {
    try {
      await flutterBeacon.initializeScanning;

      final beaconBroadcast = BeaconBroadcast(
        proximityUUID: beaconUUID,
        major: major,
        minor: minor,
        identifier: 'Attendify-Beacon',
      );

      await flutterBeacon.startBroadcast(beaconBroadcast);
      _isBroadcasting = true;
      print('📡 Broadcasting: Major=$major, Minor=$minor');
    } catch (e) {
      print('❌ Error starting broadcast: $e');
      rethrow;
    }
  }

  bool get isBroadcasting => _isBroadcasting;

  Future<void> stopBroadcasting() async {
    try {
      await flutterBeacon.stopBroadcast();
      _isBroadcasting = false;
      print('🛑 Stopped broadcasting beacon');
    } catch (e) {
      print('❌ Error stopping broadcast: $e');
    }
  }

  // ---------------------------------------------------------
  // ✅ UPDATED: Start Scanning
  // Now sends 'uuid' and maps 'accuracy' to 'distance'
  // ---------------------------------------------------------
  Stream<Map<String, dynamic>?> startScanning() async* {
    try {
      print('🔍 Initializing scanning...');
      await flutterBeacon.initializeScanning;

      final regions = <Region>[
        Region(
          identifier: 'Attendify',
          proximityUUID: beaconUUID,
        ),
      ];

      await for (final result in flutterBeacon.ranging(regions)) {
        if (result.beacons.isNotEmpty) {
          for (var beacon in result.beacons) {
            yield {
              'uuid': beacon.proximityUUID, // Required by UI
              'major': beacon.major,
              'minor': beacon.minor,
              'rssi': beacon.rssi,
              'distance': beacon.accuracy, // Mapped from accuracy to distance
              'proximity': beacon.proximity.toString().split('.').last, // Returns "near", "immediate", etc.
            };
          }
        } else {
          yield null;
        }
      }
    } catch (e) {
      print('❌ Error during scanning: $e');
      yield null;
    }
  }

  Future<void> stopScanning() async {
    await _rangingSubscription?.cancel();
    _rangingSubscription = null;
    print('🛑 Stopped scanning for beacons');
  }

  // Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      final bluetoothState = await flutterBeacon.bluetoothState;
      if (bluetoothState == BluetoothState.stateOn) return true;

      final scanGranted = await Permission.bluetoothScan.isGranted;
      final connectGranted = await Permission.bluetoothConnect.isGranted;

      if (scanGranted && connectGranted) return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    stopBroadcasting();
    stopScanning();
  }
}
