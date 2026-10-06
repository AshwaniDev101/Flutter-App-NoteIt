import 'package:flutter/foundation.dart';

class PlatformHelper {
  /// Returns true if running on a native Android or iOS device (excluding web)
  static bool get isMobileScreen {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Returns true if running on Windows, macOS, Linux, or the Web
  static bool get isDesktopScreen {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  // ==== SPECIFIC PLATFORM CHECKS ====
  /// Returns true if running on the Web
  static bool get isWeb => kIsWeb;

  /// Returns true ONLY if running natively on Android
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Returns true ONLY if running natively on iOS
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Returns true ONLY if running natively on Windows
  static bool get isWindows => !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Returns true ONLY if running natively on macOS
  static bool get isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Returns true ONLY if running natively on Linux
  static bool get isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;


  /// Returns true ONLY if running natively on Windows, macOS, or Linux.
  /// (Excludes Web, Android, and iOS). For desktop-specific plugins.
  static bool get isNativeDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Returns the current platform name as a string
  /// (e.g., "android", "iOS", "windows", "macOS", "linux", or "web")
  static String get name {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  // ==== ENVIRONMENT CHECKS ====

  /// Returns true if the app is running in Debug mode (during development)
  static bool get isDebugMode => kDebugMode;

  /// Returns true if the app is running in Release mode (production/published app)
  static bool get isReleaseMode => kReleaseMode;

  /// Returns true if the app is running in Profile mode (performance testing)
  static bool get isProfileMode => kProfileMode;
}