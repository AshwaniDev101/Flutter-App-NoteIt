import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/platform_helper.dart';
import '../../../drawer/app_drawer.dart';
import '../../core/providers.dart';

/// Only visible when you're on the desktop right panel
class DesktopCloseButton extends ConsumerWidget {
  const DesktopCloseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If it is NOT a desktop screen, return an empty box
    if (!PlatformHelper.isDesktopScreen) {
      return const SizedBox.shrink();
    }

    // Otherwise, show the close button
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Close',
        onPressed: () {
          ref.read(desktopRightPanelViewProvider.notifier).setView(DrawerOption.allNotes);
        },
      ),
    );
  }
}