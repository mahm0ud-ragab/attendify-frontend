import 'beacon.dart';

/// Wrapper class for scan results with metadata
class ScanResultData {
  final List<Beacon> beacons;
  final DateTime timestamp;
  final int totalScanned;
  final Duration scanDuration;

  ScanResultData({
    required this.beacons,
    required this.timestamp,
    required this.totalScanned,
    required this.scanDuration,
  });

  /// Get number of detected beacons
  int get beaconCount => beacons.length;

  /// Check if any beacons were found
  bool get hasBeacons => beacons.isNotEmpty;

  /// Get beacons sorted by signal strength (strongest first)
  List<Beacon> get sortedBySignal {
    final sorted = List<Beacon>.from(beacons);
    sorted.sort((a, b) => b.rssi.compareTo(a.rssi));
    return sorted;
  }

  /// Get only beacons with excellent signal (RSSI > -60)
  List<Beacon> get excellentSignalBeacons {
    return beacons.where((b) => b.rssi > -60).toList();
  }

  /// Get only beacons with good signal (RSSI > -70)
  List<Beacon> get goodSignalBeacons {
    return beacons.where((b) => b.rssi > -70).toList();
  }

  /// Get beacons within a specific distance range
  List<Beacon> getBeaconsInRange(int minRssi, int maxRssi) {
    return beacons
        .where((b) => b.rssi >= minRssi && b.rssi <= maxRssi)
        .toList();
  }

  /// Find a specific beacon by UUID
  Beacon? findByUuid(String uuid) {
    try {
      return beacons.firstWhere(
            (b) => b.uuid.toLowerCase() == uuid.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Find beacons by major value
  List<Beacon> findByMajor(int major) {
    return beacons.where((b) => b.major == major).toList();
  }

  /// Find a specific beacon by major and minor
  Beacon? findByMajorMinor(int major, int minor) {
    try {
      return beacons.firstWhere(
            (b) => b.major == major && b.minor == minor,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get statistics about the scan
  Map<String, dynamic> get statistics {
    return {
      'total_beacons': beaconCount,
      'total_scanned': totalScanned,
      'scan_duration_seconds': scanDuration.inSeconds,
      'excellent_signal': excellentSignalBeacons.length,
      'good_signal': goodSignalBeacons.length,
      'average_rssi': beacons.isEmpty
          ? 0
          : beacons.map((b) => b.rssi).reduce((a, b) => a + b) / beaconCount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'beacons': beacons.map((b) => b.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'total_scanned': totalScanned,
      'scan_duration_seconds': scanDuration.inSeconds,
      'statistics': statistics,
    };
  }

  /// Create from JSON
  factory ScanResultData.fromJson(Map<String, dynamic> json) {
    return ScanResultData(
      beacons: (json['beacons'] as List)
          .map((b) => Beacon.fromJson(b))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
      totalScanned: json['total_scanned'],
      scanDuration: Duration(seconds: json['scan_duration_seconds']),
    );
  }

  /// Create an empty result
  factory ScanResultData.empty() {
    return ScanResultData(
      beacons: [],
      timestamp: DateTime.now(),
      totalScanned: 0,
      scanDuration: Duration.zero,
    );
  }

  /// Copy with new values
  ScanResultData copyWith({
    List<Beacon>? beacons,
    DateTime? timestamp,
    int? totalScanned,
    Duration? scanDuration,
  }) {
    return ScanResultData(
      beacons: beacons ?? this.beacons,
      timestamp: timestamp ?? this.timestamp,
      totalScanned: totalScanned ?? this.totalScanned,
      scanDuration: scanDuration ?? this.scanDuration,
    );
  }

  @override
  String toString() {
    return 'ScanResultData(beacons: $beaconCount, timestamp: $timestamp, duration: ${scanDuration.inSeconds}s)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScanResultData &&
        other.timestamp == timestamp &&
        other.totalScanned == totalScanned &&
        other.scanDuration == scanDuration;
  }

  @override
  int get hashCode {
    return timestamp.hashCode ^
    totalScanned.hashCode ^
    scanDuration.hashCode;
  }
}