import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/drift/folders/folders_dao.dart';
import 'sync_entity_processor.dart';

final folderSyncProcessorProvider = Provider<FolderSyncProcessor>((ref) {
  return FolderSyncProcessor(ref);
});

class FolderSyncProcessor extends SyncEntityProcessor {
  FolderSyncProcessor(super.ref);

  @override
  String get entityName => 'folder';

  @override
  String get batchType => 'folder_sync_batch';

  @override
  String get ackType => 'folder_ack_batch';

  @override
  Future<List<Map<String, dynamic>>> getPendingLocalChanges() async {
    final foldersDao = ref.read(foldersDaoProvider);
    final pendingFolders = await foldersDao.getPendingLocalFolders();
    return pendingFolders.map((folder) => folder.toJson()).toList();
  }

  @override
  Future<List<String>> processIncomingLocalBatch(List<dynamic> incomingList) async {
    final foldersDao = ref.read(foldersDaoProvider);
    final uuidsToAck = <String>[];

    for (final item in incomingList) {
      if (item is! Map<String, dynamic>) continue;

      try {
        final folderUuid = item['uuid'] as String?;
        if (folderUuid == null) continue;

        await foldersDao.upsertFolderFromLocal(item);
        uuidsToAck.add(folderUuid);
      } catch (e, st) {
        AppLogger.e('FolderSyncProcessor: Failed to process incoming folder', error: e, stack: st);
      }
    }

    return uuidsToAck;
  }

  @override
  Future<void> markAsLocalSynced(List<String> uuids) async {
    final foldersDao = ref.read(foldersDaoProvider);
    await foldersDao.markAsLocalSynced(uuids);
  }
}
