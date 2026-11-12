import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A docked bottom app bar that spans edge-to-edge off screen edges.
///
/// Docked flush at the screen bottom by default with zero margins.
/// Automatically handles virtual keyboard visibility and gesture navigation insets,
/// and updates the Android system navigation bar background color to match.
class FloatingBottomAppBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double elevation;
  final double horizontalMargin;
  final double bottomMargin;
  final double borderRadius;
  final double? height;

  const FloatingBottomAppBar({
    super.key,
    required this.child,
    this.padding,
    this.elevation = 0.0,
    this.horizontalMargin = 0.0,
    this.bottomMargin = 0.0,
    this.borderRadius = 0.0,
    this.height = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    final effectiveBottomMargin = isKeyboardOpen ? bottomInset : bottomMargin;
    final effectiveHorizontalMargin = isKeyboardOpen ? 0.0 : horizontalMargin;
    final effectiveRadius = isKeyboardOpen ? 0.0 : borderRadius;

    final theme = Theme.of(context);
    final navBarColor = theme.bottomAppBarTheme.color ?? theme.colorScheme.surfaceContainer;
    final isDark = theme.brightness == Brightness.dark;

    final systemUiOverlayStyle = SystemUiOverlayStyle(
      systemNavigationBarColor: navBarColor,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: Padding(
        padding: EdgeInsets.only(
          left: effectiveHorizontalMargin,
          right: effectiveHorizontalMargin,
          bottom: effectiveBottomMargin,
        ),
        child: BottomAppBar(
          height: height,
          elevation: elevation,
          shape: (effectiveRadius > 0 && !isKeyboardOpen)
              ? AutomaticNotchedShape(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(effectiveRadius)),
                  ),
                )
              : null,
          clipBehavior: Clip.antiAlias,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0.0),
          child: child,
        ),
      ),
    );
  }
}
