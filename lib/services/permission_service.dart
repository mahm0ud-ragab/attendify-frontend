// Enhanced Permission Service with Bluetooth and Location Service Checks
// FINAL FIX: Properly opens Android Location Settings (not app info page)

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart'; // ✅ NEW: For opening location settings

/// Result class for comprehensive permission checks
class PermissionCheckResult {
  final bool hasPermissions;
  final bool isBluetoothEnabled;
  final bool isLocationEnabled;
  final List<String> missingPermissions;
  final String? userMessage;

  PermissionCheckResult({
    required this.hasPermissions,
    required this.isBluetoothEnabled,
    required this.isLocationEnabled,
    required this.missingPermissions,
    this.userMessage,
  });

  /// Returns true only if ALL requirements are met
  bool get isReady => hasPermissions && isBluetoothEnabled && isLocationEnabled;

  /// Returns true if user needs to take any action
  bool get requiresAction => !isReady;

  @override
  String toString() {
    return 'PermissionCheckResult(ready: $isReady, permissions: $hasPermissions, '
        'bluetooth: $isBluetoothEnabled, location: $isLocationEnabled, '
        'missing: $missingPermissions)';
  }
}

class PermissionService {
  /// Perform comprehensive pre-scan check
  /// Checks permissions AND service states (Bluetooth, Location)
  Future<PermissionCheckResult> performComprehensiveCheck() async {
    print('🔍 Performing comprehensive permission check...');

    try {
      // Step 1: Check permissions
      final hasPermissions = await hasBluetoothPermissions();

      // Step 2: Check Bluetooth adapter state
      final bluetoothEnabled = await isBluetoothEnabled();

      // Step 3: Check Location service state
      final locationEnabled = await isLocationServiceEnabled();

      // Step 4: Identify missing permissions
      final missing = <String>[];
      if (!hasPermissions) {
        if (Platform.isAndroid) {
          final androidInfo = await _getAndroidVersion();
          if (androidInfo >= 31) {
            if (!await Permission.bluetoothScan.isGranted) {
              missing.add('Bluetooth Scan');
            }
            if (!await Permission.bluetoothConnect.isGranted) {
              missing.add('Bluetooth Connect');
            }
          } else {
            if (!await Permission.bluetooth.isGranted) {
              missing.add('Bluetooth');
            }
          }
          if (!await Permission.locationWhenInUse.isGranted) {
            missing.add('Location');
          }
        } else if (Platform.isIOS) {
          if (!await Permission.bluetooth.isGranted) {
            missing.add('Bluetooth');
          }
          if (!await Permission.locationWhenInUse.isGranted) {
            missing.add('Location');
          }
        }
      }

      // Step 5: Generate user-friendly message
      String? message;
      if (!hasPermissions) {
        message = 'Missing permissions: ${missing.join(', ')}';
      } else if (!bluetoothEnabled) {
        message = 'Please enable Bluetooth';
      } else if (!locationEnabled) {
        message = 'Please enable Location Services';
      }

      final result = PermissionCheckResult(
        hasPermissions: hasPermissions,
        isBluetoothEnabled: bluetoothEnabled,
        isLocationEnabled: locationEnabled,
        missingPermissions: missing,
        userMessage: message,
      );

      print('📊 Check Result: $result');
      return result;
    } catch (e) {
      print('❌ Error during comprehensive check: $e');
      return PermissionCheckResult(
        hasPermissions: false,
        isBluetoothEnabled: false,
        isLocationEnabled: false,
        missingPermissions: ['Unknown'],
        userMessage: 'Error checking permissions: $e',
      );
    }
  }

  /// Check if Bluetooth adapter is enabled (hardware level)
  Future<bool> isBluetoothEnabled() async {
    try {
      // Use flutter_blue_plus to check adapter state
      final adapterState = await FlutterBluePlus.adapterState.first
          .timeout(const Duration(seconds: 3));

      final isOn = adapterState == BluetoothAdapterState.on;
      print('📶 Bluetooth Adapter: ${isOn ? "ON" : "OFF"}');
      return isOn;
    } catch (e) {
      print('⚠️ Error checking Bluetooth state: $e');
      return false;
    }
  }

  /// Prompt user to enable Bluetooth
  /// On Android: Attempts to turn on Bluetooth programmatically
  /// On iOS: Returns false (iOS doesn't allow programmatic enable)
  Future<bool> promptEnableBluetooth() async {
    print('📢 Prompting user to enable Bluetooth...');

    try {
      if (Platform.isAndroid) {
        // Android: Request to turn on Bluetooth
        print('🤖 Requesting Bluetooth enable on Android...');
        await FlutterBluePlus.turnOn();

        // Wait a moment for Bluetooth to initialize
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify it's actually on
        final isOn = await isBluetoothEnabled();
        print(isOn ? '✅ Bluetooth enabled!' : '❌ Bluetooth still off');
        return isOn;
      } else if (Platform.isIOS) {
        // iOS: Cannot programmatically enable Bluetooth
        print('🍎 iOS detected - user must manually enable Bluetooth');
        return false;
      }
      return false;
    } catch (e) {
      print('❌ Error prompting Bluetooth enable: $e');
      return false;
    }
  }

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
            Permission.locationWhenInUse,
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
          for (var p in permanentlyDenied) {
            print('   - $p');
          }
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
      // Use geolocator to check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      print('📍 Location Service Status: ${serviceEnabled ? "ENABLED" : "DISABLED"}');

      if (!serviceEnabled) {
        print('⚠️ Location service is DISABLED!');
        print('   User must enable Location in device settings');
      }

      return serviceEnabled;
    } catch (e) {
      print('❌ Error checking location service: $e');
      return false;
    }
  }

  /// Open app settings so user can manually grant permissions
  Future<void> openSettings() async {
    print('⚙️ Opening app settings...');
    try {
      await openAppSettings();
      print('✅ App settings opened');
    } catch (e) {
      print('❌ Error opening app settings: $e');
    }
  }

  /// Open location settings directly
  /// ✅ FIXED: Now uses Geolocator to open ACTUAL location settings, not app info
  Future<void> openLocationSettings() async {
    print('📍 Opening location settings...');
    try {
      if (Platform.isAndroid) {
        // Use Geolocator to open Android location settings
        final opened = await Geolocator.openLocationSettings();
        print(opened ? '✅ Location settings opened' : '⚠️ Could not open location settings');
      } else {
        // On iOS, open app settings (can't open system location settings)
        await openAppSettings();
        print('✅ App settings opened (iOS)');
      }
    } catch (e) {
      print('❌ Error opening location settings: $e');
      // Fallback to app settings
      print('⚠️ Falling back to app settings...');
      await openSettings();
    }
  }

  /// Check if any permission is permanently denied
  /// This is useful to show "Open Settings" instead of "Request Permission"
  Future<bool> hasPermissionsPermanentlyDenied() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();

        if (androidInfo >= 31) {
          final scanDenied = await Permission.bluetoothScan.isPermanentlyDenied;
          final connectDenied = await Permission.bluetoothConnect.isPermanentlyDenied;
          final locationDenied = await Permission.locationWhenInUse.isPermanentlyDenied;
          return scanDenied || connectDenied || locationDenied;
        } else {
          final bluetoothDenied = await Permission.bluetooth.isPermanentlyDenied;
          final locationDenied = await Permission.locationWhenInUse.isPermanentlyDenied;
          return bluetoothDenied || locationDenied;
        }
      } else if (Platform.isIOS) {
        final bluetoothDenied = await Permission.bluetooth.isPermanentlyDenied;
        final locationDenied = await Permission.locationWhenInUse.isPermanentlyDenied;
        return bluetoothDenied || locationDenied;
      }
      return false;
    } catch (e) {
      print('⚠️ Error checking permanently denied: $e');
      return false;
    }
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
        diagnostics['androidVersion'] = await _getAndroidVersion();
        diagnostics['bluetoothScan'] = await Permission.bluetoothScan.status;
        diagnostics['bluetoothConnect'] = await Permission.bluetoothConnect.status;
        diagnostics['location'] = await Permission.locationWhenInUse.status;
        diagnostics['locationService'] = await Geolocator.isLocationServiceEnabled();
        diagnostics['bluetoothEnabled'] = await isBluetoothEnabled();
      } else if (Platform.isIOS) {
        diagnostics['platform'] = 'iOS';
        diagnostics['bluetooth'] = await Permission.bluetooth.status;
        diagnostics['location'] = await Permission.locationWhenInUse.status;
        diagnostics['locationService'] = await Geolocator.isLocationServiceEnabled();
        diagnostics['bluetoothEnabled'] = await isBluetoothEnabled();
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
