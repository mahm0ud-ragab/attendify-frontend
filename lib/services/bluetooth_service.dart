import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/beacon.dart';

class BluetoothService {
  // ✅ CRITICAL: Only accept beacons with this exact UUID
  static const String EXPECTED_UUID = '123E4567-E89B-12D3-A456-426614174000';

  Stream<List<Beacon>> get scanStream {
    return FlutterBluePlus.scanResults.map((results) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📡 SCAN UPDATE: ${results.length} devices detected');

      if (results.isEmpty) {
        print('! No devices found at all!');
        print('   Check: Is Bluetooth ON? Is Location ON?');
        print('   Check: Are permissions granted?');
      }

      final beacons = <Beacon>[];
      int beaconLikeDevices = 0;
      int correctUuidBeacons = 0;

      for (var result in results) {
        print('---');
        print('Device: ${result.device.remoteId}');
        print('Name: ${result.advertisementData.advName.isEmpty ? "(No Name)" : result.advertisementData.advName}');
        print('RSSI: ${result.rssi} dBm');
        print('Manufacturer Data Keys: ${result.advertisementData.manufacturerData.keys.toList()}');

        // Check if it's a beacon
        if (_isBeacon(result)) {
          beaconLikeDevices++;
          print('✅ Device has beacon-like data!');
          
          final beacon = _parseBeacon(result);
          if (beacon != null) {
            print('✅ Successfully parsed beacon:');
            print('   UUID: ${beacon.uuid}');
            print('   Major: ${beacon.major}');
            print('   Minor: ${beacon.minor}');
            
            // ✅ CRITICAL: Only add if UUID matches
            if (beacon.uuid.toUpperCase() == EXPECTED_UUID) {
              beacons.add(beacon);
              correctUuidBeacons++;
              print('🎯 ✅ CORRECT UUID - ADDING TO LIST!');
            } else {
              print('❌ Wrong UUID - Expected: $EXPECTED_UUID');
              print('❌ Got: ${beacon.uuid}');
            }
          } else {
            print('❌ Failed to parse beacon data');
          }
        } else {
          print('❌ Not a beacon (no valid manufacturer data)');
        }
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 SUMMARY:');
      print('   Total devices: ${results.length}');
      print('   Beacon-like devices: $beaconLikeDevices');
      print('   Correct UUID beacons: $correctUuidBeacons');
      print('   Expected UUID: $EXPECTED_UUID');
      print('');

      return beacons;
    });
  }

  Future<bool> isBluetoothOn() async {
    try {
      var state = await FlutterBluePlus.adapterState.first;
      print('📶 Bluetooth Adapter State: $state');
      return state == BluetoothAdapterState.on;
    } catch (e) {
      print('❌ Error checking Bluetooth state: $e');
      return false;
    }
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 30)}) async {
    print('🚀 Starting BLE scan...');
    print('   Timeout: $timeout');
    print('   Looking for UUID: $EXPECTED_UUID');
    print('   Using Fine Location: true');

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );
      print('✅ Scan started successfully!');
      print('   Listening for devices...');
    } catch (e) {
      print('❌ ERROR starting scan: $e');
      rethrow;
    }
  }

  Future<void> stopScan() async {
    print('🛑 Stopping scan...');
    await FlutterBluePlus.stopScan();
    print('✅ Scan stopped');
  }

  Stream<bool> get isScanningStream {
    return FlutterBluePlus.isScanning.map((scanning) {
      print('🔄 Scanning status changed: ${scanning ? "SCANNING" : "IDLE"}');
      return scanning;
    });
  }

  bool _isBeacon(ScanResult result) {
    if (result.advertisementData.manufacturerData.isEmpty) {
      return false;
    }

    for (var entry in result.advertisementData.manufacturerData.entries) {
      final data = entry.value;
      if (data.length >= 21) {
        return true;
      }
    }

    return false;
  }

  Beacon? _parseBeacon(ScanResult result) {
    try {
      for (var entry in result.advertisementData.manufacturerData.entries) {
        final manufacturerId = entry.key;
        final data = entry.value;

        print('🔍 Checking manufacturer ID: 0x${manufacturerId.toRadixString(16).padLeft(4, '0')} ($manufacturerId)');
        print('📦 Raw manufacturer data length: ${data.length} bytes');
        print('📦 Raw data: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

        if (data.length < 21) {
          print('⚠️ Data too short! Need at least 21 bytes, got ${data.length}');
          continue;
        }

        try {
          // ✅ Try Apple iBeacon format FIRST (manufacturer ID 0x004C with prefix)
          if (manufacturerId == 0x004C && data.length >= 23 && data[0] == 0x02 && data[1] == 0x15) {
            print('📱 Apple iBeacon format detected!');
            return _parseIBeaconStandard(result, data);
          }
          
          // ✅ Try generic format (no prefix)
          if (data.length >= 21) {
            return _parseIBeaconGeneric(result, data);
          }
          
        } catch (e) {
          print('⚠️ Parse error for manufacturer $manufacturerId: $e');
          continue;
        }
      }

      print('❌ No valid iBeacon format found in any manufacturer data');
      return null;

    } catch (e) {
      print('❌ Error parsing beacon: $e');
      return null;
    }
  }

  // Parse standard Apple iBeacon format (with 0x02 0x15 prefix)
  Beacon? _parseIBeaconStandard(ScanResult result, List<int> data) {
    print('📱 Parsing as STANDARD iBeacon (Apple format)');
    
    // Parse UUID (bytes 2-17)
    String uuid = data
        .sublist(2, 18)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();

    uuid = '${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-'
        '${uuid.substring(12, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20, 32)}';

    // Parse Major (bytes 18-19)
    int major = (data[18] << 8) | data[19];

    // Parse Minor (bytes 20-21)
    int minor = (data[20] << 8) | data[21];

    print('✅ Parsed STANDARD iBeacon successfully!');
    print('   UUID: $uuid');
    print('   Major: $major');
    print('   Minor: $minor');

    return Beacon(
      uuid: uuid,
      major: major,
      minor: minor,
      rssi: result.rssi,
      detectedAt: DateTime.now(),
    );
  }

  // Parse generic iBeacon format (no prefix, UUID starts at byte 0)
  Beacon? _parseIBeaconGeneric(ScanResult result, List<int> data) {
    print('📱 Parsing as GENERIC iBeacon (no prefix)');
    
    // Parse UUID (bytes 0-15)
    String uuid = data
        .sublist(0, 16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();

    uuid = '${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-'
        '${uuid.substring(12, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20, 32)}';

    // Parse Major (bytes 16-17)
    int major = (data[16] << 8) | data[17];

    // Parse Minor (bytes 18-19)
    int minor = (data[18] << 8) | data[19];

    print('✅ Parsed GENERIC iBeacon successfully!');
    print('   UUID: $uuid');
    print('   Major: $major');
    print('   Minor: $minor');

    return Beacon(
      uuid: uuid,
      major: major,
      minor: minor,
      rssi: result.rssi,
      detectedAt: DateTime.now(),
    );
  }
}