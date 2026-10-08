import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/view/shared/icon_tray/spinning_sync_icon.dart';
import 'package:noteit/features/home/view/shared/icon_tray/websocket_connection_indicator.dart';

import '../../../../../database/sync/sync_orchestrator.dart';
import 'mdns_broadcast_indicator.dart';
import 'mdns_search_indicator.dart';

class IconTray extends ConsumerWidget {
  const IconTray({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = ref.watch(isSyncingProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // mDNS Activity (Radar scanning or signal broadcasting)
        // They will automatically appear/disappear and slide out of the way
        const MdnsSearchIndicator(),
        const MdnsBroadcastIndicator(),
        const SizedBox(width: 6),

        // Live WebSocket connection status
        const WebSocketConnectionIndicator(),

        // Sync Trigger & Spinner
        IconButton(
          icon: SpinningSyncIcon(
            isSyncing: isSyncing,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: 'Sync Notes',
          onPressed: () {
            ref.read(syncOrchestratorProvider).triggerSync();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Syncing notes...')),
            );
          },
        ),
      ],
    );
  }
}