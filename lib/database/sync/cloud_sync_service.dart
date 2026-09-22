import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/sync/sync_orchestrator.dart';
import '../drift/notes/notes_dao.dart';
import '../firebase/firebase_database.dart';
import '../shared_preference/shared_preference_manager.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(ref);
});

class CloudSyncService {
  final Ref ref;
  StreamSubscription? _remoteSubscription;
  bool _isSyncing = false;

  CloudSyncService(this.ref);

  void start() {
    if (_remoteSubscription != null) return; // Already running
    print("CloudWorker: Starting Firebase sync engine...");
    _startActiveSessionListener();
    executeFullSync();
  }

  void stop() {
    print("CloudWorker: Stopping Firebase sync engine...");
    _remoteSubscription?.cancel();
    _remoteSubscription = null;
  }

  void _startActiveSessionListener() {
    final firebaseDb = ref.read(noteFirebaseDatabaseProvider);
    final notesDao = ref.read(notesDaoProvider);
    final prefs = ref.read(sharedPreferenceProvider);

    if (firebaseDb == null) return;

    final sessionStartTime = DateTime.now().toUtc().millisecondsSinceEpoch;

    _remoteSubscription = firebaseDb
        .watchForRemoteChanges(sessionStartTime)
        .listen((newDocs) async {
          if (newDocs.isEmpty) return;

          print("CloudWorker: Real-time remote changes detected!");
          for (final doc in newDocs) {
            // upsertNoteFromCloud now only needs the data map, since UUID is inside it!
            await notesDao.upsertNoteFromCloud(doc.data()!);
          }
          await prefs.setLastSyncTime(
            DateTime.now().toUtc().millisecondsSinceEpoch,
          );
        });
  }

  Future<void> executeFullSync() async {
    if (_isSyncing) return;

    final firebaseDb = ref.read(noteFirebaseDatabaseProvider);
    final notesDao = ref.read(notesDaoProvider);
    final prefs = ref.read(sharedPreferenceProvider);

    if (firebaseDb == null) return;

    _isSyncing = true;

    ref.read(isSyncingProvider.notifier).state = true;

    try {
      final int lastSyncTime = prefs.lastSyncTime;
      final int newSyncTime = DateTime.now().toUtc().millisecondsSinceEpoch;

      // --- PULL ---
      final remoteChanges = await firebaseDb.pullChanges(lastSyncTime);
      for (final doc in remoteChanges) {
        await notesDao.upsertNoteFromCloud(doc.data());
      }

      // --- PUSH ---
      final pendingNotes = await notesDao.getPendingCloudNotes();
      if (pendingNotes.isNotEmpty) {
        await firebaseDb.pushBatch(pendingNotes);

        await notesDao.markAsCloudSynced(pendingNotes.map((n) => n.uuid));
        print("CloudWorker: Pushed ${pendingNotes.length} notes.");
      }

      // --- BOOKMARK ---
      await prefs.setLastSyncTime(newSyncTime);
      print("CloudWorker: Sync Complete. Bookmark: $newSyncTime");
    } catch (e) {
      print("CloudWorker: Sync Failed -> $e");
    } finally {
      _isSyncing = false;

      // Tell the UI spinner to stop spinning!
      ref.read(isSyncingProvider.notifier).state = false;
    }
  }
}
