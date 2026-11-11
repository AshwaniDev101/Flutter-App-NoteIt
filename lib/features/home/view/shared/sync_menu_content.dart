import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_engine.dart';
import '../../../../core/sync/sync_orchestrator.dart';
import '../../../../shared/overlays/snack_bar_manager.dart';

class SyncMenuContent extends ConsumerWidget {
  final VoidCallback onCloseMenu;

  const SyncMenuContent({
    super.key,
    required this.onCloseMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncMode = ref.watch(syncModeProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 4.0, bottom: 8.0, right: 12.0),
            child: Text(
              'Select Sync Mode',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildOptionTile(
            context: context,
            ref: ref,
            title: 'Cloud',
            subtitle: 'Sync notes across devices using cloud storage',
            icon: Icons.cloud_outlined,
            isSelected: syncMode.isCloud,
            onTap: () async {
              onCloseMenu();
              final success = await ref.read(syncModeProvider.notifier).requestModeChange(SyncMode.cloud);
              if (success) {
                SnackBarManager.show(
                  msg: 'Switched to Cloud Sync',
                  type: SnackBarMessageType.info,
                );
              }
            },
          ),
          _buildOptionTile(
            context: context,
            ref: ref,
            title: 'Local Router',
            subtitle: 'Sync notes directly with devices on your local network',
            icon: Icons.wifi,
            isSelected: syncMode.isLocal,
            onTap: () async {
              onCloseMenu();
              final targetMode = syncMode.isLocal ? syncMode : SyncMode.localUndefined;
              await ref.read(syncModeProvider.notifier).requestModeChange(targetMode);
              SnackBarManager.show(
                msg: 'Switched to Local Sync',
                type: SnackBarMessageType.info,
              );
            },
          ),
          _buildOptionTile(
            context: context,
            ref: ref,
            title: 'Offline',
            subtitle: 'Keep all notes stored only on this device',
            icon: Icons.signal_wifi_off,
            isSelected: syncMode.isOffline,
            onTap: () async {
              onCloseMenu();
              await ref.read(syncModeProvider.notifier).requestModeChange(SyncMode.offline);
              SnackBarManager.show(
                msg: 'Switched to Offline Mode',
                type: SnackBarMessageType.info,
              );
            },
          ),
          if (syncMode.isSyncing) ...[
            const Divider(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: TextButton.icon(
                onPressed: () {
                  onCloseMenu();
                  ref.read(syncOrchestratorProvider).triggerSync();
                  SnackBarManager.show(
                    msg: 'Syncing notes...',
                    type: SnackBarMessageType.info,
                  );
                },
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Force Sync Now'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.35) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
