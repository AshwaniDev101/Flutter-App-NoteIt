import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Defines the intent and style of the snackbar.
enum SnackBarMessageType {
  error,          // For failures/critical alerts
  info,           // For general information
  acknowledgment, // For success/saves (e.g., "Note saved")
  suggestion,     // For tips, recommendations, or warnings
}

class SnackBarManager {
  static void show({
    required String msg,
    SnackBarMessageType type = SnackBarMessageType.acknowledgment,
    String? description,
    Duration duration = const Duration(seconds: 3),
    Alignment alignment = Alignment.bottomRight,
    IconData? customIcon,
    VoidCallback? onTap,
    bool showProgressBar = false,
    bool closable = false,
  }) {
    final context = scaffoldMessengerKey.currentContext;

    // Calculate 33% of the screen width (fallback to 400 if context is null)
    final toastWidth = context != null
        ? MediaQuery.sizeOf(context).width * 0.33
        : 400.0;

    // Grab the active theme so we can dynamically adapt the colors
    final theme = context != null ? Theme.of(context) : null;

    // Fetch the correct background and foreground colors based strictly on the active theme
    final (backgroundColor, foregroundColor) = _getColorsForType(type, theme);

    toastification.show(
      context: context,
      type: _getToastType(type),
      style: ToastificationStyle.fillColored,

      // -- STRICTLY THEME-BASED COLORS APPLIED HERE --
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      primaryColor: backgroundColor,

      alignment: alignment,
      autoCloseDuration: duration,
      showProgressBar: showProgressBar,

      icon: _getIcon(type, customIcon, foregroundColor),

      callbacks: ToastificationCallbacks(
        onTap: (toastItem) => onTap?.call(),
      ),

      closeButton: ToastCloseButton(
        showType: closable ? CloseButtonShowType.always : CloseButtonShowType.none,
      ),

      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      // Use the theme's shadow or a default subtle shadow
      boxShadow: highModeShadow,

      // Title mapped to the 33% width requirement
      title: SizedBox(
        width: toastWidth,
        child: Text(
          msg,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: foregroundColor, // Forces text to match the theme's "on" color
          ),
          softWrap: true,
          maxLines: 10,
          overflow: TextOverflow.visible,
        ),
      ),

      // Optional description with the same width constraint
      description: description != null
          ? SizedBox(
        width: toastWidth,
        child: Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: foregroundColor.withValues(alpha: 0.85), // Slightly dim for hierarchy
          ),
          softWrap: true,
          maxLines: 15,
          overflow: TextOverflow.visible,
        ),
      )
          : null,
    );
  }

  /// Maps the custom Enum to colors dynamically pulled from YOUR active ThemeData.
  /// It now strictly uses your Primary, Secondary, Tertiary, and Error containers.
  static (Color, Color) _getColorsForType(SnackBarMessageType type, ThemeData? theme) {
    final colorScheme = theme?.colorScheme;

    switch (type) {
      case SnackBarMessageType.error:
      // Uses your theme's errorContainer
        return (
        colorScheme?.errorContainer ?? const Color(0xFF8C1D18),
        colorScheme?.onErrorContainer ?? const Color(0xFFFFDAD6),
        );

      case SnackBarMessageType.info:
      // Uses your theme's secondaryContainer
        return (
        colorScheme?.secondaryContainer ?? const Color(0xFF004F53),
        colorScheme?.onSecondaryContainer ?? const Color(0xFF99F5F8),
        );

      case SnackBarMessageType.suggestion:
      // Uses your theme's tertiaryContainer
        return (
        colorScheme?.tertiaryContainer ?? const Color(0xFF75122B),
        colorScheme?.onTertiaryContainer ?? const Color(0xFFFFD9DF),
        );

      case SnackBarMessageType.acknowledgment:
      // Since Material 3 has no "Success" color, we map standard saves/successes
        return (
        colorScheme?.primaryContainer ?? const Color(0xFF262E7A),
        colorScheme?.onPrimaryContainer ?? const Color(0xFFDFE2FF),
        );
    }
  }

  /// Maps your custom enum to Toastification's internal types
  static ToastificationType _getToastType(SnackBarMessageType type) {
    switch (type) {
      case SnackBarMessageType.error:
        return ToastificationType.error;
      case SnackBarMessageType.info:
        return ToastificationType.info;
      case SnackBarMessageType.acknowledgment:
        return ToastificationType.success;
      case SnackBarMessageType.suggestion:
        return ToastificationType.warning;
    }
  }

  /// Returns the appropriate icon, tinted to match the foreground color perfectly
  static Widget? _getIcon(SnackBarMessageType type, IconData? customIcon, Color iconColor) {
    if (customIcon != null) return Icon(customIcon, color: iconColor);

    switch (type) {
      case SnackBarMessageType.error:
        return Icon(Icons.error_outline_rounded, color: iconColor);
      case SnackBarMessageType.info:
        return Icon(Icons.info_outline_rounded, color: iconColor);
      case SnackBarMessageType.acknowledgment:
        return Icon(Icons.check_circle_outline_rounded, color: iconColor);
      case SnackBarMessageType.suggestion:
        return Icon(Icons.lightbulb_outline_rounded, color: iconColor);
    }
  }
}