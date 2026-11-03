import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/synced_devices/synced_devices_dao.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

/// A reusable action button that navigates to the Synced Devices List ([RightPanelPageOptions.syncedList]),
/// displaying a live, optimized count of paired devices.
class SyncHistoryButton extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const SyncHistoryButton({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceCount = ref.watch(
      syncedDevicesStreamProvider.select((async) => async.value?.length ?? 0),
    );

    return OutlinedButton.icon(
      onPressed: () {
        ref.read(drawerNavigationProvider).navigate(
              context,
              RightPanelPageOptions.syncedList,
            );
      },
      icon: const Icon(Icons.devices_rounded, size: 18),
      label: Text('Paired Devices ($deviceCount)'),
      style: OutlinedButton.styleFrom(
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
