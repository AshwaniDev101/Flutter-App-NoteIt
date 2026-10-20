import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import '../core/sync_entity_processor.dart';
import 'folder_sync_processor.dart';

final noteSyncProcessorProvider = Provider<NoteSyncProcessor>((ref) {
  final dao = ref.watch(notesDaoProvider);
  final folderProcessor = ref.watch(folderSyncProcessorProvider);
  return NoteSyncProcessor(dao, folderProcessor);
});

class NoteSyncProcessor extends SyncEntityProcessor {
  final NotesDao notesDao;
  final FolderSyncProcessor folderSyncProcessor;

  NoteSyncProcessor(this.notesDao, this.folderSyncProcessor);

  @override
  String get entityName => 'note';

  @override
  List<SyncEntityProcessor> get dependencies => [folderSyncProcessor];

  // --- LOCAL WI-FI SYNC ---

  @override
  Future<List<Map<String, dynamic>>> getPendingLocalChanges() async {
    final pendingNotes = await notesDao.getPendingLocalNotes();
    return pendingNotes.map((n) => n.toJson()).toList();
  }

  @override
  Future<List<String>> processIncomingLocalBatch(List<dynamic> items) async {
    final uuidsToAck = <String>[];
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        await notesDao.upsertNoteFromLocal(item);
        if (item['uuid'] != null) {
          uuidsToAck.add(item['uuid'] as String);
        }
      }
    }
    return uuidsToAck;
  }

  @override
  Future<void> markAsLocalSynced(Iterable<String> uuids) async {
    await notesDao.markAsLocalSynced(uuids);
  }

  // --- CLOUD FIREBASE SYNC ---

  @override
  Future<List<Map<String, dynamic>>> getPendingCloudChanges() async {
    final pendingNotes = await notesDao.getPendingCloudNotes();
    return pendingNotes.map((n) => n.toJson()).toList();
  }

  @override
  Future<List<String>> processIncomingCloudBatch(List<Map<String, dynamic>> items) async {
    final processedUuids = <String>[];
    for (final item in items) {
      await notesDao.upsertNoteFromCloud(item);
      if (item['uuid'] != null) {
        processedUuids.add(item['uuid'] as String);
      }
    }
    return processedUuids;
  }

  @override
  Future<void> markAsCloudSynced(Iterable<String> uuids) async {
    await notesDao.markAsCloudSynced(uuids);
  }
}
