class Beacon {
  final String uuid;
  final int major;
  final int minor;
  final int rssi;
  final DateTime detectedAt;

  Beacon({
    required this.uuid,
    required this.major,
    required this.minor,
    required this.rssi,
    required this.detectedAt,
  });

  String get signalStrength {
    if (rssi > -60) return 'Excellent';
    if (rssi > -70) return 'Good';
    if (rssi > -80) return 'Fair';
    return 'Weak';
  }

  String get estimatedDistance {
    if (rssi > -60) return 'Very Close (<1m)';
    if (rssi > -70) return 'Close (1-3m)';
    if (rssi > -80) return 'Medium (3-10m)';
    return 'Far (>10m)';
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'major': major,
      'minor': minor,
      'rssi': rssi,
      'detected_at': detectedAt.toIso8601String(),
    };
  }

  factory Beacon.fromJson(Map<String, dynamic> json) {
    return Beacon(
      uuid: json['uuid'],
      major: json['major'],
      minor: json['minor'],
      rssi: json['rssi'],
      detectedAt: DateTime.parse(json['detected_at']),
    );
  }
}