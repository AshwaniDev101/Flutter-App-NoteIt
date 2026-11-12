import 'package:flutter/material.dart';

/// A floating bottom app bar dock that cleanly elevates off screen edges.
///
/// Uses 8dp page margins and smooth rounded corners by default to align with note cards.
/// Automatically handles virtual keyboard visibility and gesture navigation insets.
class FloatingBottomAppBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double elevation;
  final double horizontalMargin;
  final double bottomMargin;
  final double borderRadius;

  const FloatingBottomAppBar({
    super.key,
    required this.child,
    this.padding,
    this.elevation = 3.0,
    this.horizontalMargin = 8.0,
    this.bottomMargin = 8.0,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final viewPaddingBottom = mediaQuery.viewPadding.bottom;
    final isKeyboardOpen = bottomInset > 0;

    final effectiveBottomMargin = isKeyboardOpen ? bottomInset : (bottomMargin + viewPaddingBottom);
    final effectiveHorizontalMargin = isKeyboardOpen ? 0.0 : horizontalMargin;
    final effectiveRadius = isKeyboardOpen ? 0.0 : borderRadius;

    return Padding(
      padding: EdgeInsets.only(
        left: effectiveHorizontalMargin,
        right: effectiveHorizontalMargin,
        bottom: effectiveBottomMargin,
      ),
      child: BottomAppBar(
        elevation: elevation,
        shape: isKeyboardOpen
            ? null
            : AutomaticNotchedShape(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(effectiveRadius)),
                ),
              ),
        clipBehavior: Clip.antiAlias,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 6.0),
        child: child,
      ),
    );
  }
}
