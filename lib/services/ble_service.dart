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
    // Check Bluetooth
    if (!await Permission.bluetooth.isGranted) {
      final result = await Permission.bluetooth.request();
      if (!result.isGranted) return false;
    }

    // Check Location (required for BLE scanning on Android)
    if (!await Permission.location.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) return false;
    }

    // Check Bluetooth Scan (Android 12+)
    if (!await Permission.bluetoothScan.isGranted) {
      final result = await Permission.bluetoothScan.request();
      if (!result.isGranted) return false;
    }

    // Check Bluetooth Advertise (Android 12+)
    if (!await Permission.bluetoothAdvertise.isGranted) {
      final result = await Permission.bluetoothAdvertise.request();
      if (!result.isGranted) return false;
    }

    return true;
  }

  // Initialize BLE
  Future<bool> initialize() async {
    try {
      await flutterBeacon.initializeScanning;
      return true;
    } catch (e) {
      print('BLE initialization error: $e');
      return false;
    }
  }

  // Broadcast beacon (for lecturers) - Fixed API usage
  Future<void> startBroadcasting({
    required int major,
    required int minor,
  }) async {
    try {
      await flutterBeacon.initializeScanning;

      // Create beacon broadcast parameters
      final beaconBroadcast = BeaconBroadcast(
        proximityUUID: beaconUUID,
        major: major,
        minor: minor,
        identifier: 'Attendify-Beacon',
      );

      // Start broadcasting
      await flutterBeacon.startBroadcast(beaconBroadcast);
      _isBroadcasting = true;

      print('Broadcasting beacon: UUID=$beaconUUID, Major=$major, Minor=$minor');
    } catch (e) {
      print('Error starting broadcast: $e');
      rethrow;
    }
  }

  // Check if currently broadcasting
  bool get isBroadcasting => _isBroadcasting;

  // Stop broadcasting
  Future<void> stopBroadcasting() async {
    try {
      await flutterBeacon.stopBroadcast();
      _isBroadcasting = false;
      print('Stopped broadcasting beacon');
    } catch (e) {
      print('Error stopping broadcast: $e');
    }
  }

  // Start scanning for beacons (for students) - Returns detected beacons
  Stream<Map<String, dynamic>?> startScanning() async* {
    try {
      await flutterBeacon.initializeScanning;

      final regions = <Region>[
        Region(
          identifier: 'Attendify',
          proximityUUID: beaconUUID,
        ),
      ];

      // Listen to ranging results
      await for (final result in flutterBeacon.ranging(regions)) {
        if (result.beacons.isNotEmpty) {
          final beacon = result.beacons.first;

          // Return beacon data
          yield {
            'major': beacon.major,
            'minor': beacon.minor,
            'rssi': beacon.rssi,
            'accuracy': beacon.accuracy,
            'proximity': beacon.proximity.toString(),
          };
        } else {
          yield null;
        }
      }
    } catch (e) {
      print('Error scanning: $e');
      yield null;
    }
  }

  // Stop scanning
  Future<void> stopScanning() async {
    await _rangingSubscription?.cancel();
    _rangingSubscription = null;
    print('Stopped scanning for beacons');
  }

  // Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      // 1. Check actual Bluetooth hardware state
      final bluetoothState = await flutterBeacon.bluetoothState;
      if (bluetoothState == BluetoothState.stateOn) {
        return true;
      }

      // 2. For Android 12+ - state may return OFF even when it's on unless permissions granted
      final scanGranted = await Permission.bluetoothScan.isGranted;
      final connectGranted = await Permission.bluetoothConnect.isGranted;

      if (scanGranted && connectGranted) {
        // If permissions granted, assume Bluetooth is usable
        return true;
      }

      return false;
    } catch (e) {
      print("Bluetooth check error: $e");
      return false;
    }
  }


  // Dispose
  void dispose() {
    stopBroadcasting();
    stopScanning();
  }
}