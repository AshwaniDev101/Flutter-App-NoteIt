import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'drift/drift_database.dart';

final localSyncServiceProvider = Provider<LocalSyncService>((ref) {
  return LocalSyncService(ref);
});

class LocalSyncService {
  final Ref ref;

  // This holds the live connection. It doesn't matter if this device
  // is the Host (PC) or the Client (Phone). Once connected, they both use this.
  WebSocketChannel? _activeChannel;

  LocalSyncService(this.ref);

  void start() {
    print("LocalWorker: Local Wi-Fi Sync enabled and waiting for connection...");
  }

  void stop() {
    print("LocalWorker: Shutting down Local Wi-Fi Sync.");
    _activeChannel?.sink.close();
    _activeChannel = null;
  }

  // QR Code pages will call this the moment a successful connection is made.
  void setActiveConnection(WebSocketChannel channel) {
    _activeChannel = channel;
    print("LocalWorker: Active connection established!");

    // Start listening for incoming notes from the other device
    _activeChannel!.stream.listen(
          (message) => _handleIncomingSyncPayload(message),
      onDone: () {
        print("LocalWorker: Disconnected from peer.");
        _activeChannel = null;
      },
      onError: (e) {
        print("LocalWorker: WebSocket Error -> $e");
        _activeChannel = null;
      },
    );

    // The second we connect, broadcast our pending notes to the other device
    broadcastLocalChanges();
  }

  // Called by the Orchestrator whenever the UI saves, updates, or deletes a note
  Future<void> broadcastLocalChanges() async {
    if (_activeChannel == null) {
      print("LocalWorker: Note saved, but no active Wi-Fi connection. Waiting.");
      return;
    }

    try {
      final driftDb = ref.read(noteDriftDatabaseProvider);

      //  Ask specifically for notes that need to be synced locally
      final pendingNotes = await driftDb.getPendingLocalNotes();

      if (pendingNotes.isEmpty) return;

      for (final note in pendingNotes) {
        final payload = jsonEncode({
          'type': 'note_update',
          'data': note.toJson(),
        });

        _activeChannel!.sink.add(payload);
      }

      print("LocalWorker: Broadcasted ${pendingNotes.length} notes over Wi-Fi.");
      // Note: We do NOT markAsLocalSynced here. We wait for the ACK!

    } catch (e) {
      print("LocalWorker: Broadcast Failed -> $e");
    }
  }

  // The Last-Write-Wins (LWW) Engine for incoming data
  Future<void> _handleIncomingSyncPayload(dynamic message) async {
    try {
      final decoded = jsonDecode(message as String);
      final driftDb = ref.read(noteDriftDatabaseProvider);

      //  SCENARIO 1: We received a note from the other device
      if (decoded['type'] == 'note_update') {
        final incomingData = decoded['data'] as Map<String, dynamic>;


        final incomingUuid = incomingData['uuid'] as String;

        // Merge the note into our local database
        await driftDb.upsertNoteFromLocal(incomingData);
        print("LocalWorker: Successfully merged incoming note $incomingUuid from Wi-Fi.");

        // Tell the other device we successfully saved it!
        final ackPayload = jsonEncode({
          'type': 'ack',
          'uuid': incomingUuid,
        });
        _activeChannel?.sink.add(ackPayload);
      }

      //  SCENARIO 2: The other device is acknowledging a note WE sent
      else if (decoded['type'] == 'ack') {
        final ackUuid = decoded['uuid'] as String;

        // Now it is safe to mark it as synced!
        await driftDb.markAsLocalSynced([ackUuid]);
        print("LocalWorker: Peer acknowledged note $ackUuid. Marked as localSyncStatus = 1.");
      }

    } catch (e) {
      print('LocalWorker: Failed to parse incoming payload -> $e');
    }
  }
}