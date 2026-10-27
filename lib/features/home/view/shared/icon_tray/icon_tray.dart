import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import 'package:noteit/database/sync/local_sync_service.dart';
import 'package:noteit/features/home/view/shared/icon_tray/spinning_sync_icon.dart';
import 'package:noteit/features/home/view/shared/icon_tray/websocket_connection_indicator.dart';

import '../../../../../database/sync/sync_engine.dart';
import '../../../../../database/sync/sync_orchestrator.dart';
import '../../../../../shared/overlays/snack_bar_manager.dart';
import 'mdns_broadcast_indicator.dart';
import 'mdns_search_indicator.dart';

/// ============================================================================
/// MASTER BUTTON VISIBILITY POLICY MATRIX
/// ============================================================================
/// | SyncEngine Mode   | App/Connection State      | mDNS Broadcast/Search | WebSocket Indicator | Sync Trigger Button |
/// | :---------------- | :------------------------ | :-------------------- | :------------------ | :------------------ |
/// | SyncEngine.offline| Any                       | Hidden                | Hidden              | Hidden              |
/// | SyncEngine.cloud  | Unauthenticated           | Hidden                | Hidden              | Hidden              |
/// | SyncEngine.cloud  | Authenticated             | Hidden                | Hidden              | Visible             |
/// | SyncEngine.local  | Standby / Disconnected    | Visible (if active)   | Hidden              | Hidden              |
/// | SyncEngine.local  | Hosting (Server running)  | Visible (if active)   | Visible (hosting)   | Hidden              |
/// | SyncEngine.local  | Connected to Peer         | Visible (if active)   | Visible (connected) | Visible             |
/// | Any Mode          | Sync In Progress          | Visible (if active)   | Visible (connected) | Visible             |
/// ============================================================================
class IconTray extends ConsumerWidget {
  const IconTray({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncEngine = ref.watch(syncEngineProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final isLocalConnected = ref.watch(localSyncServiceProvider) == SyncConnectionState.connected;
    final isAuthenticated = ref.watch(authStateProvider).value != null;

    // --- BUTTON VISIBILITY POLICY ---
    // The Sync button should only be visible when sync can actually be executed:
    // 1. In Local Sync mode: ONLY if actively connected to a peer over WebSocket.
    // 2. In Cloud Sync mode: ONLY if user is authenticated with Firebase.
    // 3. Or if a sync is currently in progress (so the user sees the spinner).
    final bool canTriggerSync = (syncEngine == SyncEngine.cloud && isAuthenticated) ||
        (syncEngine == SyncEngine.local && isLocalConnected);

    final bool showSyncButton = canTriggerSync || isSyncing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // mDNS Activity & WebSocket Status - Strictly relevant in Local Sync mode
        if (syncEngine == SyncEngine.local) ...[
          const MdnsBroadcastIndicator(),
          const MdnsSearchIndicator(),
          const WebSocketConnectionIndicator(),
        ],

        // Sync Trigger & Spinner (Only visible when sync is actually actionable or in-progress)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: showSyncButton
              ? Row(
                  key: const ValueKey('sync_button_group'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    IconButton(
                      icon: SpinningSyncIcon(isSyncing: isSyncing),
                      tooltip: 'Sync Notes',
                      onPressed: () {
                        ref.read(syncOrchestratorProvider).triggerSync();
                        SnackBarManager.show(
                          msg: 'Syncing notes...',
                          type: SnackBarMessageType.info,
                        );
                      },
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
