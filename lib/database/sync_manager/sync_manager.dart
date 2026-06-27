import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../drift/drift_database.dart';
import '../firebase/firebase_database.dart';
import '../shared_preference/shared_preference_manager.dart';


final syncManagerProvider = Provider((ref) {
  final driftDb = ref.watch(noteDriftDatabaseProvider);
  final firebaseDb = ref.watch(noteFirebaseDatabaseProvider);
  final prefs = ref.watch(sharedPreferenceProvider);

  return SyncManager(driftDb, firebaseDb, prefs);
});

class SyncManager {
  final NoteDriftDatabase _driftDb;
  final NoteFirestoreDatabase _firebaseDb;
  final SharedPreferenceManager _prefs;

  SyncManager(this._driftDb, this._firebaseDb, this._prefs);

  Future<void> executeFullSync() async {
    try {
      print("### SyncManager: Starting Delta Sync...");

      // Get the last sync timestamp (defaults to 0 on first run)
      final int lastSyncTime = _prefs.lastSyncTime;

      // Capture current time BEFORE sync starts so we don't miss changes that happen during sync
      final int newSyncTime = DateTime.now().toUtc().millisecondsSinceEpoch;

      // PULL Remote Changes
      print("### SyncManager: Pulling changes since $lastSyncTime...");
      final remoteChanges = await _firebaseDb.pullChanges(lastSyncTime);

      for (final doc in remoteChanges) {
        // MERGE into Local DB
        await _driftDb.upsertNoteFromCloud(doc.data(), doc.id);
      }
      print("### SyncManager: Pulled & merged ${remoteChanges.length} notes.");

      // PUSH Local Changes
      print("### SyncManager: Fetching local pending notes...");
      final pendingNotes = await _driftDb.getPendingNotes();

      if (pendingNotes.isNotEmpty) {
        // BATCH PUSH to Firebase
        final newIds = await _firebaseDb.pushBatch(pendingNotes);

        // Mark Local as Synced
        await _driftDb.markAsSynced(pendingNotes.map((n) => n.id), newIds);
        print("### SyncManager: Pushed ${pendingNotes.length} notes.");
      } else {
        print("### SyncManager: No local changes to push.");
      }

      // Update Bookmark
      await _prefs.setLastSyncTime(newSyncTime);
      print("### SyncManager: Sync Complete. Bookmark updated to $newSyncTime.");

    } catch (e) {
      print("### SyncManager: Sync Failed: $e");

    }
  }
}