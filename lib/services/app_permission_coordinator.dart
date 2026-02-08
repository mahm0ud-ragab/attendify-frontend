// Optional: App Permission Coordinator
// Centralizes all permission and service checking logic
// Use this to reduce duplication across multiple screens

import 'package:flutter/material.dart';
import 'permission_service.dart';
import 'bluetooth_service.dart';
import 'dart:io' show Platform;

/// Centralized coordinator for managing app permissions and service states
/// This class handles the entire flow of ensuring the app is ready for BLE operations
class AppPermissionCoordinator {
  final PermissionService _permissionService;
  final BluetoothService _bluetoothService;

  AppPermissionCoordinator({
    PermissionService? permissionService,
    BluetoothService? bluetoothService,
  })  : _permissionService = permissionService ?? PermissionService(),
        _bluetoothService = bluetoothService ?? BluetoothService();

  /// Master method to ensure all requirements are met for BLE scanning
  /// Handles the entire flow including showing dialogs and guiding the user
  /// Returns true if app is ready to scan, false otherwise
  Future<bool> ensureReadyForBleScanning(BuildContext context) async {
    print('🎯 Starting comprehensive BLE readiness check...');

    // Step 1: Permissions check
    final permissionsReady = await _ensurePermissions(context);
    if (!permissionsReady) {
      print('❌ Permissions not ready');
      return false;
    }

    // Step 2: Bluetooth adapter check
    final bluetoothReady = await _ensureBluetooth(context);
    if (!bluetoothReady) {
      print('❌ Bluetooth not ready');
      return false;
    }

    // Step 3: Location services check
    final locationReady = await _ensureLocationService(context);
    if (!locationReady) {
      print('❌ Location service not ready');
      return false;
    }

    print('✅ All checks passed - ready for BLE scanning!');
    return true;
  }

  /// Ensure Bluetooth permissions are granted
  Future<bool> _ensurePermissions(BuildContext context) async {
    final hasPermissions = await _permissionService.hasBluetoothPermissions();
    
    if (hasPermissions) {
      print('✅ Permissions already granted');
      return true;
    }

    // Check if permanently denied
    final permanentlyDenied = await _permissionService.hasPermissionsPermanentlyDenied();
    
    if (permanentlyDenied) {
      // Show dialog to open settings
      await _showPermanentlyDeniedDialog(context);
      return false;
    }

    // Request permissions
    final granted = await _permissionService.requestBluetoothPermissions();
    
    if (!granted && context.mounted) {
      // Show explanation dialog
      await _showPermissionExplanationDialog(context);
      return false;
    }

    return granted;
  }

  /// Ensure Bluetooth adapter is enabled
  Future<bool> _ensureBluetooth(BuildContext context) async {
    final isEnabled = await _bluetoothService.isBluetoothOn();
    
    if (isEnabled) {
      print('✅ Bluetooth already enabled');
      return true;
    }

    // Try to enable Bluetooth (Android only)
    if (Platform.isAndroid) {
      final enabled = await _permissionService.promptEnableBluetooth();
      if (enabled) {
        print('✅ Bluetooth enabled automatically');
        return true;
      }
    }

    // Show dialog to enable manually
    if (context.mounted) {
      await _showBluetoothDisabledDialog(context);
    }
    
    return false;
  }

  /// Ensure Location services are enabled
  Future<bool> _ensureLocationService(BuildContext context) async {
    final isEnabled = await _permissionService.isLocationServiceEnabled();
    
    if (isEnabled) {
      print('✅ Location service already enabled');
      return true;
    }

    // Show dialog to enable location
    if (context.mounted) {
      await _showLocationDisabledDialog(context);
    }
    
    return false;
  }

  // ══════════════════════════════════════════════════════════════
  // Dialog Methods
  // ══════════════════════════════════════════════════════════════

  Future<void> _showPermissionExplanationDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
          'Bluetooth: To detect nearby beacons\n'
          'Location: Required by Android for BLE scanning\n\n'
          'Please grant these permissions to continue.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _permissionService.requestBluetoothPermissions();
            },
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermanentlyDeniedDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
          'To use this feature, please:\n'
          '1. Open Settings\n'
          '2. Go to Permissions\n'
          '3. Enable Bluetooth and Location\n'
          '4. Return to this app',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _permissionService.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBluetoothDisabledDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
        content: Text(
          Platform.isAndroid
              ? 'Please enable Bluetooth to scan for beacons.\n\n'
                  'You can enable it in Quick Settings or device settings.'
              : 'Please enable Bluetooth in your device settings to continue.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationDisabledDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
          'Please enable Location Services to scan for beacons.\n\n'
          'Location is required by Android for Bluetooth beacon scanning.\n\n'
          'Tap "Open Settings" to enable it.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _permissionService.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Utility Methods
  // ══════════════════════════════════════════════════════════════

  /// Quick check without showing any dialogs
  /// Useful for checking state on app resume
  Future<bool> isReadyForBleScanning() async {
    final hasPermissions = await _permissionService.hasBluetoothPermissions();
    final bluetoothOn = await _bluetoothService.isBluetoothOn();
    final locationOn = await _permissionService.isLocationServiceEnabled();
    
    return hasPermissions && bluetoothOn && locationOn;
  }

  /// Get detailed status information
  Future<Map<String, bool>> getDetailedStatus() async {
    return {
      'hasPermissions': await _permissionService.hasBluetoothPermissions(),
      'bluetoothEnabled': await _bluetoothService.isBluetoothOn(),
      'locationEnabled': await _permissionService.isLocationServiceEnabled(),
    };
  }
}

// ══════════════════════════════════════════════════════════════
// USAGE EXAMPLE IN BEACON SCANNER SCREEN
// ══════════════════════════════════════════════════════════════

/*
class _BeaconScannerScreenState extends State<BeaconScannerScreen> 
    with WidgetsBindingObserver {
  
  final _coordinator = AppPermissionCoordinator();
  
  Future<void> _startScan() async {
    // Simple one-line check!
    final ready = await _coordinator.ensureReadyForBleScanning(context);
    
    if (!ready) {
      print('Not ready to scan - user was guided through the process');
      return;
    }
    
    // All checks passed - start scanning
    await _bluetoothService.startScan();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckAfterResume();
    }
  }
  
  Future<void> _recheckAfterResume() async {
    final ready = await _coordinator.isReadyForBleScanning();
    setState(() {
      _statusMessage = ready ? 'Ready to scan' : 'Please check settings';
    });
  }
}
*/
