import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/sync/sync_orchestrator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/util/logger.dart';
import 'core/sync_entity_processor.dart';
import 'entities/folder_sync_processor.dart';
import 'entities/note_sync_processor.dart';

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
    ref.onDispose(() {
      stop();
    });

    return SyncConnectionState.disconnected;
  }

  void setStatus(SyncConnectionState status) {
    state = status;
  }

  void stop({SyncConnectionState reason = SyncConnectionState.disconnected}) {
    AppLogger.d("LocalSyncService: Shutting down Local Wi-Fi Sync ($reason).");
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

    state = reason;
  }

  void setActiveConnection(WebSocketChannel channel) {
    // Clean up previous channel if any
    stop();

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
      AppLogger.d("LocalSyncService: Save detected, but no active Wi-Fi connection. Waiting.");
      return;
    }

    ref.read(isSyncingProvider.notifier).setSyncing(true);

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
    }
  }

  /// Handle incoming network messages across entity processors
  Future<void> _handleIncomingSyncPayload(dynamic message) async {
    _lastActivityTime = DateTime.now();
    ref.read(isSyncingProvider.notifier).setSyncing(true);

    try {
      final decoded = jsonDecode(message as String) as Map<String, dynamic>;
      final type = decoded['type'] as String?;

      if (type == null) return;

      // --- HEARTBEAT & LIFECYCLE HANDLERS ---
      if (type == 'disconnect') {
        AppLogger.d("LocalSyncService: Peer sent disconnect notice. Closing local channel.");
        stop();
        return;
      }

      if (type == 'ping') {
        final pongPayload = jsonEncode({
          'type': 'pong',
          'ts': decoded['ts'],
        });
        _activeChannel?.sink.add(pongPayload);

        if (_probeCompleter != null && !_probeCompleter!.isCompleted) {
          _probeCompleter!.complete(true);
        }
        return;
      }

      if (type == 'pong') {
        if (_lastPingSentTime != null) {
          _latencyMs = DateTime.now().difference(_lastPingSentTime!).inMilliseconds;
          _lastPingSentTime = null;
        }

        if (_probeCompleter != null && !_probeCompleter!.isCompleted) {
          _probeCompleter!.complete(true);
        }
        return;
      }

      // If any other valid message arrived, probe is also satisfied
      if (_probeCompleter != null && !_probeCompleter!.isCompleted) {
        _probeCompleter!.complete(true);
      }

      // --- SCENARIO 1: Receiving a batch of items ---
      for (final processor in _processors) {
        if (processor.batchType == type) {
          final incomingList = (decoded['data'] as List<dynamic>?) ?? [];
          final uuidsToAck = await processor.processIncomingLocalBatch(incomingList);

          AppLogger.d("LocalSyncService: Successfully merged ${uuidsToAck.length} '${processor.entityName}' items from Wi-Fi.");

          final ackPayload = jsonEncode({
            'type': processor.ackType,
            'uuids': uuidsToAck,
          });

          _activeChannel?.sink.add(ackPayload);
          return;
        }
      }

      // --- SCENARIO 2: Receiving an ACK for sent items ---
      for (final processor in _processors) {
        // Match processor's ackType OR legacy 'ack_batch' for notes
        final isMatch = processor.ackType == type ||
            (type == 'ack_batch' && processor.entityName == 'note');

        if (isMatch) {
          final ackUuids = List<String>.from(decoded['uuids'] as List? ?? []);
          await processor.markAsLocalSynced(ackUuids);

          AppLogger.d("LocalSyncService: Peer acknowledged ${ackUuids.length} '${processor.entityName}' items. Marked as synced.");
          return;
        }
      }
    } catch (e, st) {
      AppLogger.e('LocalSyncService: Failed to parse incoming payload', error: e, stack: st);
    } finally {
      ref.read(isSyncingProvider.notifier).setSyncing(false);
    }
  }
}
