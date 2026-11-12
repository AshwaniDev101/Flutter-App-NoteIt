import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/util/logger.dart';
import '../../../../database/drift/folders/folders_dao.dart';
import '../../../../database/firebase/firebase_database.dart';
import '../../../workspace/providers/active_workspace_provider.dart';
import 'cloud_entity_processor.dart';

final cloudFolderProcessorProvider = Provider<CloudFolderProcessor>((ref) {
  return CloudFolderProcessor(ref);
});

class CloudFolderProcessor extends CloudEntityProcessor {
  CloudFolderProcessor(super.ref);

  @override
  String get entityName => 'folder';

  @override
  String get collectionName => 'folders';

  @override
  int get dependencyLevel => 1;

  @override
  Future<void> pushPendingChanges(NoteFirestoreDatabase firebaseDb, {String? targetWorkspaceId}) async {
    final wsId = targetWorkspaceId ?? firebaseDb.profileId;
    try {
      final foldersDao = ref.read(foldersDaoProvider);
      final pendingFolders = await foldersDao.getPendingCloudFolders();
      if (pendingFolders.isEmpty) {
        AppLogger.d('CloudFolderProcessor: No pending folders to push for workspace $wsId.');
        return;
      }

      final folderMaps = pendingFolders.map((f) => f.toJson()).toList();
      await firebaseDb.pushBatch('folders', folderMaps, targetWorkspaceId: targetWorkspaceId);
      await foldersDao.markAsCloudSynced(pendingFolders.map((f) => f.uuid));
      AppLogger.d('CloudFolderProcessor: Pushed ${pendingFolders.length} pending folders for workspace $wsId.');
    } catch (e, st) {
      AppLogger.e('CloudFolderProcessor: Failed to push pending folders for workspace $wsId', error: e, stack: st);
    }
  }

  @override
  Future<void> pullRemoteChanges(NoteFirestoreDatabase firebaseDb, int lastSyncTime, {String? targetWorkspaceId}) async {
    final wsId = targetWorkspaceId ?? firebaseDb.profileId;
    try {
      final remoteDocs = await firebaseDb.pullChanges('folders', lastSyncTime, targetWorkspaceId: targetWorkspaceId);
      if (remoteDocs.isEmpty) {
        AppLogger.d('CloudFolderProcessor: No remote folders found since lastSyncTime: $lastSyncTime for workspace $wsId.');
        return;
      }
      for (final doc in remoteDocs) {
        final data = doc.data();
        await processIncomingCloudItem(data, targetWorkspaceId: targetWorkspaceId);
      }
      AppLogger.d('CloudFolderProcessor: Pulled and merged ${remoteDocs.length} folders from cloud for workspace $wsId.');
    } catch (e, st) {
      AppLogger.e('CloudFolderProcessor: Failed to pull remote folders for workspace $wsId', error: e, stack: st);
    }
  }

  @override
  Future<void> processIncomingCloudItem(Map<String, dynamic> data, {String? targetWorkspaceId}) async {
    try {
      final activeWorkspace = ref.read(activeWorkspaceProvider);
      final itemWorkspaceId = targetWorkspaceId ?? activeWorkspace.id;

      if (itemWorkspaceId != activeWorkspace.id) {
        AppLogger.w('CloudFolderProcessor: Skipped incoming folder ${data['uuid']} (${data['name']}) because item workspace ($itemWorkspaceId) != active workspace (${activeWorkspace.id})');
        return;
      }

      final foldersDao = ref.read(foldersDaoProvider);
      await foldersDao.upsertFolderFromCloud(data);
      AppLogger.d('CloudFolderProcessor: Merged folder ${data['uuid']} (${data['name']})');
    } catch (e, st) {
      AppLogger.e('CloudFolderProcessor: Failed to process incoming cloud folder ${data['uuid']}', error: e, stack: st);
    }
  }
}
