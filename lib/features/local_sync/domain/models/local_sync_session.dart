import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/local_sync/data/network/local_sync_service.dart';

/// Immutable data snapshot representing the live state of a Local P2P Wi-Fi Sync Session.
class LocalSyncSession {
  final SyncConnectionState connectionState;
  final SyncRole activeRole;
  final String? peerUuid;
  final String? peerName;
  final String? peerPlatform;
  final DateTime? connectedAt;
  final int latencyMs;
  final bool isSyncing;
  final String? errorMessage;

  const LocalSyncSession({
    this.connectionState = SyncConnectionState.disconnected,
    this.activeRole = SyncRole.undefine,
    this.peerUuid,
    this.peerName,
    this.peerPlatform,
    this.connectedAt,
    this.latencyMs = 0,
    this.isSyncing = false,
    this.errorMessage,
  });

  bool get isConnected => connectionState == SyncConnectionState.connected;

  Duration? get sessionDuration =>
      connectedAt != null ? DateTime.now().difference(connectedAt!) : null;

  LocalSyncSession copyWith({
    SyncConnectionState? connectionState,
    SyncRole? activeRole,
    String? peerUuid,
    String? peerName,
    String? peerPlatform,
    DateTime? connectedAt,
    int? latencyMs,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return LocalSyncSession(
      connectionState: connectionState ?? this.connectionState,
      activeRole: activeRole ?? this.activeRole,
      peerUuid: peerUuid ?? this.peerUuid,
      peerName: peerName ?? this.peerName,
      peerPlatform: peerPlatform ?? this.peerPlatform,
      connectedAt: connectedAt ?? this.connectedAt,
      latencyMs: latencyMs ?? this.latencyMs,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalSyncSession &&
          runtimeType == other.runtimeType &&
          connectionState == other.connectionState &&
          activeRole == other.activeRole &&
          peerUuid == other.peerUuid &&
          peerName == other.peerName &&
          peerPlatform == other.peerPlatform &&
          connectedAt == other.connectedAt &&
          latencyMs == other.latencyMs &&
          isSyncing == other.isSyncing &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      connectionState.hashCode ^
      activeRole.hashCode ^
      peerUuid.hashCode ^
      peerName.hashCode ^
      peerPlatform.hashCode ^
      connectedAt.hashCode ^
      latencyMs.hashCode ^
      isSyncing.hashCode ^
      errorMessage.hashCode;

  @override
  String toString() {
    return 'LocalSyncSession(state: $connectionState, role: $activeRole, peer: $peerName ($peerPlatform), latency: ${latencyMs}ms, syncing: $isSyncing)';
  }
}
