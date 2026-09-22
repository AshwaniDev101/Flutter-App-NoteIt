import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/database/sync/sync_orchestrator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum SyncConnectionState { disconnected, connected }

final localSyncServiceProvider =
    NotifierProvider<LocalSyncNotifier, SyncConnectionState>(() {
      return LocalSyncNotifier();
    });
// final localSyncServiceProvider = Provider<LocalSyncService>((ref) {
//   return LocalSyncService(ref);
// });

class LocalSyncNotifier extends Notifier<SyncConnectionState> {
  // This holds the live connection. It doesn't matter if this device
  // is the Host (PC) or the Client (Phone). Once connected, they both use this.
  WebSocketChannel? _activeChannel;
  StreamSubscription? _streamSubscription;

  @override
  SyncConnectionState build() {
    // Safety net: if provider is destroyed, clean up resources
    ref.onDispose(() {
      stop();
    });

    return SyncConnectionState.disconnected; // Default state
  }

  void stop() {
    print("LocalWorker: Shutting down Local Wi-Fi Sync.");
    _streamSubscription?.cancel(); // Cancel the listener
    _activeChannel?.sink.close();
    _activeChannel = null;
    // For updating the UI
    state = SyncConnectionState.disconnected;
  }

  // QR Code pages will call this the moment a successful connection is made.
  void setActiveConnection(WebSocketChannel channel) {
    _activeChannel = channel;

    // Update the UI instantly so it can show a green "Connected" icon
    state = SyncConnectionState.connected;

    print("LocalWorker: Active connection established!");

    // Start listening for incoming notes from the other device
    // Save the subscription to the variable
    _streamSubscription = _activeChannel!.stream.listen(
      (message) => _handleIncomingSyncPayload(message),
      onDone: () {
        print("LocalWorker: Disconnected from peer.");
        stop(); // Resets state and cleans up
      },
      onError: (e) {
        print("LocalWorker: WebSocket Error -> $e");
        stop(); // Resets state and cleans up
      },
    );

    // The second we connect, broadcast our pending notes to the other device
    broadcastLocalChanges();
  }

  // Called by the Orchestrator whenever the UI saves, updates, or deletes a note
  // This asks the Drift database for any notes created or edited offline.
  // It loops through them, converts them to JSON, and fires them across the WebSocket.
  // Crucially, it does not mark them as synced yet. It waits for proof of delivery.

  Future<void> broadcastLocalChanges() async {
    if (_activeChannel == null) {
      print(
        "LocalWorker: Note saved, but no active Wi-Fi connection. Waiting.",
      );
      return;
    }

    // Syncing icon animation: starts
    ref.read(isSyncingProvider.notifier).state = true;

    try {
      final notesDao = ref.read(notesDaoProvider);

      //  Ask specifically for notes that need to be synced locally
      final pendingNotes = await notesDao.getPendingLocalNotes();

      if (pendingNotes.isEmpty) return;

      // BATCHING : Send everything in one single payload
      final payload = jsonEncode({
        'type': 'note_batch',
        'data': pendingNotes.map((n) => n.toJson()).toList(),
      });
      // for (final note in pendingNotes) {
      //   final payload = jsonEncode({
      //     'type': 'note_update',
      //     'data': note.toJson(),
      //   });
      //
      //   _activeChannel!.sink.add(payload);
      // }
      _activeChannel!.sink.add(payload);
      print(
        "LocalWorker: Broadcasted batch of ${pendingNotes.length} notes over Wi-Fi.",
      );
      // Note: We do NOT markAsLocalSynced here. We wait for the ACK!
    } catch (e) {
      print("LocalWorker: Broadcast Failed -> $e");
    } finally {
      // Syncing icon animation: stops
      ref.read(isSyncingProvider.notifier).state = false;
    }
  }

  // The Last-Write-Wins (LWW) Engine for incoming data
  // When other device sent a note. _handleIncomingSyncPayload blindly saves it using Last-Write-Wins logic (upsertNoteFromLocal),
  // and then sends a tiny ack (acknowledgment) receipt back.
  Future<void> _handleIncomingSyncPayload(dynamic message) async {
    // Syncing icon animation: starts
    ref.read(isSyncingProvider.notifier).state = true;

    try {
      final decoded = jsonDecode(message as String);
      final notesDao = ref.read(notesDaoProvider);

      //  SCENARIO 1: Receiving a batch of notes
      if (decoded['type'] == 'note_batch') {
        final incomingList = decoded['data'] as List<dynamic>;

        final uuidsToAck =
            <String>[]; // Keep track of what we successfully save

        for (var item in incomingList) {
          final noteData = item as Map<String, dynamic>;
          await notesDao.upsertNoteFromLocal(noteData);
          uuidsToAck.add(noteData['uuid'] as String);
        }
        // Merge the note into our local database
        // await notesDao.upsertNoteFromLocal(incomingList);
        // print("LocalWorker: Successfully merged incoming note $incomingUuid from Wi-Fi.");

        print(
          "LocalWorker: Successfully merged ${uuidsToAck.length} notes from Wi-Fi.",
        );
        // Tell the other device we successfully saved it!
        final ackPayload = jsonEncode({
          'type': 'ack_batch',
          'uuids': uuidsToAck,
        });
        _activeChannel?.sink.add(ackPayload);
      }
      //  SCENARIO 2: The other device is acknowledging a note WE sent
      else if (decoded['type'] == 'ack_batch') {
        // Convert the dynamic JSON list back into a List<String>
        final ackUuids = List<String>.from(decoded['uuids']);

        // Now it is safe to mark it as synced!
        // Update the database for all confirmed notes at once
        await notesDao.markAsLocalSynced(ackUuids);

        print(
          "LocalWorker: Peer acknowledged ${ackUuids.length} notes. Marked as synced.",
        );
      }
    } catch (e) {
      print('LocalWorker: Failed to parse incoming payload -> $e');
    } finally {
      // Syncing icon animation: stops
      ref.read(isSyncingProvider.notifier).state = false;
    }
  }
}
