import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base contract for processing different database entities over P2P local Wi-Fi sync.
abstract class SyncEntityProcessor {
  final Ref ref;

  SyncEntityProcessor(this.ref);

  /// Human readable entity name (e.g., 'note', 'folder')
  String get entityName;

  /// JSON message type for batch payload (e.g., 'sync_batch', 'folder_sync_batch')
  String get batchType;

  /// JSON message type for ACK response (e.g., 'ack_batch', 'folder_ack_batch')
  String get ackType;

  /// Fetches pending local database changes that need to be sent to peer
  Future<List<Map<String, dynamic>>> getPendingLocalChanges();

  /// Merges incoming peer payload list into local database and returns synced UUIDs
  Future<List<String>> processIncomingLocalBatch(List<dynamic> incomingList);

  /// Marks items as synced locally in database after receiving peer ACK
  Future<void> markAsLocalSynced(List<String> uuids);
}
