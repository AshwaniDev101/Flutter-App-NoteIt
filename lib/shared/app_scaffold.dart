import 'package:flutter/material.dart';
import '../core/util/platform_helper.dart';
import '../features/home/view/desktop/right_panel/core/navigator.dart';
import '../features/home/view/shared/desktop_close_button.dart';

/// A centralized Scaffold wrapper that provides a consistent AppBar, 
/// background styling, and desktop close button integration across pages.
class AppScaffold extends StatelessWidget {
  final Widget? title;
  final PreferredSizeWidget? appBar;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showDesktopCloseButton;
  final VoidCallback? onClose;
  final Color? backgroundColor;
  final bool centerTitle;

  const AppScaffold({
    super.key,
    this.title,
    this.appBar,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showDesktopCloseButton = true,
    this.onClose,
    this.backgroundColor,
    this.centerTitle = true,
  });

  /// Convenience constructor for pages managed by [RightPanelPageOptions]
  factory AppScaffold.rightPanel({
    Key? key,
    required RightPanelPageOptions option,
    List<Widget>? actions,
    required Widget body,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    bool showDesktopCloseButton = true,
    VoidCallback? onClose,
    Color? backgroundColor,
    bool centerTitle = true,
  }) {
    return AppScaffold(
      key: key,
      title: Text(option.label),
      actions: actions,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      showDesktopCloseButton: showDesktopCloseButton,
      onClose: onClose,
      backgroundColor: backgroundColor,
      centerTitle: centerTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? colorScheme.surfaceContainerLowest;

    PreferredSizeWidget? effectiveAppBar = appBar;

    if (effectiveAppBar == null && title != null) {
      effectiveAppBar = AppBar(
        title: title,
        centerTitle: centerTitle,
        backgroundColor: bg,
        scrolledUnderElevation: PlatformHelper.isDesktopScreen ? 0.0 : null,
        actions: [
          ...?actions,
          if (showDesktopCloseButton) DesktopCloseButton(onPressed: onClose),
        ],
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: effectiveAppBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
