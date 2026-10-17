// lib/core/config/app_env.dart

import 'package:package_info_plus/package_info_plus.dart';

/// Global synchronous access to static app packaging information.
///
/// WHY THIS FILE EXISTS:
/// Retrieving the app's version and name from the native OS is an asynchronous
/// operation. If we accessed it directly in the UI, every Settings or About screen
/// would require complex loading/error states just to display a simple version string.
/// By fetching this exactly once in `main.dart` and storing it here in a `late`
/// variable, we bypass the Future and make the data instantly available everywhere
/// in the app (e.g., `AppEnv.version`).
///
/// ABOUT THE PACKAGE (package_info_plus):
/// This package queries the host operating system to read the true native app data
/// directly from the OS (like Android's `build.gradle` or Windows' `Runner.rc`).
/// This ensures the version displayed in your Flutter UI always perfectly matches
/// the actual installed version defined in your `pubspec.yaml`.
class AppEnv {
  // Initialized exactly once in main.dart before runApp()
  static late final PackageInfo _packageInfo;

  static void init(PackageInfo info) {
    _packageInfo = info;
  }

  // Quick synchronous getters for the rest of your app
  static String get version => _packageInfo.version;
  static String get appName => _packageInfo.appName;
  static String get buildNumber => _packageInfo.buildNumber;
}