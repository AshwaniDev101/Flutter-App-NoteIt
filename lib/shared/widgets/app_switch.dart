import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noteit/core/helpers/platform_helper.dart';

/// Standardized, platform-adaptive toggle switch component for NoteIt.
///
/// Automatically applies compact desktop scaling (`0.75x`) on desktop platforms
/// (Windows/macOS/Linux/Web) and full-size touch targets (`1.0x`) on mobile devices (Android/iOS).
/// Triggers light haptic feedback on mobile touch devices when toggled.
class AppSwitch extends StatelessWidget {
  /// Current boolean state of the switch.
  final bool value;

  /// Callback triggered when switch state changes.
  final ValueChanged<bool>? onChanged;

  /// Optional custom thumb icon or function returning icon based on WidgetState.
  final WidgetStateProperty<Icon?>? thumbIcon;

  /// Optional active color for the thumb/track.
  final Color? activeColor;

  /// Optional inactive thumb color.
  final Color? inactiveThumbColor;

  /// Optional inactive track color.
  final Color? inactiveTrackColor;

  /// Scale factor for desktop screens. Defaults to `0.75`.
  final double desktopScale;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.thumbIcon,
    this.activeColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.desktopScale = 0.75,
  });

  void _handleChanged(bool newValue) {
    if (onChanged == null) return;
    if (PlatformHelper.isAndroid || PlatformHelper.isIOS) {
      HapticFeedback.lightImpact();
    }
    onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = PlatformHelper.isDesktopScreen;

    Widget switchWidget = Switch(
      value: value,
      onChanged: onChanged != null ? _handleChanged : null,
      thumbIcon: thumbIcon,
      activeColor: activeColor,
      inactiveThumbColor: inactiveThumbColor,
      inactiveTrackColor: inactiveTrackColor,
    );

    if (isDesktop) {
      switchWidget = Transform.scale(
        scale: desktopScale,
        alignment: Alignment.centerRight,
        child: switchWidget,
      );
    }

    return switchWidget;
  }
}
