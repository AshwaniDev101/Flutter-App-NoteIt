import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'package:noteit/features/local_sync/data/providers/sync_server_provider.dart';

class SyncMenuContent extends ConsumerWidget {
  final VoidCallback onCloseMenu;

  const SyncMenuContent({
    super.key,
    required this.onCloseMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncMode = ref.watch(syncModeProvider);
    final isHosting = ref.watch(syncServerProvider) != null;
    final theme = Theme.of(context);
    final isDesktop = PlatformHelper.isDesktopScreen;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sync Engine',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isDesktop)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onCloseMenu,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 1. Offline Mode Option
          _MenuOptionTile(
            icon: Icons.cloud_off,
            title: 'Offline Mode',
            subtitle: 'Disable automatic sync. Data stays on this device.',
            isSelected: syncMode == SyncMode.offline,
            onTap: () {
              ref.read(syncModeProvider.notifier).requestModeChange(SyncMode.offline);
              onCloseMenu();
            },
          ),

          // 2. Cloud Sync Option
          _MenuOptionTile(
            icon: Icons.cloud_queue,
            title: 'Cloud Sync',
            subtitle: 'Sync notes securely across devices via Firebase Cloud.',
            isSelected: syncMode == SyncMode.cloud,
            onTap: () {
              ref.read(syncModeProvider.notifier).requestModeChange(SyncMode.cloud);
              onCloseMenu();
            },
          ),

          // 3. Local Network Sync Option
          _MenuOptionTile(
            icon: Icons.wifi,
            title: 'Local Network Sync',
            subtitle: 'Sync notes directly over Wi-Fi without cloud servers.',
            isSelected: syncMode.isLocal,
            onTap: () {
              onCloseMenu();

              // If already in Local Sync, navigate to appropriate sub-screen based on state/role
              if (syncMode.isLocal) {
                if (syncMode.isHost || isHosting) {
                  ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.hostMode);
                } else if (syncMode.isClient) {
                  ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.clientMode);
                } else {
                  ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.localSync);
                }
              } else {
                // First-time selecting local sync: open local sync role selector
                ref.read(syncModeProvider.notifier).requestModeChange(SyncMode.localUndefined);
                ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.localSync);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MenuOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
