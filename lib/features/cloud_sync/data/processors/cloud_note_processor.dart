import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/util/logger.dart';
import '../../../../database/drift/notes/notes_dao.dart';
import '../../../../database/firebase/firebase_database.dart';
import '../../../workspace/providers/active_workspace_provider.dart';
import 'cloud_entity_processor.dart';

final cloudNoteProcessorProvider = Provider<CloudNoteProcessor>((ref) {
  return CloudNoteProcessor(ref);
});

class CloudNoteProcessor extends CloudEntityProcessor {
  CloudNoteProcessor(super.ref);

  @override
  String get entityName => 'note';

  @override
  String get collectionName => 'notes';

  @override
  int get dependencyLevel => 2;

  @override
  Future<void> pushPendingChanges(NoteFirestoreDatabase firebaseDb, {String? targetWorkspaceId}) async {
    final wsId = targetWorkspaceId ?? firebaseDb.profileId;
    try {
      final notesDao = ref.read(notesDaoProvider);
      final pendingNotes = await notesDao.getPendingCloudNotes();
      if (pendingNotes.isEmpty) {
        AppLogger.d('CloudNoteProcessor: No pending notes to push for workspace $wsId.');
        return;
      }

      final noteMaps = pendingNotes.map((n) => n.toJson()).toList();
      await firebaseDb.pushBatch('notes', noteMaps, targetWorkspaceId: targetWorkspaceId);
      await notesDao.markAsCloudSynced(pendingNotes.map((n) => n.uuid));
      AppLogger.d('CloudNoteProcessor: Pushed ${pendingNotes.length} pending notes for workspace $wsId.');
    } catch (e, st) {
      AppLogger.e('CloudNoteProcessor: Failed to push pending notes for workspace $wsId', error: e, stack: st);
    }
  }

  @override
  Future<void> pullRemoteChanges(NoteFirestoreDatabase firebaseDb, int lastSyncTime, {String? targetWorkspaceId}) async {
    final wsId = targetWorkspaceId ?? firebaseDb.profileId;
    try {
      final remoteDocs = await firebaseDb.pullChanges('notes', lastSyncTime, targetWorkspaceId: targetWorkspaceId);
      if (remoteDocs.isEmpty) {
        AppLogger.d('CloudNoteProcessor: No remote notes found since lastSyncTime: $lastSyncTime for workspace $wsId.');
        return;
      }
      for (final doc in remoteDocs) {
        final data = doc.data();
        await processIncomingCloudItem(data, targetWorkspaceId: targetWorkspaceId);
      }
      AppLogger.d('CloudNoteProcessor: Pulled and merged ${remoteDocs.length} notes from cloud for workspace $wsId.');
    } catch (e, st) {
      AppLogger.e('CloudNoteProcessor: Failed to pull remote notes for workspace $wsId', error: e, stack: st);
    }
  }

  @override
  Future<void> processIncomingCloudItem(Map<String, dynamic> data, {String? targetWorkspaceId}) async {
    try {
      final activeWorkspace = ref.read(activeWorkspaceProvider);
      final itemWorkspaceId = targetWorkspaceId ?? activeWorkspace.id;

      if (itemWorkspaceId != activeWorkspace.id) {
        AppLogger.w('CloudNoteProcessor: Skipped incoming note ${data['uuid']} (${data['title']}) because item workspace ($itemWorkspaceId) != active workspace (${activeWorkspace.id})');
        return;
      }

      final notesDao = ref.read(notesDaoProvider);
      await notesDao.upsertNoteFromCloud(data);
      AppLogger.d('CloudNoteProcessor: Merged note ${data['uuid']} (${data['title']})');
    } catch (e, st) {
      AppLogger.e('CloudNoteProcessor: Failed to process incoming cloud note ${data['uuid']}', error: e, stack: st);
    }
  }
}
