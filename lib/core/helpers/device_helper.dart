import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceHelper {
  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String platform = Platform.operatingSystem; // 'android', 'windows', etc.
    String deviceName = 'Unknown Device';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model; // e.g., 'Redmi Note 10S'
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceName = windowsInfo.computerName; // e.g., 'Ashwin-PC'
      }
    } catch (e) {
      print("Failed to get device info: $e");
    }

    return {
      'platform': platform,
      'deviceName': deviceName,
    };
  }
}