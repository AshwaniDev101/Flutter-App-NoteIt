import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/core/sync/sync_orchestrator.dart';
import 'package:noteit/core/theme/sync_status_colors.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'package:noteit/features/home/view/shared/icon_tray/spinning_sync_icon.dart';
import 'package:noteit/features/local_sync/data/network/local_sync_service.dart';
import 'package:noteit/features/local_sync/data/network/mdns_searcher.dart';
import 'package:noteit/features/local_sync/data/providers/sync_server_provider.dart';
import 'package:noteit/shared/menus/app_bottom_sheet.dart';
import 'package:noteit/shared/overlays/snack_bar_manager.dart';
import 'sync_menu_content.dart';

/// Enumeration of all visual display states for the sync badge.
enum SyncDisplayState {
  offline(
    label: 'Offline',
    icon: Icons.cloud_off,
    tooltip: 'Sync is disabled in Offline mode. Tap to select Sync mode.',
    isActionable: true,
  ),
  unauthenticated(
    label: 'Not Synced',
    icon: Icons.account_circle_outlined,
    tooltip: 'Sign in to enable Cloud Sync',
    isActionable: true,
  ),
  hosting(
    label: 'Hosting...',
    icon: Icons.wifi,
    tooltip: 'Host server running, waiting for peer...',
    isActionable: true,
  ),
  searching(
    label: 'Scanning...',
    icon: Icons.search_rounded,
    tooltip: 'Searching local network for Hosts...',
    isActionable: false,
  ),
  disconnected(
    label: 'Disconnected',
    icon: Icons.link_off_rounded,
    tooltip: 'Disconnected from Host. Tap to open Host Searcher.',
    isActionable: true,
  ),
  reconnecting(
    label: 'Reconnecting...',
    icon: Icons.change_circle_outlined,
    tooltip: 'Connection lost, attempting reconnect...',
    isActionable: false,
  ),
  syncing(
    label: 'Syncing...',
    icon: Icons.sync,
    tooltip: 'Synchronizing notes...',
    isActionable: false,
  ),
  synced(
    label: 'Synced',
    icon: Icons.check_circle,
    tooltip: 'All notes are up to date. Tap to force sync.',
    isActionable: true,
  );

  final String label;
  final IconData icon;
  final String tooltip;
  final bool isActionable;

  const SyncDisplayState({
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.isActionable,
  });

  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<SyncStatusColors>();
    if (ext != null) {
      switch (this) {
        case SyncDisplayState.synced:
          return ext.synced;
        case SyncDisplayState.syncing:
          return ext.syncing;
        case SyncDisplayState.hosting:
          return ext.hosting;
        case SyncDisplayState.searching:
          return ext.searching;
        case SyncDisplayState.reconnecting:
          return ext.reconnecting;
        case SyncDisplayState.unauthenticated:
          return ext.unauthenticated;
        case SyncDisplayState.disconnected:
          return ext.disconnected;
        case SyncDisplayState.offline:
          return ext.offline;
      }
    }
    return theme.colorScheme.onSurfaceVariant;
  }
}

/// Calculated visual display info including state enum and dynamic tooltip.
@immutable
class SyncDisplayInfo {
  final SyncDisplayState state;
  final String tooltip;

  const SyncDisplayInfo({
    required this.state,
    required this.tooltip,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncDisplayInfo &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          tooltip == other.tooltip;

  @override
  int get hashCode => state.hashCode ^ tooltip.hashCode;
}

/// Pure state calculation function for sync display info.
SyncDisplayInfo calculateSyncDisplayInfo({
  required SyncMode syncMode,
  required bool isAuthenticated,
  required SyncConnectionState localSyncState,
  required bool isHosting,
  required bool isSyncing,
  required bool isSearching,
}) {
  // 1. Offline Mode
  if (syncMode.isOffline) {
    return SyncDisplayInfo(
      state: SyncDisplayState.offline,
      tooltip: SyncDisplayState.offline.tooltip,
    );
  }

  // 2. Cloud Mode
  if (syncMode.isCloud) {
    if (!isAuthenticated) {
      return SyncDisplayInfo(
        state: SyncDisplayState.unauthenticated,
        tooltip: SyncDisplayState.unauthenticated.tooltip,
      );
    }
    if (isSyncing) {
      return const SyncDisplayInfo(
        state: SyncDisplayState.syncing,
        tooltip: 'Synchronizing notes with Cloud...',
      );
    }
    return const SyncDisplayInfo(
      state: SyncDisplayState.synced,
      tooltip: 'All notes synced with Cloud. Tap to force sync.',
    );
  }

  // 3. Local Mode
  if (syncMode.isLocal) {
    // 3a. Connection recovery takes highest priority over transfers
    if (localSyncState == SyncConnectionState.reconnecting ||
        localSyncState == SyncConnectionState.connecting ||
        localSyncState == SyncConnectionState.ghostDetected) {
      return SyncDisplayInfo(
        state: SyncDisplayState.reconnecting,
        tooltip: SyncDisplayState.reconnecting.tooltip,
      );
    }

    // 3b. Active transfer (only when connection is healthy)
    if (isSyncing) {
      return const SyncDisplayInfo(
        state: SyncDisplayState.syncing,
        tooltip: 'Synchronizing notes locally...',
      );
    }

    // 3c. Host Role Handling
    if (syncMode.isHost || isHosting) {
      if (localSyncState == SyncConnectionState.connected) {
        return const SyncDisplayInfo(
          state: SyncDisplayState.synced,
          tooltip: 'Synced with local client. Tap to force sync.',
        );
      }
      return SyncDisplayInfo(
        state: SyncDisplayState.hosting,
        tooltip: SyncDisplayState.hosting.tooltip,
      );
    }

    // 3d. Client Role Handling
    if (syncMode.isClient) {
      if (localSyncState == SyncConnectionState.connected) {
        return const SyncDisplayInfo(
          state: SyncDisplayState.synced,
          tooltip: 'Synced with Host. Tap to force sync.',
        );
      }
      if (isSearching) {
        return SyncDisplayInfo(
          state: SyncDisplayState.searching,
          tooltip: SyncDisplayState.searching.tooltip,
        );
      }
      return SyncDisplayInfo(
        state: SyncDisplayState.disconnected,
        tooltip: SyncDisplayState.disconnected.tooltip,
      );
    }

    // 3e. Undefined Role Handling
    if (syncMode == SyncMode.localUndefined) {
      return const SyncDisplayInfo(
        state: SyncDisplayState.disconnected,
        tooltip: 'Local Sync enabled. Tap to select Host or Client role.',
      );
    }
  }

  return SyncDisplayInfo(
    state: SyncDisplayState.offline,
    tooltip: SyncDisplayState.offline.tooltip,
  );
}

/// Derived Riverpod provider computing [SyncDisplayInfo] with fine-grained reactivity filters.
final syncDisplayInfoProvider = Provider<SyncDisplayInfo>((ref) {
  final syncMode = ref.watch(syncModeProvider);
  final isAuthenticated = ref.watch(authStateProvider.select((a) => a.unwrapPrevious().value != null));
  final localSyncState = ref.watch(localSyncServiceProvider);
  final isHosting = ref.watch(syncServerProvider.select((s) => s != null));
  final isSyncing = ref.watch(isSyncingProvider);
  final isSearching = ref.watch(mdnsSearcherProvider.select((s) => s.status == ScanStatus.scanning));

  final info = calculateSyncDisplayInfo(
    syncMode: syncMode,
    isAuthenticated: isAuthenticated,
    localSyncState: localSyncState,
    isHosting: isHosting,
    isSyncing: isSyncing,
    isSearching: isSearching,
  );

  AppLogger.d(
    'SyncStateWidget: State -> ${info.state.name} [mode: $syncMode, auth: $isAuthenticated, localState: $localSyncState, hosting: $isHosting, syncing: $isSyncing, searching: $isSearching]',
  );

  return info;
});

/// Single self-contained status widget for note synchronization.
class SyncStateWidget extends ConsumerStatefulWidget {
  const SyncStateWidget({super.key});

  @override
  ConsumerState<SyncStateWidget> createState() => _SyncStateWidgetState();
}

class _SyncStateWidgetState extends ConsumerState<SyncStateWidget> {
  final MenuController _menuController = MenuController();

  void _showMobileBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (bottomSheetContext, setModalState) {
        return SyncMenuContent(
          onCloseMenu: () => Navigator.of(bottomSheetContext).pop(),
        );
      },
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    SyncDisplayState displayState,
  ) {
    final syncMode = ref.read(syncModeProvider);
    AppLogger.d('SyncStateWidget: User tapped badge in state ${displayState.name} (mode: $syncMode)');

    // 1. Offline Mode -> Open Sync Engine Selector Menu
    if (displayState == SyncDisplayState.offline) {
      if (!PlatformHelper.isWideLayout(context)) {
        _showMobileBottomSheet(context);
      } else {
        if (_menuController.isOpen) {
          _menuController.close();
        } else {
          _menuController.open();
        }
      }
      return;
    }

    // 2. Undefined Role -> Role Selector Page
    if (syncMode == SyncMode.localUndefined) {
      ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.localSync);
      return;
    }

    // 3. Host waiting / Host error -> Host Broadcaster Screen
    if (displayState == SyncDisplayState.hosting ||
        (syncMode.isHost && displayState == SyncDisplayState.disconnected)) {
      ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.hostMode);
      return;
    }

    // 4. Client disconnected / Client error -> Host Searcher Screen
    if (displayState == SyncDisplayState.disconnected) {
      ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.clientMode);
      return;
    }

    // 5. Unauthenticated Cloud Mode -> Google Sign In
    if (displayState == SyncDisplayState.unauthenticated) {
      SnackBarManager.show(
        msg: 'Please sign in with Google to enable Cloud Sync',
        type: SnackBarMessageType.info,
      );
      ref.read(syncModeProvider.notifier).requestModeChange(SyncMode.cloud);
      return;
    }

    // 6. Synced -> Force Sync
    if (displayState == SyncDisplayState.synced) {
      ref.read(syncOrchestratorProvider).triggerSync();
      SnackBarManager.show(
        msg: 'Syncing notes...',
        type: SnackBarMessageType.info,
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayInfo = ref.watch(syncDisplayInfoProvider);
    final displayState = displayInfo.state;
    final statusColor = displayState.getColor(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = !PlatformHelper.isWideLayout(context);

    final badgeWidget = Tooltip(
      message: displayInfo.tooltip,
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
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
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
                      _buildIcon(displayState, statusColor),
                      const SizedBox(width: 6),
                      Text(
                        displayState.label,
                        style: TextStyle(
                          color: statusColor,
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

    if (isMobile) {
      return badgeWidget;
    }

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, 8),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return badgeWidget;
      },
      menuChildren: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.all(4),
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 340,
            child: SyncMenuContent(
              onCloseMenu: () {
                if (_menuController.isOpen) _menuController.close();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(SyncDisplayState displayState, Color statusColor) {
    if (displayState == SyncDisplayState.syncing) {
      return SpinningSyncIcon(
        isSyncing: true,
        color: statusColor,
      );
    }

    return Icon(
      displayState.icon,
      size: 18,
      color: statusColor,
    );
  }
}
