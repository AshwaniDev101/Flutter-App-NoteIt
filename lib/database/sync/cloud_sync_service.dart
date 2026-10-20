import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/sync/sync_orchestrator.dart';
import '../firebase/firebase_database.dart';
import '../shared_preference/shared_preference_manager.dart';
import 'core/sync_entity_processor.dart';
import 'entities/folder_sync_processor.dart';
import 'entities/note_sync_processor.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final folderProcessor = ref.watch(folderSyncProcessorProvider);
  final noteProcessor = ref.watch(noteSyncProcessorProvider);
  return CloudSyncService(ref, processors: [folderProcessor, noteProcessor]);
});

class CloudSyncService {
  final Ref ref;
  final List<SyncEntityProcessor> processors;
  final List<StreamSubscription> _remoteSubscriptions = [];
  bool _isSyncing = false;

  CloudSyncService(this.ref, {required this.processors});

  void start() {
    if (_remoteSubscriptions.isNotEmpty) return; // Already running
    AppLogger.d("CloudSyncService: Starting Firebase sync engine across ${processors.length} entity processors...");
    _startActiveSessionListeners();
    executeFullSync();
  }

  void stop() {
    AppLogger.d("CloudSyncService: Stopping Firebase sync engine...");
    for (final sub in _remoteSubscriptions) {
      sub.cancel();
    }
    _remoteSubscriptions.clear();
  }

  void _startActiveSessionListeners() {
    final firebaseDb = ref.read(noteFirebaseDatabaseProvider);
    final prefs = ref.read(sharedPreferenceProvider);

    if (firebaseDb == null) return;

    final sessionStartTime = DateTime.now().toUtc().millisecondsSinceEpoch;

    for (final processor in processors) {
      final sub = firebaseDb
          .watchForRemoteChanges(processor.entityName, sessionStartTime)
          .listen((newDocs) async {
        if (newDocs.isEmpty) return;

        AppLogger.d("CloudSyncService: Real-time remote changes detected for '${processor.entityName}'!");
        final items = newDocs.map((doc) => doc.data()!).toList();
        await processor.processIncomingCloudBatch(items);
        await prefs.setLastSyncTime(DateTime.now().toUtc().millisecondsSinceEpoch);
      });
      _remoteSubscriptions.add(sub);
    }
  }

  Future<void> executeFullSync() async {
    if (_isSyncing) return;

    final firebaseDb = ref.read(noteFirebaseDatabaseProvider);
    final prefs = ref.read(sharedPreferenceProvider);

    if (firebaseDb == null) return;

    _isSyncing = true;

    ref.read(isSyncingProvider.notifier).setSyncing(true);

    try {
      final int lastSyncTime = prefs.lastSyncTime;
      final int newSyncTime = DateTime.now().toUtc().millisecondsSinceEpoch;

      // --- PULL (In processor dependency order: Folders -> Notes) ---
      for (final processor in processors) {
        final remoteDocs = await firebaseDb.pullChanges(processor.entityName, lastSyncTime);
        if (remoteDocs.isNotEmpty) {
          final items = remoteDocs.map((doc) => doc.data()).toList();
          await processor.processIncomingCloudBatch(items);
          AppLogger.d("CloudSyncService: Pulled ${items.length} '${processor.entityName}' items from Cloud.");
        }
      }

      // --- PUSH (In processor dependency order: Folders -> Notes) ---
      for (final processor in processors) {
        final pendingItems = await processor.getPendingCloudChanges();
        if (pendingItems.isNotEmpty) {
          await firebaseDb.pushBatch(processor.entityName, pendingItems);

          final pushedUuids = pendingItems
              .map((item) => item['uuid'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>();

          await processor.markAsCloudSynced(pushedUuids);
          AppLogger.d("CloudSyncService: Pushed ${pendingItems.length} '${processor.entityName}' items to Cloud.");
        }
      }

      // --- BOOKMARK ---
      await prefs.setLastSyncTime(newSyncTime);
      AppLogger.d("CloudSyncService: Sync Complete. Bookmark: $newSyncTime");
    } catch (e, st) {
      AppLogger.e("CloudSyncService: Sync Failed", error: e, stack: st);
    } finally {
      _isSyncing = false;

      // Tell the UI spinner to stop spinning!
      ref.read(isSyncingProvider.notifier).setSyncing(false);
    }
  }
}
