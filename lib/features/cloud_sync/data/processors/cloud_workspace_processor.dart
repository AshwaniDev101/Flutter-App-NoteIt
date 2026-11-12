import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/util/logger.dart';
import '../../../../database/firebase/firebase_database.dart';
import '../../../../database/shared_preference/shared_preference_manager.dart';
import '../../../workspace/data/workspace_repository.dart';
import '../../../workspace/models/workspace_model.dart';
import '../../../workspace/providers/active_workspace_provider.dart';
import '../../../workspace/providers/workspace_providers.dart';
import 'cloud_entity_processor.dart';

final cloudWorkspaceProcessorProvider = Provider<CloudWorkspaceProcessor>((ref) {
  return CloudWorkspaceProcessor(ref);
});

class CloudWorkspaceProcessor extends CloudEntityProcessor {
  CloudWorkspaceProcessor(super.ref);

  @override
  String get entityName => 'workspace';

  @override
  String get collectionName => 'workspaces_manifest';

  @override
  int get dependencyLevel => 0;

  @override
  Future<int> pushPendingChanges(NoteFirestoreDatabase firebaseDb, {String? targetWorkspaceId}) async {
    try {
      final repo = WorkspaceRepository.instance;
      final localWorkspaces = repo.getWorkspaces();
      if (localWorkspaces.isEmpty) return 0;

      final prefs = ref.read(sharedPreferenceProvider);
      final lastSyncTime = prefs.lastCloudSyncTime;

      final pendingWorkspaces = localWorkspaces.where((w) => !w.isCloudSynced).toList();
      final hasPending = lastSyncTime == 0 || pendingWorkspaces.isNotEmpty;

      if (!hasPending) return 0;

      final manifestMaps = localWorkspaces.map((w) => w.toJson()).toList();
      await firebaseDb.pushProfileManifest(manifestMaps);
      await repo.markAsCloudSynced(localWorkspaces.map((w) => w.id).toList());

      AppLogger.d('CloudWorkspaceProcessor: Pushed ${manifestMaps.length} workspace manifest items to cloud.');
      return manifestMaps.length;
    } catch (e, st) {
      AppLogger.e('CloudWorkspaceProcessor: Failed to push workspace manifest', error: e, stack: st);
      return 0;
    }
  }

  @override
  Future<int> pullRemoteChanges(NoteFirestoreDatabase firebaseDb, int lastSyncTime, {String? targetWorkspaceId}) async {
    try {
      final remoteDocs = await firebaseDb.pullProfileManifest();
      if (remoteDocs.isEmpty) return 0;

      int mergedCount = 0;
      for (final doc in remoteDocs) {
        final data = doc.data();
        final wasMerged = await processIncomingCloudItem(data, targetWorkspaceId: targetWorkspaceId);
        if (wasMerged) mergedCount++;
      }
      if (mergedCount > 0) {
        AppLogger.d('CloudWorkspaceProcessor: Pulled and merged $mergedCount workspace manifest items from cloud.');
      }
      return mergedCount;
    } catch (e, st) {
      AppLogger.e('CloudWorkspaceProcessor: Failed to pull workspace manifest', error: e, stack: st);
      return 0;
    }
  }

  @override
  Future<bool> processIncomingCloudItem(Map<String, dynamic> data, {String? targetWorkspaceId}) async {
    try {
      final incomingWorkspace = Workspace.fromJson(data).copyWith(isCloudSynced: true);
      final repo = WorkspaceRepository.instance;
      final existing = repo.getWorkspaceById(incomingWorkspace.id);

      if (existing == null) {
        await repo.upsertWorkspace(incomingWorkspace);
        ref.read(workspacesListProvider.notifier).refresh();
        AppLogger.d('CloudWorkspaceProcessor: Discovered and upserted new remote workspace "${incomingWorkspace.name}" (${incomingWorkspace.id})');
        return true;
      } else {
        final isDifferentName = incomingWorkspace.name != existing.name;
        final isNewerCounter = incomingWorkspace.updateCounter > existing.updateCounter;
        final isNewerTime = incomingWorkspace.lastUsedAt.isAfter(existing.lastUsedAt);
        final isSoftDeleted = incomingWorkspace.deletedAt != null && existing.deletedAt == null;

        if (isDifferentName || isNewerCounter || isNewerTime || isSoftDeleted) {
          await repo.upsertWorkspace(incomingWorkspace);
          ref.read(workspacesListProvider.notifier).refresh();
          AppLogger.d('CloudWorkspaceProcessor: Merged workspace update for ${incomingWorkspace.name}');
          return true;
        }
      }

      // Edge case safety: If active workspace was deleted on another device, switch to default workspace
      if (incomingWorkspace.deletedAt != null && ref.read(activeWorkspaceProvider).id == incomingWorkspace.id) {
        AppLogger.w('CloudWorkspaceProcessor: Active workspace "${incomingWorkspace.name}" was remotely deleted! Switching to default workspace...');
        await ref.read(activeWorkspaceProvider.notifier).switchWorkspace(WorkspaceRepository.defaultWorkspace);
      }
      return false;
    } catch (e, st) {
      AppLogger.e('CloudWorkspaceProcessor: Failed to process incoming workspace item', error: e, stack: st);
      return false;
    }
  }
}
