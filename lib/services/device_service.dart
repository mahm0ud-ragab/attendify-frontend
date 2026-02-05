import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DeviceService {
  static Future<String> getDeviceFingerprint() async {
    final deviceInfo = DeviceInfoPlugin();
    String rawData = "";

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      rawData =
          "${info.id}-${info.model}-${info.manufacturer}-${info.version.release}";
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      rawData =
          "${info.identifierForVendor}-${info.model}-${info.systemVersion}";
    }

    final bytes = utf8.encode(rawData);
    return sha256.convert(bytes).toString();
  }
}
