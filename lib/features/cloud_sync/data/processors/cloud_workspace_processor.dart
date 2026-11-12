import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/util/logger.dart';
import '../../../../database/firebase/firebase_database.dart';
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
  Future<void> pushPendingChanges(NoteFirestoreDatabase firebaseDb, {String? targetWorkspaceId}) async {
    try {
      final repo = WorkspaceRepository.instance;
      final localWorkspaces = repo.getWorkspaces();
      if (localWorkspaces.isEmpty) return;

      final manifestMaps = localWorkspaces.map((w) => w.toJson()).toList();
      await firebaseDb.pushProfileManifest(manifestMaps);
      AppLogger.d('CloudWorkspaceProcessor: Pushed ${manifestMaps.length} workspace manifest items to cloud.');
    } catch (e, st) {
      AppLogger.e('CloudWorkspaceProcessor: Failed to push workspace manifest', error: e, stack: st);
    }
  }

  @override
  Future<void> pullRemoteChanges(NoteFirestoreDatabase firebaseDb, int lastSyncTime, {String? targetWorkspaceId}) async {
    try {
      final remoteDocs = await firebaseDb.pullProfileManifest();
      for (final doc in remoteDocs) {
        final data = doc.data();
        await processIncomingCloudItem(data, targetWorkspaceId: targetWorkspaceId);
      }
      if (remoteDocs.isNotEmpty) {
        AppLogger.d('CloudWorkspaceProcessor: Pulled ${remoteDocs.length} workspace manifest items from cloud.');
      }
    } catch (e, st) {
      AppLogger.e('CloudWorkspaceProcessor: Failed to pull workspace manifest', error: e, stack: st);
    }
  }

  @override
  Future<void> processIncomingCloudItem(Map<String, dynamic> data, {String? targetWorkspaceId}) async {
    try {
      final incomingWorkspace = Workspace.fromJson(data);
      final repo = WorkspaceRepository.instance;
      final existing = repo.getWorkspaceById(incomingWorkspace.id);

      if (existing == null) {
        await repo.upsertWorkspace(incomingWorkspace);
        ref.read(workspacesListProvider.notifier).refresh();
        AppLogger.d('CloudWorkspaceProcessor: Discovered and upserted new remote workspace "${incomingWorkspace.name}" (${incomingWorkspace.id})');
      } else {
        final isDifferentName = incomingWorkspace.name != existing.name;
        final isNewerCounter = incomingWorkspace.updateCounter > existing.updateCounter;
        final isNewerTime = incomingWorkspace.lastUsedAt.isAfter(existing.lastUsedAt);
        final isSoftDeleted = incomingWorkspace.deletedAt != null && existing.deletedAt == null;

        if (isDifferentName || isNewerCounter || isNewerTime || isSoftDeleted) {
          await repo.upsertWorkspace(incomingWorkspace);
          ref.read(workspacesListProvider.notifier).refresh();
          AppLogger.d('CloudWorkspaceProcessor: Merged workspace update for ${incomingWorkspace.name}');
        }
      }

      // Edge case safety: If active workspace was deleted on another device, switch to default workspace
      if (incomingWorkspace.deletedAt != null && ref.read(activeWorkspaceProvider).id == incomingWorkspace.id) {
        AppLogger.w('CloudWorkspaceProcessor: Active workspace "${incomingWorkspace.name}" was remotely deleted! Switching to default workspace...');
        await ref.read(activeWorkspaceProvider.notifier).switchWorkspace(WorkspaceRepository.defaultWorkspace);
      }
    } catch (e, st) {
      AppLogger.e('CloudWorkspaceProcessor: Failed to process incoming workspace item', error: e, stack: st);
    }
  }
}
