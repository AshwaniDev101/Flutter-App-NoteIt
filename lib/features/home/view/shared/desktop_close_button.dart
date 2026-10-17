import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/platform_helper.dart';
import '../../core/providers.dart';
import '../desktop/content_panel/core/navigator.dart';

/// Only visible when you're on the desktop right panel
class DesktopCloseButton extends ConsumerWidget {
  final VoidCallback? onPressed;

  const DesktopCloseButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!PlatformHelper.isDesktopScreen) {
      return const SizedBox.shrink();
    }

    final colorSchema = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: IconButton(
        icon: Icon(Icons.close, color: colorSchema.primary),
        tooltip: 'Close',
        onPressed: onPressed ??
            () {
              ref.read(desktopRightPanelViewProvider.notifier).setView(RightPanelPageOptions.allNotes);
            },
      ),
    );
  }
}