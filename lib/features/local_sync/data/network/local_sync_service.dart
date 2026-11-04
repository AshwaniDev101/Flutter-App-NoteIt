import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/core/sync/sync_orchestrator.dart';
import 'package:noteit/features/local_sync/data/processors/folder_sync_processor.dart';
import 'package:noteit/features/local_sync/data/processors/note_sync_processor.dart';
import 'package:noteit/features/local_sync/data/processors/sync_entity_processor.dart';
import 'package:noteit/features/local_sync/data/providers/local_sync_session_manager.dart';
import 'package:noteit/features/local_sync/data/providers/sync_client_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:noteit/core/util/logger.dart';

enum SyncConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  ghostDetected,
  error,
}

final localSyncServiceProvider =
    NotifierProvider<LocalSyncNotifier, SyncConnectionState>(() {
      return LocalSyncNotifier();
    });

class LocalSyncNotifier extends Notifier<SyncConnectionState> {
  WebSocketChannel? _activeChannel;
  StreamSubscription? _streamSubscription;

  Timer? _heartbeatTimer;
  DateTime? _lastPingSentTime;
  DateTime? _lastActivityTime;
  Completer<bool>? _probeCompleter;
  int _latencyMs = 0;

  int get latencyMs => _latencyMs;

  List<SyncEntityProcessor> get _processors => [
        ref.read(folderSyncProcessorProvider),
        ref.read(noteSyncProcessorProvider),
      ];

  @override
  SyncConnectionState build() {
    ref.onDispose(() => stop());
    return SyncConnectionState.disconnected;
  }

  void setStatus(SyncConnectionState status) {
    state = status;
  }

  void _closeActiveResources() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _lastPingSentTime = null;
    _lastActivityTime = null;
    _latencyMs = 0;

    if (_probeCompleter != null && !_probeCompleter!.isCompleted) {
      _probeCompleter!.complete(false);
      _probeCompleter = null;
    }

    _streamSubscription?.cancel();
    _streamSubscription = null;

    if (_activeChannel != null) {
      try {
        _activeChannel?.sink.add(jsonEncode({'type': 'disconnect'}));
      } catch (_) {}
      try {
        _activeChannel?.sink.close();
      } catch (_) {}
      _activeChannel = null;
    }
  }

  void stop({SyncConnectionState reason = SyncConnectionState.disconnected}) {
    AppLogger.d("LocalSyncService: Shutting down Local Wi-Fi Sync ($reason).");
    _closeActiveResources();

    if (state != reason) {
      state = reason;
    }
    ref.read(localSyncSessionProvider.notifier).updateConnectionState(reason);
  }

  void setActiveConnection(WebSocketChannel channel) {
    // Clean up previous channel resources cleanly without triggering session teardown
    _closeActiveResources();

    _activeChannel = channel;
    _lastActivityTime = DateTime.now();
    state = SyncConnectionState.connected;

    AppLogger.d("LocalSyncService: Active connection established!");

    _streamSubscription = _activeChannel!.stream.listen(
      (message) => _handleIncomingSyncPayload(message),
      onDone: () {
        AppLogger.d("LocalSyncService: Disconnected from peer (stream closed).");
        stop();
      },
      onError: (e) {
        AppLogger.e("LocalSyncService: WebSocket Error", error: e);
        stop();
      },
    );

    _startHeartbeatTimer();

    // Broadcast local changes immediately upon connecting
    broadcastLocalChanges();
  }

  /// Starts a periodic 5-second timer checking for idle time and ghost sockets
  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_activeChannel == null || state != SyncConnectionState.connected) {
        _heartbeatTimer?.cancel();
        return;
      }

      final now = DateTime.now();
      final lastActivity = _lastActivityTime ?? now;
      final idleDuration = now.difference(lastActivity);

      // 1. GHOST SOCKET DETECTION: No activity or pong for 15+ seconds
      if (idleDuration >= const Duration(seconds: 15)) {
        AppLogger.w("LocalSyncService: Ghost connection detected (no ping/pong response in 15s). Shutting down.");
        stop(reason: SyncConnectionState.ghostDetected);
        return;
      }

      // 2. IDLE PING: If idle for 10+ seconds and no pending ping, send ping
      if (idleDuration >= const Duration(seconds: 10) && _lastPingSentTime == null) {
        _sendPing();
      }
    });
  }

  void _sendPing() {
    if (_activeChannel == null) return;
    try {
      final now = DateTime.now();
      _lastPingSentTime = now;
      final pingPayload = jsonEncode({
        'type': 'ping',
        'ts': now.millisecondsSinceEpoch,
      });
      _activeChannel!.sink.add(pingPayload);
    } catch (e) {
      AppLogger.w("LocalSyncService: Failed to send ping: $e");
      stop();
    }
  }

  /// Probe socket health actively (e.g. on app resume). Returns true if peer responds within timeout.
  Future<bool> probeConnection({Duration timeout = const Duration(seconds: 2)}) async {
    if (_activeChannel == null || state != SyncConnectionState.connected) {
      return false;
    }

    if (_probeCompleter != null && !_probeCompleter!.isCompleted) {
      _probeCompleter!.complete(false);
    }

    final completer = Completer<bool>();
    _probeCompleter = completer;

    _sendPing();

    try {
      final result = await completer.future.timeout(timeout, onTimeout: () {
        AppLogger.w("LocalSyncService: Active connection probe timed out after ${timeout.inSeconds}s.");
        return false;
      });
      return result;
    } catch (_) {
      return false;
    } finally {
      if (_probeCompleter == completer) {
        _probeCompleter = null;
      }
    }
  }

  /// Broadcast pending local changes across all entity processors in dependency order (Folders -> Notes)
  Future<void> broadcastLocalChanges() async {
    if (_activeChannel == null) {
      final isClientMode = ref.read(syncModeProvider).isClient;
      if (isClientMode) {
        AppLogger.d("LocalSyncService: Save detected while disconnected. Running auto-connect protocol...");
        final reconnected = await ref.read(syncClientProvider.notifier).autoConnectToPairedHost();
        if (!reconnected || _activeChannel == null) {
          AppLogger.d("LocalSyncService: Save detected, but host unreachable. Saved locally.");
          return;
        }
      } else {
        AppLogger.d("LocalSyncService: Save detected, but no active Wi-Fi connection. Waiting.");
        return;
      }
    }

    ref.read(isSyncingProvider.notifier).setSyncing(true);
    ref.read(localSyncSessionProvider.notifier).setSyncing(true);

    try {
      for (final processor in _processors) {
        final pendingItems = await processor.getPendingLocalChanges();

        if (pendingItems.isEmpty) continue;

        final payload = jsonEncode({
          'type': processor.batchType,
          'data': pendingItems,
        });

        _activeChannel!.sink.add(payload);
        _lastActivityTime = DateTime.now();
        AppLogger.d("LocalSyncService: Broadcasted batch of ${pendingItems.length} '${processor.entityName}' items over Wi-Fi.");
      }
    } catch (e, st) {
      AppLogger.e("LocalSyncService: Broadcast Failed", error: e, stack: st);
      stop();
    } finally {
      ref.read(isSyncingProvider.notifier).setSyncing(false);
      ref.read(localSyncSessionProvider.notifier).setSyncing(false);
    }
  }

  /// Process incoming JSON payload from host or peer
  void _handleIncomingSyncPayload(dynamic rawMessage) async {
    try {
      final Map<String, dynamic> message = jsonDecode(rawMessage.toString());
      final type = message['type'] as String?;

      _lastActivityTime = DateTime.now();

      if (type == 'ping') {
        // Peer sent a ping -> respond with a pong immediately
        _sendPong(message['ts']);
        return;
      }

      if (type == 'pong') {
        // Peer responded to our ping -> calculate RTT latency
        final sentTs = message['ts'] as int?;
        if (sentTs != null) {
          _latencyMs = DateTime.now().millisecondsSinceEpoch - sentTs;
          _lastPingSentTime = null;
          AppLogger.d("LocalSyncService: Ping response received. RTT: ${_latencyMs}ms");

          if (_probeCompleter != null && !_probeCompleter!.isCompleted) {
            _probeCompleter!.complete(true);
          }
        }
        return;
      }

      if (type == 'disconnect') {
        AppLogger.d("LocalSyncService: Peer sent disconnect notice. Closing local channel.");
        stop();
        return;
      }

      // Delegate data payload to registered processor
      for (final processor in _processors) {
        if (processor.batchType == type) {
          ref.read(isSyncingProvider.notifier).setSyncing(true);
          ref.read(localSyncSessionProvider.notifier).setSyncing(true);

          try {
            final dataList = (message['data'] as List).cast<Map<String, dynamic>>();
            final syncedUuids = await processor.processIncomingLocalBatch(dataList);

            // Send acknowledgment back to peer
            _sendAck(processor.ackType, syncedUuids.map((id) => {'uuid': id}).toList());
          } finally {
            ref.read(isSyncingProvider.notifier).setSyncing(false);
            ref.read(localSyncSessionProvider.notifier).setSyncing(false);
          }
          return;
        }

        if (processor.ackType == type) {
          final dataList = (message['data'] as List).cast<Map<String, dynamic>>();
          final ackUuids = dataList.map((e) => e['uuid'] as String?).whereType<String>().toList();
          await processor.markAsLocalSynced(ackUuids);
          return;
        }
      }

      AppLogger.w("LocalSyncService: Unhandled payload type: $type");
    } catch (e, st) {
      AppLogger.e("LocalSyncService: Error processing sync payload", error: e, stack: st);
    }
  }

  void _sendPong(dynamic ts) {
    if (_activeChannel == null) return;
    try {
      final pongPayload = jsonEncode({
        'type': 'pong',
        'ts': ts,
      });
      _activeChannel!.sink.add(pongPayload);
    } catch (e) {
      AppLogger.w("LocalSyncService: Failed to send pong: $e");
    }
  }

  void _sendAck(String ackType, List<Map<String, dynamic>> items) {
    if (_activeChannel == null) return;
    try {
      final ackPayload = jsonEncode({
        'type': ackType,
        'data': items,
      });
      _activeChannel!.sink.add(ackPayload);
    } catch (e) {
      AppLogger.w("LocalSyncService: Failed to send ACK: $e");
    }
  }
}
