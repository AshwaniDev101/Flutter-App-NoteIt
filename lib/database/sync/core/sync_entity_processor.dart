/// Contract for entity sync processors (Folders, Notes, etc.)
abstract class SyncEntityProcessor {
  /// Unique identifier for entity collection / channel (e.g. 'folders', 'notes')
  String get entityName;

  /// Batch payload type identifier for Wi-Fi P2P (e.g. 'folder_batch', 'note_batch')
  String get batchType => '${entityName}_batch';

  /// ACK payload type identifier for Wi-Fi P2P (e.g. 'ack_folder_batch', 'ack_note_batch')
  String get ackType => 'ack_${entityName}_batch';

  /// List of dependent entity processors that MUST sync BEFORE this processor
  List<SyncEntityProcessor> get dependencies => [];

  // --- LOCAL WI-FI SYNC METHODS ---
  Future<List<Map<String, dynamic>>> getPendingLocalChanges();
  Future<List<String>> processIncomingLocalBatch(List<dynamic> items);
  Future<void> markAsLocalSynced(Iterable<String> uuids);

  // --- CLOUD FIREBASE SYNC METHODS ---
  Future<List<Map<String, dynamic>>> getPendingCloudChanges();
  Future<List<String>> processIncomingCloudBatch(List<Map<String, dynamic>> items);
  Future<void> markAsCloudSynced(Iterable<String> uuids);
}
