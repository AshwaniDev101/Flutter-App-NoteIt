import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/helpers/platform_helper.dart';
import '../../core/providers.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

/// Only visible when you're on the desktop right panel
class DesktopCloseButton extends ConsumerWidget {
  final VoidCallback? onPressed;

  const DesktopCloseButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!PlatformHelper.isDesktopScreen) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Close',
        onPressed: onPressed ??
            () {
              ref.read(desktopRightPanelViewProvider.notifier).setView(RightPanelPageOptions.noteEditor);
            },
      ),
    );
  }
}