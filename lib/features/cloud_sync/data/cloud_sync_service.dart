import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/profiles/providers/active_profile_provider.dart';
import 'package:noteit/core/sync/sync_orchestrator.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/drift/folders/folders_dao.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import 'package:noteit/database/firebase/firebase_database.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(ref);
});

class CloudSyncService {
  final Ref ref;
  bool _isRunning = false;
  bool _isExecutingFullSync = false;
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>? _folderSubscription;
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>? _noteSubscription;

  bool get isRunning => _isRunning;

  CloudSyncService(this.ref);

  void start() {
    if (_isRunning) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      AppLogger.w("CloudSyncService: Cannot start engine. User is not authenticated.");
      return;
    }

    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile.linkedEmail != null && user.email?.toLowerCase() != activeProfile.linkedEmail?.toLowerCase()) {
      AppLogger.w("CloudSyncService: Signed-in user (${user.email}) does not match active profile linkedEmail (${activeProfile.linkedEmail}). Aborting sync.");
      return;
    }

    _isRunning = true;
    final sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    AppLogger.d("CloudSyncService: Starting Firebase sync engine for user ${user.uid} (${activeProfile.name})...");

    _subscribeToRemoteChanges(sessionStartTime);
    executeFullSync();
  }

  void stop() {
    _cancelSubscriptions();
    if (!_isRunning) return;
    _isRunning = false;
    AppLogger.d("CloudSyncService: Stopping Firebase sync engine...");
  }

  void _cancelSubscriptions() {
    _folderSubscription?.cancel();
    _folderSubscription = null;
    _noteSubscription?.cancel();
    _noteSubscription = null;
  }

  void _subscribeToRemoteChanges(int sessionStartTime) {
    _cancelSubscriptions();

    final firebaseDb = ref.read(noteFirebaseDatabaseProvider);
    if (firebaseDb == null) return;

    final foldersDao = ref.read(foldersDaoProvider);
    final notesDao = ref.read(notesDaoProvider);

    _folderSubscription = firebaseDb.watchForRemoteChanges('folders', sessionStartTime).listen(
      (docSnapshots) async {
        for (final doc in docSnapshots) {
          final data = doc.data();
          if (data != null) {
            try {
              await foldersDao.upsertFolderFromCloud(data);
              AppLogger.d("CloudSyncService: Realtime merged folder ${data['uuid']}");
            } catch (e, st) {
              AppLogger.e("CloudSyncService: Failed to upsert realtime folder", error: e, stack: st);
            }
          }
        }
      },
      onError: (e, st) {
        AppLogger.e("CloudSyncService: Error in folder realtime stream", error: e, stack: st);
      },
    );

    _noteSubscription = firebaseDb.watchForRemoteChanges('notes', sessionStartTime).listen(
      (docSnapshots) async {
        for (final doc in docSnapshots) {
          final data = doc.data();
          if (data != null) {
            try {
              await notesDao.upsertNoteFromCloud(data);
              AppLogger.d("CloudSyncService: Realtime merged note ${data['uuid']}");
            } catch (e, st) {
              AppLogger.e("CloudSyncService: Failed to upsert realtime note", error: e, stack: st);
            }
          }
        }
      },
      onError: (e, st) {
        AppLogger.e("CloudSyncService: Error in note realtime stream", error: e, stack: st);
      },
    );
  }

  Future<void> executeFullSync() async {
    if (!_isRunning || _isExecutingFullSync) return;

    final firebaseDb = ref.read(noteFirebaseDatabaseProvider);
    if (firebaseDb == null) {
      AppLogger.w("CloudSyncService: Cannot sync. NoteFirestoreDatabase is null.");
      return;
    }

    _isExecutingFullSync = true;
    AppLogger.d("CloudSyncService: Executing full sync...");
    ref.read(isSyncingProvider.notifier).setSyncing(true);

    try {
      final foldersDao = ref.read(foldersDaoProvider);
      final notesDao = ref.read(notesDaoProvider);
      final prefs = ref.read(sharedPreferenceProvider);

      // 1. PUSH FOLDERS FIRST
      final pendingFolders = await foldersDao.getPendingCloudFolders();
      if (pendingFolders.isNotEmpty) {
        final folderMaps = pendingFolders.map((f) => f.toJson()).toList();
        await firebaseDb.pushBatch('folders', folderMaps);
        await foldersDao.markAsCloudSynced(pendingFolders.map((f) => f.uuid));
        AppLogger.d("CloudSyncService: Pushed ${pendingFolders.length} folders to cloud.");
      }

      // 2. PUSH NOTES SECOND
      final pendingNotes = await notesDao.getPendingCloudNotes();
      if (pendingNotes.isNotEmpty) {
        final noteMaps = pendingNotes.map((n) => n.toJson()).toList();
        await firebaseDb.pushBatch('notes', noteMaps);
        await notesDao.markAsCloudSynced(pendingNotes.map((n) => n.uuid));
        AppLogger.d("CloudSyncService: Pushed ${pendingNotes.length} notes to cloud.");
      }

      // 3. PULL REMOTE FOLDERS
      final lastSyncTime = prefs.lastCloudSyncTime;
      final remoteFolderDocs = await firebaseDb.pullChanges('folders', lastSyncTime);
      for (final doc in remoteFolderDocs) {
        final data = doc.data();
        await foldersDao.upsertFolderFromCloud(data);
      }
      if (remoteFolderDocs.isNotEmpty) {
        AppLogger.d("CloudSyncService: Pulled and merged ${remoteFolderDocs.length} folders from cloud.");
      }

      // 4. PULL REMOTE NOTES
      final remoteNoteDocs = await firebaseDb.pullChanges('notes', lastSyncTime);
      for (final doc in remoteNoteDocs) {
        final data = doc.data();
        await notesDao.upsertNoteFromCloud(data);
      }
      if (remoteNoteDocs.isNotEmpty) {
        AppLogger.d("CloudSyncService: Pulled and merged ${remoteNoteDocs.length} notes from cloud.");
      }

      // 5. UPDATE LAST SYNC TIMESTAMP
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setLastCloudSyncTime(now);

      AppLogger.d("CloudSyncService: Full sync completed successfully.");
    } catch (e, st) {
      AppLogger.e("CloudSyncService: Error executing full sync", error: e, stack: st);
    } finally {
      _isExecutingFullSync = false;
      ref.read(isSyncingProvider.notifier).setSyncing(false);
    }
  }
}
