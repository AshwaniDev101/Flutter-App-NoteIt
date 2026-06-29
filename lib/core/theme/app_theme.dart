import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/theme/note_theme.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';


part 'custom_themes/light/light.dart';
part 'custom_themes/dark/dark.dart';
part 'custom_themes/amoled/amoled.dart';
part 'custom_themes/sepia/sepia.dart';


// THEME ENUM
enum AppThemeType {
  light,
  dark,
  amoled,
  sepia,
}


// STATE MANAGER (RIVERPOD)
class ThemeNotifier extends Notifier<AppThemeType> {
  late final SharedPreferenceManager _prefs;

  @override
  AppThemeType build() {
    _prefs = ref.watch(sharedPreferenceProvider);
    final savedThemeStr = _prefs.themeType;

    return AppThemeType.values.firstWhere(
          (theme) => theme.name == savedThemeStr,
      orElse: () => AppThemeType.dark,
    );
  }

  Future<void> setTheme(AppThemeType type) async {
    state = type;
    await _prefs.setThemeType(type.name);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeType>(ThemeNotifier.new);


// UI THEME RESOLVER
class Themes {
  /// Resolves the unified ThemeData package based on the active state selection
  static ThemeData getThemeData(AppThemeType type) {
    switch (type) {
      case AppThemeType.light:
        return _lightThemeData;
      case AppThemeType.dark:
        return _darkThemeData;
      case AppThemeType.amoled:
        return _amoledThemeData;
      case AppThemeType.sepia:
        return _sepiaThemeData;
    }
  }
}