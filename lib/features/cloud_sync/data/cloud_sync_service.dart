import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/sync/sync_orchestrator.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import 'package:noteit/database/firebase/firebase_database.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/workspace/providers/active_workspace_provider.dart';

import 'processors/cloud_entity_processor.dart';
import 'processors/cloud_folder_processor.dart';
import 'processors/cloud_note_processor.dart';
import 'processors/cloud_workspace_processor.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(ref);
});

class CloudSyncService {
  final Ref ref;
  bool _isRunning = false;
  bool _isExecutingFullSync = false;
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>? _manifestSubscription;
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>? _folderSubscription;
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>? _noteSubscription;

  bool get isRunning => _isRunning;

  List<CloudEntityProcessor> get _processors => [
        ref.read(cloudWorkspaceProcessorProvider),
        ref.read(cloudFolderProcessorProvider),
        ref.read(cloudNoteProcessorProvider),
      ];

  CloudSyncService(this.ref);

  void start() {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      AppLogger.w("CloudSyncService: Cannot start engine. User is not authenticated.");
      return;
    }

    final activeWorkspace = ref.read(activeWorkspaceProvider);

    if (_isRunning) {
      _cancelSubscriptions();
    }

    _isRunning = true;
    final sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    AppLogger.d("CloudSyncService: Starting Firebase sync engine for user ${user.uid} (Active Workspace: ${activeWorkspace.name}, ID: ${activeWorkspace.id})...");

    _subscribeToRemoteChanges(sessionStartTime);
    executeFullSync();
  }

  void stop() {
    _cancelSubscriptions();
    if (!_isRunning) return;
    _isRunning = false;
    AppLogger.d("CloudSyncService: Stopping Firebase sync engine...");
  }

  void restart() {
    stop();
    start();
  }

  void _cancelSubscriptions() {
    _manifestSubscription?.cancel();
    _manifestSubscription = null;
    _folderSubscription?.cancel();
    _folderSubscription = null;
    _noteSubscription?.cancel();
    _noteSubscription = null;
  }

  void _subscribeToRemoteChanges(int sessionStartTime) {
    _cancelSubscriptions();

    final firebaseDb = ref.read(noteFirebaseDatabaseProvider);
    if (firebaseDb == null) return;

    final workspaceProcessor = ref.read(cloudWorkspaceProcessorProvider);
    final folderProcessor = ref.read(cloudFolderProcessorProvider);
    final noteProcessor = ref.read(cloudNoteProcessorProvider);

    final activeWorkspace = ref.read(activeWorkspaceProvider);

    _manifestSubscription = firebaseDb.watchForManifestChanges(sessionStartTime).listen(
      (docSnapshots) async {
        if (docSnapshots.isEmpty) return;
        ref.read(isSyncingProvider.notifier).setSyncing(true);
        try {
          for (final doc in docSnapshots) {
            final data = doc.data();
            if (data != null) {
              await workspaceProcessor.processIncomingCloudItem(data);
            }
          }
        } finally {
          ref.read(isSyncingProvider.notifier).setSyncing(false);
        }
      },
      onError: (e, st) {
        AppLogger.e("CloudSyncService: Error in workspace manifest realtime stream", error: e, stack: st);
      },
    );

    _folderSubscription = firebaseDb.watchForRemoteChanges('folders', sessionStartTime, targetWorkspaceId: activeWorkspace.id).listen(
      (docSnapshots) async {
        if (docSnapshots.isEmpty) return;
        ref.read(isSyncingProvider.notifier).setSyncing(true);
        try {
          for (final doc in docSnapshots) {
            final data = doc.data();
            if (data != null) {
              await folderProcessor.processIncomingCloudItem(data, targetWorkspaceId: activeWorkspace.id);
            }
          }
        } finally {
          ref.read(isSyncingProvider.notifier).setSyncing(false);
        }
      },
      onError: (e, st) {
        AppLogger.e("CloudSyncService: Error in folder realtime stream", error: e, stack: st);
      },
    );

    _noteSubscription = firebaseDb.watchForRemoteChanges('notes', sessionStartTime, targetWorkspaceId: activeWorkspace.id).listen(
      (docSnapshots) async {
        if (docSnapshots.isEmpty) return;
        ref.read(isSyncingProvider.notifier).setSyncing(true);
        try {
          for (final doc in docSnapshots) {
            final data = doc.data();
            if (data != null) {
              await noteProcessor.processIncomingCloudItem(data, targetWorkspaceId: activeWorkspace.id);
            }
          }
        } finally {
          ref.read(isSyncingProvider.notifier).setSyncing(false);
        }
      },
      onError: (e, st) {
        AppLogger.e("CloudSyncService: Error in note realtime stream", error: e, stack: st);
      },
    );
  }

  /// Master sync coordinator executing entity processors in strict dependency order:
  /// Stage 1: Workspace Manifest Sync (Level 0)
  /// Stage 2: Active Workspace Content Sync (Level 1 Folders -> Level 2 Notes)
  Future<void> executeFullSync({bool isUserInitiated = false}) async {
    if (!_isRunning || _isExecutingFullSync || ref.read(activeWorkspaceProvider.notifier).isSwitching) return;

    final firebaseDb = ref.read(noteFirebaseDatabaseProvider);
    if (firebaseDb == null) {
      AppLogger.w("CloudSyncService: Cannot sync. NoteFirestoreDatabase is null.");
      return;
    }

    _isExecutingFullSync = true;
    final activeWorkspace = ref.read(activeWorkspaceProvider);
    AppLogger.d("CloudSyncService: Executing prioritized sync for active workspace ${activeWorkspace.name} (${activeWorkspace.id}) [isUserInitiated: $isUserInitiated]...");

    if (isUserInitiated) {
      ref.read(isSyncingProvider.notifier).setSyncing(true);
    }

    try {
      final prefs = ref.read(sharedPreferenceProvider);
      final lastSyncTime = prefs.lastCloudSyncTime;
      int totalItemsTransferred = 0;

      // STAGE 1: WORKSPACE MANIFEST SYNC (Level 0)
      final workspaceProcessor = ref.read(cloudWorkspaceProcessorProvider);
      final pushedWorkspaces = await workspaceProcessor.pushPendingChanges(firebaseDb);
      final pulledWorkspaces = await workspaceProcessor.pullRemoteChanges(firebaseDb, lastSyncTime);
      totalItemsTransferred += pushedWorkspaces + pulledWorkspaces;

      if (totalItemsTransferred > 0 && !isUserInitiated) {
        ref.read(isSyncingProvider.notifier).setSyncing(true);
      }

      // STAGE 2: ACTIVE WORKSPACE CONTENT SYNC (Level 1 Folders -> Level 2 Notes)
      final activeWorkspaceProcessors = _processors.where((p) => p.dependencyLevel > 0).toList()
        ..sort((a, b) => a.dependencyLevel.compareTo(b.dependencyLevel));

      for (final processor in activeWorkspaceProcessors) {
        final pushed = await processor.pushPendingChanges(firebaseDb, targetWorkspaceId: activeWorkspace.id);
        final pulled = await processor.pullRemoteChanges(firebaseDb, lastSyncTime, targetWorkspaceId: activeWorkspace.id);
        
        final stageTransferred = pushed + pulled;
        if (stageTransferred > 0 && totalItemsTransferred == 0 && !isUserInitiated) {
          ref.read(isSyncingProvider.notifier).setSyncing(true);
        }
        totalItemsTransferred += stageTransferred;
      }

      // UPDATE GLOBAL LAST SYNC TIMESTAMP
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setLastCloudSyncTime(now);

      AppLogger.d("CloudSyncService: Prioritized sync completed successfully for active workspace ${activeWorkspace.name} (Total items transferred: $totalItemsTransferred).");
    } catch (e, st) {
      AppLogger.e("CloudSyncService: Error executing full sync", error: e, stack: st);
    } finally {
      _isExecutingFullSync = false;
      ref.read(isSyncingProvider.notifier).setSyncing(false);
    }
  }
}
