import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../core/util/platform_helper.dart';
import 'package:noteit/features/home/core/providers.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import '../features/home/view/shared/desktop_close_button.dart';

/// A centralized Scaffold wrapper that provides a consistent AppBar, 
/// background styling, desktop back button, and desktop close button integration across pages.
class AppScaffold extends ConsumerWidget {
  final Widget? title;
  final Widget? leading;
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
    this.leading,
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
    Widget? leading,
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
      leading: leading,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? colorScheme.surfaceContainerLowest;

    PreferredSizeWidget? effectiveAppBar = appBar;

    if (effectiveAppBar == null && title != null) {
      Widget? effectiveLeading = leading;

      if (effectiveLeading == null && PlatformHelper.isDesktopScreen) {
        final canPop = ref.watch(desktopRightPanelViewProvider.select((stack) => stack.length > 1));
        if (canPop) {
          effectiveLeading = IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () {
              ref.read(desktopRightPanelViewProvider.notifier).popView();
            },
          );
        }
      }

      effectiveAppBar = AppBar(
        flexibleSpace: PlatformHelper.isNativeDesktop
            ? DragToMoveArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                ),
              )
            : null,
        title: title,
        leading: effectiveLeading,
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
