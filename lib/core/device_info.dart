import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Create a FutureProvider to fetch cross-platform device info asynchronously
final deviceInfoProvider = FutureProvider<BaseDeviceInfo>((ref) async {
  final deviceInfoPlugin = DeviceInfoPlugin();

  // .deviceInfo automatically detects the platform and returns a BaseDeviceInfo object
  return await deviceInfoPlugin.deviceInfo;
});

/// Fetch the Local Wi-Fi IP Address
final localIPProvide = FutureProvider<String?>((ref) async {
  // 'NetworkInfo' special package used for getting network info
  return await NetworkInfo().getWifiIP();
});


extension DeviceInfoExtension on BaseDeviceInfo {

  /// Extracts a human-readable device name based on the platform
  String get extractName {
    if (this is AndroidDeviceInfo) return (this as AndroidDeviceInfo).model;
    if (this is IosDeviceInfo) return (this as IosDeviceInfo).name;
    if (this is WindowsDeviceInfo) return (this as WindowsDeviceInfo).computerName;
    if (this is MacOsDeviceInfo) return (this as MacOsDeviceInfo).computerName;
    if (this is LinuxDeviceInfo) return (this as LinuxDeviceInfo).prettyName;
    if (this is WebBrowserInfo) return (this as WebBrowserInfo).browserName.toString();

    return 'Unknown Device';
  }

  /// Extracts the platform string natively (Safe for Web as well)
  String get extractPlatform {
    if (this is AndroidDeviceInfo) return 'android';
    if (this is IosDeviceInfo) return 'ios';
    if (this is WindowsDeviceInfo) return 'windows';
    if (this is MacOsDeviceInfo) return 'macos';
    if (this is LinuxDeviceInfo) return 'linux';
    if (this is WebBrowserInfo) return 'web';

    return 'unknown';
  }
}

