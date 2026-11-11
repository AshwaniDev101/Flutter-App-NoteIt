import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/util/logger.dart';
import '../../../../database/drift/folders/folders_dao.dart';
import '../../../../database/firebase/firebase_database.dart';
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
    try {
      final foldersDao = ref.read(foldersDaoProvider);
      final pendingFolders = await foldersDao.getPendingCloudFolders();
      if (pendingFolders.isEmpty) return;

      final folderMaps = pendingFolders.map((f) => f.toJson()).toList();
      await firebaseDb.pushBatch('folders', folderMaps, targetWorkspaceId: targetWorkspaceId);
      await foldersDao.markAsCloudSynced(pendingFolders.map((f) => f.uuid));
      AppLogger.d('CloudFolderProcessor: Pushed ${pendingFolders.length} pending folders for workspace ${targetWorkspaceId ?? firebaseDb.profileId}.');
    } catch (e, st) {
      AppLogger.e('CloudFolderProcessor: Failed to push pending folders', error: e, stack: st);
    }
  }

  @override
  Future<void> pullRemoteChanges(NoteFirestoreDatabase firebaseDb, int lastSyncTime, {String? targetWorkspaceId}) async {
    try {
      final remoteDocs = await firebaseDb.pullChanges('folders', lastSyncTime, targetWorkspaceId: targetWorkspaceId);
      for (final doc in remoteDocs) {
        final data = doc.data();
        await processIncomingCloudItem(data, targetWorkspaceId: targetWorkspaceId);
      }
      if (remoteDocs.isNotEmpty) {
        AppLogger.d('CloudFolderProcessor: Pulled and merged ${remoteDocs.length} folders from cloud.');
      }
    } catch (e, st) {
      AppLogger.e('CloudFolderProcessor: Failed to pull remote folders', error: e, stack: st);
    }
  }

  @override
  Future<void> processIncomingCloudItem(Map<String, dynamic> data, {String? targetWorkspaceId}) async {
    try {
      final foldersDao = ref.read(foldersDaoProvider);
      await foldersDao.upsertFolderFromCloud(data);
      AppLogger.d('CloudFolderProcessor: Merged folder ${data['uuid']}');
    } catch (e, st) {
      AppLogger.e('CloudFolderProcessor: Failed to process incoming cloud folder ${data['uuid']}', error: e, stack: st);
    }
  }
}
