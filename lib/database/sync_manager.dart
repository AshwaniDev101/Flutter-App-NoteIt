import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'drift/drift_database.dart';
import 'firebase/firebase_database.dart';
import 'shared_preference/shared_preference_manager.dart';

final syncNotifierProvider = NotifierProvider<SyncNotifier, bool>(
  SyncNotifier.new,
);

class SyncNotifier extends Notifier<bool> {

  late final NoteDriftDatabase _driftDb;
  late final NoteFirestoreDatabase _firebaseDb;
  late final SharedPreferenceManager _prefs;

  @override
  bool build() {
    _driftDb = ref.watch(noteDriftDatabaseProvider);
    _firebaseDb = ref.watch(noteFirebaseDatabaseProvider);
    _prefs = ref.watch(sharedPreferenceProvider);

    return false; // initial state: not syncing
  }

  /// Execute full sync and manage loading state internally
  Future<void> executeFullSync() async {
    if (state) return; // Prevent overlapping syncs

    state = true; // Start loading / animation

    try {
      print("### SyncManager: Starting Delta Sync...");

      final int lastSyncTime = _prefs.lastSyncTime;
      final int newSyncTime = DateTime.now().toUtc().millisecondsSinceEpoch;

      // PULL
      print("### SyncManager: Pulling changes since $lastSyncTime...");
      final remoteChanges = await _firebaseDb.pullChanges(lastSyncTime);

      for (final doc in remoteChanges) {
        await _driftDb.upsertNoteFromCloud(doc.data(), doc.id);
      }
      print("### SyncManager: Pulled & merged ${remoteChanges.length} notes.");

      // PUSH
      print("### SyncManager: Fetching local pending notes...");
      final pendingNotes = await _driftDb.getPendingNotes();

      if (pendingNotes.isNotEmpty) {
        final newIds = await _firebaseDb.pushBatch(pendingNotes);
        await _driftDb.markAsSynced(
          pendingNotes.map((n) => n.id),
          newIds,
        );
        print("### SyncManager: Pushed ${pendingNotes.length} notes.");
      } else {
        print("### SyncManager: No local changes to push.");
      }

      // BOOKMARK
      await _prefs.setLastSyncTime(newSyncTime);
      print("### SyncManager: Sync Complete. Bookmark updated to $newSyncTime.");
    } catch (e) {
      print("### SyncManager: Sync Failed: $e");
    } finally {
      state = false; // Always stop loading
    }
  }
}