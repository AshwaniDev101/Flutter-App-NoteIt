import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/local_sync/data/network/local_sync_service.dart';
import 'package:noteit/features/local_sync/data/network/mdns_broadcast.dart';
import 'package:noteit/features/local_sync/data/network/mdns_searcher.dart';
import 'package:noteit/features/local_sync/data/providers/sync_client_provider.dart';
import 'package:noteit/features/local_sync/domain/models/local_sync_session.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final localSyncSessionProvider =
    NotifierProvider<LocalSyncSessionManager, LocalSyncSession>(() {
  return LocalSyncSessionManager();
});

class LocalSyncSessionManager extends Notifier<LocalSyncSession> {
  @override
  LocalSyncSession build() {
    ref.onDispose(() {
      endSession();
    });

    final currentRole = ref.watch(sharedPreferenceProvider).syncRole;
    return LocalSyncSession(
      activeRole: currentRole,
      connectionState: SyncConnectionState.disconnected,
    );
  }

  /// Called when a P2P WebSocket handshake completes successfully.
  /// Sets up session metadata and establishes the active traffic channel.
  void establishSession({
    required WebSocketChannel channel,
    required SyncRole role,
    required String peerUuid,
    required String peerName,
    required String peerPlatform,
  }) {
    AppLogger.d('LocalSyncSessionManager: Establishing P2P Session with $peerName ($peerPlatform) as $role');

    // Update session state snapshot
    state = state.copyWith(
      connectionState: SyncConnectionState.connected,
      activeRole: role,
      peerUuid: peerUuid,
      peerName: peerName,
      peerPlatform: peerPlatform,
      connectedAt: DateTime.now(),
      errorMessage: null,
    );

    // Pass socket to traffic controller
    ref.read(localSyncServiceProvider.notifier).setActiveConnection(channel);
  }

  /// Updates sync activity status (active note/folder payloads transferring)
  void setSyncing(bool isSyncing) {
    if (state.isSyncing != isSyncing) {
      state = state.copyWith(isSyncing: isSyncing);
    }
  }

  /// Updates connection status (e.g. ghostDetected, reconnecting, error)
  void updateConnectionState(SyncConnectionState connectionState, {String? errorMessage}) {
    if (state.connectionState != connectionState || state.errorMessage != errorMessage) {
      state = state.copyWith(
        connectionState: connectionState,
        errorMessage: errorMessage,
      );
    }
  }

  /// ATOMIC TEARDOWN: Cleanly terminates the active session and shuts down
  /// all underlying sockets, timers, servers, and mDNS broadcasts in one operation.
  void endSession({
    SyncConnectionState reason = SyncConnectionState.disconnected,
  }) {
    if (state.connectionState == SyncConnectionState.disconnected &&
        state.peerUuid == null) {
      return; // Already cleanly disconnected
    }

    AppLogger.d('LocalSyncSessionManager: Ending session (Reason: $reason)...');

    // 1. Stop traffic controller socket & timers
    ref.read(localSyncServiceProvider.notifier).stop(reason: reason);

    // 2. Shut down dialer channel if active
    ref.read(syncClientProvider.notifier).disconnect();

    // 3. Stop mDNS searcher & broadcast
    ref.read(mdnsSearcherProvider.notifier).stopScan();
    ref.read(mdnsBroadcastProvider.notifier).stopBroadcasting();

    // 4. Reset immutable session state
    state = LocalSyncSession(
      connectionState: reason,
      activeRole: ref.read(sharedPreferenceProvider).syncRole,
    );
  }
}
