import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/folders/folders_dao.dart';
import '../core/sync_entity_processor.dart';

final folderSyncProcessorProvider = Provider<FolderSyncProcessor>((ref) {
  final dao = ref.watch(foldersDaoProvider);
  return FolderSyncProcessor(dao);
});

class FolderSyncProcessor extends SyncEntityProcessor {
  final FoldersDao foldersDao;

  FolderSyncProcessor(this.foldersDao);

  @override
  String get entityName => 'folder';

  @override
  List<SyncEntityProcessor> get dependencies => [];

  // --- LOCAL WI-FI SYNC ---

  @override
  Future<List<Map<String, dynamic>>> getPendingLocalChanges() async {
    final pendingFolders = await foldersDao.getPendingLocalFolders();
    return pendingFolders.map((f) => f.toJson()).toList();
  }

  @override
  Future<List<String>> processIncomingLocalBatch(List<dynamic> items) async {
    final uuidsToAck = <String>[];
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        await foldersDao.upsertFolderFromLocal(item);
        if (item['uuid'] != null) {
          uuidsToAck.add(item['uuid'] as String);
        }
      }
    }
    return uuidsToAck;
  }

  @override
  Future<void> markAsLocalSynced(Iterable<String> uuids) async {
    await foldersDao.markAsLocalSynced(uuids);
  }

  // --- CLOUD FIREBASE SYNC ---

  @override
  Future<List<Map<String, dynamic>>> getPendingCloudChanges() async {
    final pendingFolders = await foldersDao.getPendingCloudFolders();
    return pendingFolders.map((f) => f.toJson()).toList();
  }

  @override
  Future<List<String>> processIncomingCloudBatch(List<Map<String, dynamic>> items) async {
    final processedUuids = <String>[];
    for (final item in items) {
      await foldersDao.upsertFolderFromCloud(item);
      if (item['uuid'] != null) {
        processedUuids.add(item['uuid'] as String);
      }
    }
    return processedUuids;
  }

  @override
  Future<void> markAsCloudSynced(Iterable<String> uuids) async {
    await foldersDao.markAsCloudSynced(uuids);
  }
}
