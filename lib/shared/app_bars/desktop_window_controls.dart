import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/helpers/platform_helper.dart';
import '../../database/shared_preference/shared_preference_manager.dart';

/// Desktop window control buttons (minimize, maximize/unmaximize, close).
///
/// Automatically returns [SizedBox.shrink] on non-native desktop platforms.
class DesktopWindowControls extends StatelessWidget {
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const DesktopWindowControls({
    super.key,
    this.iconSize = 16,
    this.padding = const EdgeInsets.only(right: 8),
  });

  @override
  Widget build(BuildContext context) {
    if (!PlatformHelper.isNativeDesktop) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.minimize, size: iconSize),
            tooltip: 'Minimize',
            onPressed: () => windowManager.minimize(),
          ),
          IconButton(
            icon: Icon(Icons.crop_square, size: iconSize),
            tooltip: 'Maximize',
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
                await SharedPreferenceManager.instance.setWindowMaximized(false);
              } else {
                await windowManager.maximize();
                await SharedPreferenceManager.instance.setWindowMaximized(true);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.close, size: iconSize),
            tooltip: 'Close',
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}
