import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class PermissionService {
  /// Request all necessary Bluetooth and Location permissions
  Future<bool> requestBluetoothPermissions() async {
    print('🔐 Starting permission request...');

    try {
      // Different permissions for Android 12+ vs older versions
      Map<Permission, PermissionStatus> statuses;

      if (Platform.isAndroid) {
        // Check Android version
        final androidInfo = await _getAndroidVersion();
        print('📱 Android API Level: $androidInfo');

        if (androidInfo >= 31) {
          // Android 12+ (API 31+)
          print('📋 Requesting Android 12+ permissions...');
          statuses = await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.locationWhenInUse, // More specific than just "location"
          ].request();
        } else {
          // Android 11 and below
          print('📋 Requesting Android 11 and below permissions...');
          statuses = await [
            Permission.bluetooth,
            Permission.locationWhenInUse,
          ].request();
        }
      } else if (Platform.isIOS) {
        // iOS permissions
        print('📋 Requesting iOS permissions...');
        statuses = await [
          Permission.bluetooth,
          Permission.locationWhenInUse,
        ].request();
      } else {
        print('❌ Unsupported platform');
        return false;
      }

      // Log each permission status
      print('📊 Permission Results:');
      statuses.forEach((permission, status) {
        print('   ${permission.toString()}: ${status.toString()}');

        if (status.isDenied) {
          print('   ⚠️ ${permission.toString()} was DENIED');
        } else if (status.isPermanentlyDenied) {
          print('   🚫 ${permission.toString()} was PERMANENTLY DENIED');
          print('   → User must enable in Settings');
        } else if (status.isGranted) {
          print('   ✅ ${permission.toString()} was GRANTED');
        }
      });

      // Check if all permissions granted
      final allGranted = statuses.values.every((status) => status.isGranted);

      if (allGranted) {
        print('✅ All permissions GRANTED');
      } else {
        print('❌ Some permissions were NOT granted');

        // Check for permanently denied permissions
        final permanentlyDenied = statuses.entries
            .where((entry) => entry.value.isPermanentlyDenied)
            .map((entry) => entry.key)
            .toList();

        if (permanentlyDenied.isNotEmpty) {
          print('🚫 Permanently denied permissions detected!');
          print('   User must go to Settings to enable:');
          permanentlyDenied.forEach((p) => print('   - $p'));
        }
      }

      return allGranted;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if all required Bluetooth permissions are granted
  Future<bool> hasBluetoothPermissions() async {
    print('🔍 Checking current permission status...');

    try {
      bool bluetoothScanGranted = false;
      bool bluetoothConnectGranted = false;
      bool locationGranted = false;

      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();

        if (androidInfo >= 31) {
          // Android 12+
          bluetoothScanGranted = await Permission.bluetoothScan.isGranted;
          bluetoothConnectGranted = await Permission.bluetoothConnect.isGranted;
          locationGranted = await Permission.locationWhenInUse.isGranted;

          print('   Bluetooth Scan: ${bluetoothScanGranted ? "✅" : "❌"}');
          print('   Bluetooth Connect: ${bluetoothConnectGranted ? "✅" : "❌"}');
          print('   Location: ${locationGranted ? "✅" : "❌"}');
        } else {
          // Android 11 and below
          bluetoothScanGranted = await Permission.bluetooth.isGranted;
          bluetoothConnectGranted = true; // Not needed on older Android
          locationGranted = await Permission.locationWhenInUse.isGranted;

          print('   Bluetooth: ${bluetoothScanGranted ? "✅" : "❌"}');
          print('   Location: ${locationGranted ? "✅" : "❌"}');
        }
      } else if (Platform.isIOS) {
        bluetoothScanGranted = await Permission.bluetooth.isGranted;
        bluetoothConnectGranted = true; // Handled differently on iOS
        locationGranted = await Permission.locationWhenInUse.isGranted;

        print('   Bluetooth: ${bluetoothScanGranted ? "✅" : "❌"}');
        print('   Location: ${locationGranted ? "✅" : "❌"}');
      }

      final allGranted = bluetoothScanGranted && bluetoothConnectGranted && locationGranted;
      print(allGranted ? '✅ All permissions granted' : '❌ Missing permissions');

      return allGranted;
    } catch (e) {
      print('❌ Error checking permissions: $e');
      return false;
    }
  }

  /// Check if location services are enabled (different from permission!)
  Future<bool> isLocationServiceEnabled() async {
    try {
      final serviceStatus = await Permission.locationWhenInUse.serviceStatus;
      final isEnabled = serviceStatus.isEnabled;

      print('📍 Location Service Status: ${isEnabled ? "ENABLED" : "DISABLED"}');

      if (!isEnabled) {
        print('⚠️ Location service is DISABLED!');
        print('   User must enable Location in device settings');
      }

      return isEnabled;
    } catch (e) {
      print('❌ Error checking location service: $e');
      return false;
    }
  }

  /// Open app settings so user can manually grant permissions
  Future<void> openSettings() async {
    print('⚙️ Opening app settings...');
    await openAppSettings();
  }


  /// Get Android API level
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      print('📱 Android SDK: $sdkInt (Android ${androidInfo.version.release})');
      return sdkInt;
    } catch (e) {
      print('⚠️ Could not detect Android version: $e');
      return 31; // Default to Android 12+
    }
  }

  /// Comprehensive permission check with detailed diagnostics
  Future<Map<String, dynamic>> getDiagnostics() async {
    print('🔬 Running permission diagnostics...');

    final diagnostics = <String, dynamic>{};

    try {
      // Check individual permissions
      if (Platform.isAndroid) {
        diagnostics['platform'] = 'Android';
        diagnostics['bluetoothScan'] = await Permission.bluetoothScan.status;
        diagnostics['bluetoothConnect'] = await Permission.bluetoothConnect.status;
        diagnostics['location'] = await Permission.locationWhenInUse.status;
        diagnostics['locationService'] = await Permission.locationWhenInUse.serviceStatus;
      } else if (Platform.isIOS) {
        diagnostics['platform'] = 'iOS';
        diagnostics['bluetooth'] = await Permission.bluetooth.status;
        diagnostics['location'] = await Permission.locationWhenInUse.status;
        diagnostics['locationService'] = await Permission.locationWhenInUse.serviceStatus;
      }

      print('📊 Diagnostics:');
      diagnostics.forEach((key, value) {
        print('   $key: $value');
      });

      return diagnostics;
    } catch (e) {
      print('❌ Error getting diagnostics: $e');
      return {'error': e.toString()};
    }
  }
}