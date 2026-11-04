import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/core/sync/sync_orchestrator.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'package:noteit/features/home/view/shared/icon_tray/spinning_sync_icon.dart';
import 'package:noteit/features/local_sync/data/network/local_sync_service.dart';
import 'package:noteit/features/local_sync/data/network/mdns_searcher.dart';
import 'package:noteit/features/local_sync/data/providers/sync_server_provider.dart';
import 'package:noteit/shared/overlays/snack_bar_manager.dart';

/// Enumeration of all visual display states for the sync badge.
enum _SyncDisplayState {
  offline(
    label: 'Offline',
    icon: Icons.cloud_off,
    color: Colors.grey,
    tooltip: 'Sync is disabled in Offline mode',
    isActionable: false,
  ),
  unauthenticated(
    label: 'Not Synced',
    icon: Icons.account_circle_outlined,
    color: Colors.orangeAccent,
    tooltip: 'Sign in to enable Cloud Sync',
    isActionable: true,
  ),
  hosting(
    label: 'Hosting...',
    icon: Icons.wifi_tethering_rounded,
    color: Colors.white,
    tooltip: 'Host server running, waiting for peer...',
    isActionable: false,
  ),
  searching(
    label: 'Searching...',
    icon: Icons.radar_rounded,
    color: Colors.cyanAccent,
    tooltip: 'Searching local network for Hosts...',
    isActionable: false,
  ),
  disconnected(
    label: 'Disconnected',
    icon: Icons.link_off_rounded,
    color: Colors.grey,
    tooltip: 'Disconnected from Host. Tap to open Host Searcher.',
    isActionable: true,
  ),
  reconnecting(
    label: 'Reconnecting...',
    icon: Icons.change_circle_outlined,
    color: Colors.amberAccent,
    tooltip: 'Connection lost, attempting reconnect...',
    isActionable: false,
  ),
  syncing(
    label: 'Syncing...',
    icon: Icons.sync,
    color: Colors.blueAccent,
    tooltip: 'Synchronizing notes...',
    isActionable: false,
  ),
  synced(
    label: 'Synced',
    icon: Icons.check_circle,
    color: Colors.greenAccent,
    tooltip: 'All notes are up to date. Tap to force sync.',
    isActionable: true,
  );

  final String label;
  final IconData icon;
  final Color color;
  final String tooltip;
  final bool isActionable;

  const _SyncDisplayState({
    required this.label,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.isActionable,
  });
}

/// Single self-contained status widget for note synchronization.
class SyncStateWidget extends ConsumerWidget {
  const SyncStateWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncMode = ref.watch(syncModeProvider);
    final isAuthenticated = ref.watch(authStateProvider).value != null;
    final localSyncState = ref.watch(localSyncServiceProvider);
    final isHosting = ref.watch(syncServerProvider) != null;
    final isSyncing = ref.watch(isSyncingProvider);
    final isSearching = ref.watch(mdnsSearcherProvider).status == ScanStatus.scanning;

    final displayState = _evaluateState(
      syncMode: syncMode,
      isAuthenticated: isAuthenticated,
      localSyncState: localSyncState,
      isHosting: isHosting,
      isSyncing: isSyncing,
      isSearching: isSearching,
    );

    return Tooltip(
      message: displayState.tooltip,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Container(
          key: ValueKey(displayState),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: displayState.isActionable
                  ? () => _handleTap(context, ref, displayState)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIcon(displayState),
                      const SizedBox(width: 6),
                      Text(
                        displayState.label,
                        style: TextStyle(
                          color: displayState.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _SyncDisplayState _evaluateState({
    required SyncMode syncMode,
    required bool isAuthenticated,
    required SyncConnectionState localSyncState,
    required bool isHosting,
    required bool isSyncing,
    required bool isSearching,
  }) {
    final state = _calculateState(
      syncMode: syncMode,
      isAuthenticated: isAuthenticated,
      localSyncState: localSyncState,
      isHosting: isHosting,
      isSyncing: isSyncing,
      isSearching: isSearching,
    );

    AppLogger.d(
      'SyncStateWidget: State -> ${state.name} [mode: $syncMode, auth: $isAuthenticated, localState: $localSyncState, hosting: $isHosting, syncing: $isSyncing, searching: $isSearching]',
    );

    return state;
  }

  _SyncDisplayState _calculateState({
    required SyncMode syncMode,
    required bool isAuthenticated,
    required SyncConnectionState localSyncState,
    required bool isHosting,
    required bool isSyncing,
    required bool isSearching,
  }) {
    // 1. Offline Mode
    if (syncMode.isOffline) {
      return _SyncDisplayState.offline;
    }

    // 2. Cloud Mode
    if (syncMode.isCloud) {
      if (!isAuthenticated) {
        return _SyncDisplayState.unauthenticated;
      }
      if (isSyncing) {
        return _SyncDisplayState.syncing;
      }
      return _SyncDisplayState.synced;
    }

    // 3. Local Mode
    if (syncMode.isLocal) {
      if (isSyncing) {
        return _SyncDisplayState.syncing;
      }
      if (localSyncState == SyncConnectionState.reconnecting ||
          localSyncState == SyncConnectionState.connecting ||
          localSyncState == SyncConnectionState.ghostDetected) {
        return _SyncDisplayState.reconnecting;
      }
      if (isHosting && localSyncState != SyncConnectionState.connected) {
        return _SyncDisplayState.hosting;
      }
      if (localSyncState == SyncConnectionState.connected) {
        return _SyncDisplayState.synced;
      }
      if (isSearching) {
        return _SyncDisplayState.searching;
      }
      if (!isHosting && localSyncState == SyncConnectionState.disconnected) {
        return _SyncDisplayState.disconnected;
      }
      return _SyncDisplayState.offline;
    }

    return _SyncDisplayState.offline;
  }

  Widget _buildIcon(_SyncDisplayState displayState) {
    if (displayState == _SyncDisplayState.syncing) {
      return SpinningSyncIcon(
        isSyncing: true,
        color: displayState.color,
      );
    }

    return Icon(
      displayState.icon,
      size: 18,
      color: displayState.color,
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    _SyncDisplayState displayState,
  ) {
    AppLogger.d('SyncStateWidget: User tapped badge in state ${displayState.name}');

    if (displayState == _SyncDisplayState.disconnected) {
      ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.clientMode);
      return;
    }

    if (displayState == _SyncDisplayState.unauthenticated) {
      SnackBarManager.show(
        msg: 'Please sign in with Google to enable Cloud Sync',
        type: SnackBarMessageType.info,
      );
      ref.read(syncModeProvider.notifier).requestModeChange(SyncMode.cloud);
      return;
    }

    if (displayState == _SyncDisplayState.synced) {
      ref.read(syncOrchestratorProvider).triggerSync();
      SnackBarManager.show(
        msg: 'Syncing notes...',
        type: SnackBarMessageType.info,
      );
      return;
    }
  }
}
