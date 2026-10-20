import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/sync/sync_orchestrator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/util/logger.dart';
import 'core/sync_entity_processor.dart';
import 'entities/folder_sync_processor.dart';
import 'entities/note_sync_processor.dart';

enum SyncConnectionState { disconnected, connected }

final localSyncServiceProvider =
    NotifierProvider<LocalSyncNotifier, SyncConnectionState>(() {
      return LocalSyncNotifier();
    });

class LocalSyncNotifier extends Notifier<SyncConnectionState> {
  WebSocketChannel? _activeChannel;
  StreamSubscription? _streamSubscription;

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

  void stop() {
    AppLogger.d("LocalSyncService: Shutting down Local Wi-Fi Sync.");
    _streamSubscription?.cancel();
    _activeChannel?.sink.close();
    _activeChannel = null;
    state = SyncConnectionState.disconnected;
  }

  void setActiveConnection(WebSocketChannel channel) {
    _activeChannel = channel;
    state = SyncConnectionState.connected;

    AppLogger.d("LocalSyncService: Active connection established!");

    _streamSubscription = _activeChannel!.stream.listen(
      (message) => _handleIncomingSyncPayload(message),
      onDone: () {
        AppLogger.d("LocalSyncService: Disconnected from peer.");
        stop();
      },
      onError: (e) {
        AppLogger.e("LocalSyncService: WebSocket Error", error: e);
        stop();
      },
    );

    // Broadcast local changes immediately upon connecting
    broadcastLocalChanges();
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
        AppLogger.d("LocalSyncService: Broadcasted batch of ${pendingItems.length} '${processor.entityName}' items over Wi-Fi.");
      }
    } catch (e, st) {
      AppLogger.e("LocalSyncService: Broadcast Failed", error: e, stack: st);
    } finally {
      ref.read(isSyncingProvider.notifier).setSyncing(false);
    }
  }

  /// Handle incoming network messages across entity processors
  Future<void> _handleIncomingSyncPayload(dynamic message) async {
    ref.read(isSyncingProvider.notifier).setSyncing(true);

    try {
      final decoded = jsonDecode(message as String) as Map<String, dynamic>;
      final type = decoded['type'] as String?;

      if (type == null) return;

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
