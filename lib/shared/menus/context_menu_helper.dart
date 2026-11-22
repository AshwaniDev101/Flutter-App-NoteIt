import 'package:flutter/material.dart';

import '../../core/config/menu_anchor_constants.dart';

/// SingleChildLayoutDelegate that calculates 2D quadrant-aware positioning
/// using the exact real-time measured dimensions ([childSize]) of the popup menu.
class SmartContextMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Offset globalTapPosition;
  final double edgeMargin;

  SmartContextMenuLayoutDelegate({
    required this.globalTapPosition,
    this.edgeMargin = 8.0,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double x = globalTapPosition.dx;
    double y = globalTapPosition.dy;

    // Horizontal check: If menu extends past right edge, open LEFT from cursor
    if (x + childSize.width > size.width - edgeMargin) {
      x = globalTapPosition.dx - childSize.width;
    }

    // Vertical check: If menu extends past bottom edge, open UP from cursor
    if (y + childSize.height > size.height - edgeMargin) {
      y = globalTapPosition.dy - childSize.height;
    }

    // Safety clamping so menu never clips off top or left boundaries
    x = x.clamp(edgeMargin, (size.width - childSize.width - edgeMargin).clamp(edgeMargin, double.infinity));
    y = y.clamp(edgeMargin, (size.height - childSize.height - edgeMargin).clamp(edgeMargin, double.infinity));

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(SmartContextMenuLayoutDelegate oldDelegate) {
    return globalTapPosition != oldDelegate.globalTapPosition ||
        edgeMargin != oldDelegate.edgeMargin;
  }
}

class _SmartContextMenuRoute<T> extends PopupRoute<T> {
  final Offset globalTapPosition;
  final List<PopupMenuEntry<T>> items;
  final ShapeBorder? shape;
  final double? elevation;
  final BoxConstraints? constraints;
  final Color? color;

  _SmartContextMenuRoute({
    required this.globalTapPosition,
    required this.items,
    this.shape,
    this.elevation,
    this.constraints,
    this.color,
  });

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final theme = Theme.of(context);
    final popupMenuTheme = PopupMenuTheme.of(context);

    final backgroundColor = color ??
        popupMenuTheme.color ??
        theme.colorScheme.surfaceContainerLowest;

    final menuElevation = elevation ?? popupMenuTheme.elevation ?? 8.0;
    final menuShape = shape ?? popupMenuTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return CustomSingleChildLayout(
      delegate: SmartContextMenuLayoutDelegate(
        globalTapPosition: globalTapPosition,
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          alignment: Alignment.center,
          child: Material(
            color: backgroundColor,
            elevation: menuElevation,
            shape: menuShape,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: constraints ?? const BoxConstraints(minWidth: AppMenuWidths.compact),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Performance-optimized helper for true 2D quadrant-aware desktop context menu positioning.
abstract class ContextMenuHelper {
  const ContextMenuHelper._();

  /// Displays a true 2D quadrant-aware context menu anchored precisely at [globalTapPosition].
  ///
  /// Dynamically measures [childSize] and flips the menu's anchor corner to:
  /// - Top-Left when space is available below & right.
  /// - Bottom-Left when space is available right, but overflow below (opens UP from cursor).
  /// - Top-Right when space is available below, but overflow right (opens LEFT from cursor).
  /// - Bottom-Right when overflow below & right (opens UP and LEFT from cursor).
  static Future<T?> show<T>({
    required BuildContext context,
    required Offset globalTapPosition,
    required List<PopupMenuEntry<T>> items,
    ShapeBorder? shape,
    double? elevation,
    BoxConstraints? constraints,
    Color? color,
  }) {
    return Navigator.of(context).push<T>(
      _SmartContextMenuRoute<T>(
        globalTapPosition: globalTapPosition,
        items: items,
        shape: shape,
        elevation: elevation,
        constraints: constraints,
        color: color,
      ),
    );
  }

  /// Calculates a dynamic [RelativeRect] for standard [showMenu].
  static RelativeRect getDynamicRelativeRect({
    required BuildContext context,
    required Offset globalTapPosition,
  }) {
    final screenSize = MediaQuery.sizeOf(context);
    return RelativeRect.fromLTRB(
      globalTapPosition.dx,
      globalTapPosition.dy,
      screenSize.width - globalTapPosition.dx,
      screenSize.height - globalTapPosition.dy,
    );
  }
}
