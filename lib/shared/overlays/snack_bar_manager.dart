import 'package:flutter/material.dart';
import 'package:noteit/core/theme/snack_bar_theme_color.dart';
import 'package:toastification/toastification.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Defines the intent and style of the snackbar.
enum SnackBarMessageType {
  error,          // For failures/critical alerts
  info,           // For general information
  acknowledgment, // For success/saves (e.g., "Note saved")
  suggestion,     // For tips, recommendations
  warning,        // For warnings/cautionary alerts
}

extension SnackBarMessageTypeX on SnackBarMessageType {
  /// Maps custom enum to Toastification's internal types
  ToastificationType get toastType {
    switch (this) {
      case SnackBarMessageType.error:
        return ToastificationType.error;
      case SnackBarMessageType.info:
      case SnackBarMessageType.suggestion:
        return ToastificationType.info;
      case SnackBarMessageType.acknowledgment:
        return ToastificationType.success;
      case SnackBarMessageType.warning:
        return ToastificationType.warning;
    }
  }

  /// Default icon corresponding to the message type
  IconData get defaultIcon {
    switch (this) {
      case SnackBarMessageType.error:
        return Icons.error_outline_rounded;
      case SnackBarMessageType.info:
        return Icons.info_outline_rounded;
      case SnackBarMessageType.acknowledgment:
        return Icons.check_circle_outline_rounded;
      case SnackBarMessageType.suggestion:
        return Icons.lightbulb_outline_rounded;
      case SnackBarMessageType.warning:
        return Icons.warning_amber_rounded;
    }
  }
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
    BuildContext? context,
  }) {
    final effectiveContext = context ?? scaffoldMessengerKey.currentContext;

    // Calculate 33% of the screen width (fallback to 400 if context is null)
    final toastWidth = effectiveContext != null
        ? MediaQuery.sizeOf(effectiveContext).width * 0.33
        : 400.0;

    // Fetch background and foreground colors directly from SnackBarThemeColor
    final (backgroundColor, foregroundColor) = SnackBarThemeColor.of(effectiveContext, type);

    toastification.show(
      context: effectiveContext,
      type: type.toastType,
      style: ToastificationStyle.fillColored,

      // -- STRICTLY THEME-BASED COLORS APPLIED HERE --
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      primaryColor: backgroundColor,

      alignment: alignment,
      autoCloseDuration: duration,
      showProgressBar: showProgressBar,

      icon: Icon(customIcon ?? type.defaultIcon, color: foregroundColor),

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
}