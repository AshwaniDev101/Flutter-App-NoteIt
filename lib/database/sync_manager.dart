import 'dart:async';

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

  StreamSubscription? _remoteSubscription;

  @override
  bool build() {
    _driftDb = ref.watch(noteDriftDatabaseProvider);
    _firebaseDb = ref.watch(noteFirebaseDatabaseProvider);
    _prefs = ref.watch(sharedPreferenceProvider);

    _startActiveSessionListener();

    return false;
  }

  void _startActiveSessionListener() {
    final sessionStartTime = DateTime.now().toUtc().millisecondsSinceEpoch;

    _remoteSubscription = _firebaseDb.watchForRemoteChanges(sessionStartTime).listen((newDocs) async {
      if (newDocs.isEmpty) return;

      print("### SyncManager [STREAM]: Real-time remote changes detected!");
      for (final doc in newDocs) {
        await _driftDb.upsertNoteFromCloud(doc.data()!, doc.id);
      }

      await _prefs.setLastSyncTime(DateTime.now().toUtc().millisecondsSinceEpoch);
    });
  }

  Future<void> executeFullSync() async {
    if (state) return;

    state = true;

    try {
      print("### SyncManager: Starting Delta Sync...");

      final int lastSyncTime = _prefs.lastSyncTime;
      // Note: We still use local time for the bookmark, which is perfectly safe
      // now because Firebase is handling the document ordering on its end.
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
      state = false;
    }
  }
}