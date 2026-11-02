import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/database/drift/synced_devices/synced_devices_dao.dart';
import 'sync_entity_processor.dart';

final noteSyncProcessorProvider = Provider<NoteSyncProcessor>((ref) {
  return NoteSyncProcessor(ref);
});

class NoteSyncProcessor extends SyncEntityProcessor {
  NoteSyncProcessor(super.ref);

  @override
  String get entityName => 'note';

  @override
  String get batchType => 'sync_batch';

  @override
  String get ackType => 'ack_batch';

  @override
  Future<List<Map<String, dynamic>>> getPendingLocalChanges() async {
    final notesDao = ref.read(notesDaoProvider);
    final pendingNotes = await notesDao.getPendingLocalNotes();
    return pendingNotes.map((note) => note.toJson()).toList();
  }

  @override
  Future<List<String>> processIncomingLocalBatch(List<dynamic> incomingList) async {
    final notesDao = ref.read(notesDaoProvider);
    final syncedDevicesDao = ref.read(syncedDevicesDaoProvider);

    final uuidsToAck = <String>[];

    for (final item in incomingList) {
      if (item is! Map<String, dynamic>) continue;

      try {
        final noteUuid = item['uuid'] as String?;
        if (noteUuid == null) continue;

        await notesDao.upsertNoteFromLocal(item);

        final peerUuid = item['last_edited_by_device_id'] as String?;
        final peerName = item['last_edited_by_device_name'] as String?;
        final peerPlatform = item['last_edited_by_device_platform'] as String?;

        if (peerUuid != null) {
          await syncedDevicesDao.upsertDeviceAsClient(
            uuid: peerUuid,
            name: peerName ?? 'Unknown Device',
            deviceType: peerPlatform ?? 'unknown',
          );
        }

        uuidsToAck.add(noteUuid);
      } catch (e, st) {
        AppLogger.e('NoteSyncProcessor: Failed to process incoming note', error: e, stack: st);
      }
    }

    return uuidsToAck;
  }

  @override
  Future<void> markAsLocalSynced(List<String> uuids) async {
    final notesDao = ref.read(notesDaoProvider);
    await notesDao.markAsLocalSynced(uuids);
  }
}
