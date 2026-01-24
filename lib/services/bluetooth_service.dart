import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/beacon.dart';

class BluetoothService {
  Stream<List<Beacon>> get scanStream {
    return FlutterBluePlus.scanResults.map((results) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📡 SCAN UPDATE: ${results.length} devices detected');

      if (results.isEmpty) {
        print('⚠️ No devices found at all!');
        print('   Check: Is Bluetooth ON? Is Location ON?');
        print('   Check: Are permissions granted?');
      }

      final beacons = <Beacon>[];

      for (var result in results) {
        print('---');
        print('Device: ${result.device.remoteId}');
        print('Name: ${result.advertisementData.advName.isEmpty ? "(No Name)" : result.advertisementData.advName}');
        print('RSSI: ${result.rssi} dBm');
        print('Manufacturer Data Keys: ${result.advertisementData.manufacturerData.keys.toList()}');

        // Check if it's a beacon
        if (_isBeacon(result)) {
          print('✅ THIS IS A BEACON!');
          final beacon = _parseBeacon(result);
          if (beacon != null) {
            beacons.add(beacon);
            print('✅ Successfully parsed beacon:');
            print('   UUID: ${beacon.uuid}');
            print('   Major: ${beacon.major}');
            print('   Minor: ${beacon.minor}');
          } else {
            print('❌ Failed to parse beacon data');
          }
        } else {
          print('❌ Not a beacon (missing manufacturer ID 0x004C/76)');
        }
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 SUMMARY: Found ${beacons.length} beacons out of ${results.length} devices');
      print('');

      return beacons;
    });
  }

  Future<bool> isBluetoothOn() async {
    try {
      var state = await FlutterBluePlus.adapterState.first;
      print('🔵 Bluetooth Adapter State: $state');
      return state == BluetoothAdapterState.on;
    } catch (e) {
      print('❌ Error checking Bluetooth state: $e');
      return false;
    }
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 30)}) async {
    print('🚀 Starting BLE scan...');
    print('   Timeout: $timeout');
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
    // Apple iBeacon uses manufacturer ID 0x004C (76 in decimal)
    final hasAppleId = result.advertisementData.manufacturerData.containsKey(0x004C);

    if (!hasAppleId) {
      // Also try decimal 76 just in case
      final hasDecimal76 = result.advertisementData.manufacturerData.containsKey(76);
      return hasDecimal76;
    }

    return hasAppleId;
  }

  Beacon? _parseBeacon(ScanResult result) {
    try {
      // Try both 0x004C and 76
      var data = result.advertisementData.manufacturerData[0x004C] ??
          result.advertisementData.manufacturerData[76];

      if (data == null) {
        print('❌ No manufacturer data found');
        return null;
      }

      print('📦 Raw manufacturer data length: ${data.length} bytes');
      print('📦 Raw data: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      if (data.length < 23) {
        print('❌ Data too short! Need 23 bytes, got ${data.length}');
        return null;
      }

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

      print('✅ Parsed successfully!');

      return Beacon(
        uuid: uuid,
        major: major,
        minor: minor,
        rssi: result.rssi,
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Exception parsing beacon: $e');
      return null;
    }
  }
}