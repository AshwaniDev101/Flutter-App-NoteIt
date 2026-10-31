import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';

import 'app_typography.dart';

part 'custom_themes/light.dart';

part 'custom_themes/dark.dart';

part 'custom_themes/amoled.dart';

part 'custom_themes/sepia.dart';

// THEME ENUM
enum AppThemeType { light, dark, amoled, sepia }

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeType>(ThemeNotifier.new);

// STATE MANAGER (RIVERPOD)
class ThemeNotifier extends Notifier<AppThemeType> {
  late final SharedPreferenceManager _prefs;

  @override
  AppThemeType build() {
    _prefs = ref.watch(sharedPreferenceProvider);
    final savedThemeStr = _prefs.themeType;

    return AppThemeType.values.firstWhere((theme) => theme.name == savedThemeStr, orElse: () => AppThemeType.dark);
  }

  Future<void> setTheme(AppThemeType type) async {
    state = type;
    await _prefs.setThemeType(type.name);
  }
}

// UI THEME RESOLVER
class Themes {
  /// Resolves the unified ThemeData package based on the active state selection
  static ThemeData getThemeData(AppThemeType type) {
    ThemeData theme;
    switch (type) {
      case AppThemeType.light:
        theme = _lightThemeData;
        break;
      case AppThemeType.dark:
        theme = _darkThemeData;
        break;
      case AppThemeType.amoled:
        theme = _amoledThemeData;
        break;
      case AppThemeType.sepia:
        theme = _sepiaThemeData;
        break;
    }

    if (PlatformHelper.isDesktopScreen) {
      final colorScheme = theme.colorScheme;
      return theme.copyWith(
        visualDensity: VisualDensity.compact,
        switchTheme: SwitchThemeData(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.focused)) {
              return colorScheme.primary.withValues(alpha: 0.12);
            }
            return null;
          }),
          trackOutlineWidth: const WidgetStatePropertyAll(1.0),
          trackOutlineColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return colorScheme.outline;
          }),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return colorScheme.outline;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return colorScheme.surfaceContainerHighest;
          }),
        ),
      );
    }

    return theme;
  }
}
