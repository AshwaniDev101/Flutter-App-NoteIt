import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/view/shared/icon_tray/spinning_sync_icon.dart';
import 'package:noteit/features/home/view/shared/icon_tray/websocket_connection_indicator.dart';

import '../../../../../database/sync/local_sync_service.dart';
import '../../../../../database/sync/sync_orchestrator.dart';

class IconTray extends ConsumerWidget {
  const IconTray({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final isSyncing = ref.watch(isSyncingProvider);
    final isConnected = ref.watch(localSyncServiceProvider) == SyncConnectionState.connected;

    return Row(
      children: [
        WebSocketConnectionIndicator(isConnected: isConnected),
        IconButton(
          // icon: const Icon(Icons.sync),
          icon: SpinningSyncIcon(isSyncing: isSyncing, color: Theme.of(context).colorScheme.primary),
          tooltip: 'Sync Notes',
          onPressed: () {
            ref.read(syncOrchestratorProvider).triggerSync();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing notes...')));
          },
        ),
      ],
      // SpinningSyncIcon(isSyncing: isSyncing, color: Theme.of(context).colorScheme.primary)],
    );
  }
}
