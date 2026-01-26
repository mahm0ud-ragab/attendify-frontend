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

      print('📊 Permission results:');
      statuses.forEach((permission, status) {
        print('   $permission: $status');
      });

      // Check if all are granted
      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        print('❌ Some permissions denied');

        // Check for permanently denied
        bool anyPermanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);
        if (anyPermanentlyDenied) {
          print('🚫 Some permissions permanently denied - user must enable in settings');
        }

        return false;
      }

      // Check Location Services are enabled
      final serviceEnabled = await Permission.location.serviceStatus.isEnabled;
      print('   Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        print('   ⚠️ Location services are disabled!');
        return false;
      }

      print('✅ All permissions granted!');
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

      print('✅ flutter_beacon initialized');

      // Check if Bluetooth is available
      final state = await flutterBeacon.bluetoothState;
      print('📶 Bluetooth state: $state');

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

      print('📡 Broadcasting beacon: UUID=$beaconUUID, Major=$major, Minor=$minor');
    } catch (e) {
      print('❌ Error starting broadcast: $e');
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
      print('🛑 Stopped broadcasting beacon');
    } catch (e) {
      print('❌ Error stopping broadcast: $e');
    }
  }

  // Start scanning for beacons (for students) - Returns detected beacons
  Stream<Map<String, dynamic>?> startScanning() async* {
    try {
      print('🔍 Initializing scanning...');
      await flutterBeacon.initializeScanning;

      print('🎯 Creating region with UUID: $beaconUUID');
      final regions = <Region>[
        Region(
          identifier: 'Attendify',
          proximityUUID: beaconUUID,
        ),
      ];

      print('📡 Starting ranging...');

      await for (final result in flutterBeacon.ranging(regions)) {
        print('📊 Ranging result received:');
        print('   Region: ${result.region.identifier}');
        print('   Beacons found: ${result.beacons.length}');

        if (result.beacons.isNotEmpty) {
          for (var beacon in result.beacons) {
            print('   ✅ Beacon detected:');
            print('      UUID: ${beacon.proximityUUID}');
            print('      Major: ${beacon.major}');
            print('      Minor: ${beacon.minor}');
            print('      RSSI: ${beacon.rssi}');
            print('      Accuracy: ${beacon.accuracy}');

            yield {
              'major': beacon.major,
              'minor': beacon.minor,
              'rssi': beacon.rssi,
              'accuracy': beacon.accuracy,
              'proximity': beacon.proximity.toString(),
            };
          }
        } else {
          print('   📭 No beacons in range');
          yield null;
        }
      }
    } catch (e) {
      print('❌ Error during scanning: $e');
      print('   Stack trace: ${StackTrace.current}');
      yield null;
    }
  }

  // Stop scanning
  Future<void> stopScanning() async {
    await _rangingSubscription?.cancel();
    _rangingSubscription = null;
    print('🛑 Stopped scanning for beacons');
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
      print("❌ Bluetooth check error: $e");
      return false;
    }
  }

  // Dispose
  void dispose() {
    stopBroadcasting();
    stopScanning();
  }
}