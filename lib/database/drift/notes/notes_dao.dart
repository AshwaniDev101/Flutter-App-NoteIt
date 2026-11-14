import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/helpers/time_helper.dart';
import '../../../core/util/hlc.dart';
import '../../../core/util/logger.dart';
import '../../../features/lock/crypto/reencryption_isolate.dart';
import '../../shared_preference/shared_preference_manager.dart';
import '../folders/folders_table.dart';
import '../local_database.dart';
import 'notes_table.dart';

part 'notes_dao.g.dart';

final notesDaoProvider = Provider((ref) => ref.watch(localDatabaseProvider).notesDao);

/// Database sorting options for active notes query
enum NoteSortPreference { name, createdAt, updatedAt, folder, reminderAt }

class NoteWithFolder {
  final Note note;
  final Folder? folder;

  NoteWithFolder({required this.note, this.folder});
}

@DriftAccessor(tables: [Notes, Folders])
class NotesDao extends DatabaseAccessor<LocalDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  String _generateHlc({int counter = 1, DateTime? lastKnownTime}) {
    final deviceId = SharedPreferenceManager.instance.hostUuid;
    return Hlc.generate(
      deviceId: deviceId,
      counter: counter,
      lastKnownTime: lastKnownTime,
    );
  }

  // =========================================================================
  // STANDARD LOCAL CRUD OPERATIONS
  // =========================================================================

  Future<String> addNote({
    required String title,
    required String content,
    String? folderId,
    String? creationPlatform,
    String? creationDevice,
    required int contentVersion,
  }) async {
    final newUuid = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final initialHlc = _generateHlc(counter: 1, lastKnownTime: now);

    await into(notes).insert(
      NotesCompanion.insert(
        uuid: Value(newUuid),
        title: title,
        content: content,
        folderId: Value(folderId),
        creationPlatform: Value(creationPlatform),
        creationDevice: Value(creationDevice),
        createdAt: Value(now),
        updatedAt: Value(now),
        updateCounter: const Value(1),
        hlc: Value(initialHlc),
        cloudSyncStatus: const Value(0),
        localSyncStatus: const Value(0),
        contentVersion: Value(contentVersion),
      ),
    );
    AppLogger.d("NotesDao: Added new note '$title' (uuid: $newUuid)");
    return newUuid;
  }

  Future<bool> updateNote({
    required String uuid,
    required String title,
    required String content,
    required int contentVersion,
    List<int>? masterKeyBytes,
  }) async {
    return await transaction(() async {
      final existing = await (select(notes)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
      final newCounter = (existing?.updateCounter ?? 0) + 1;
      final now = DateTime.now().toUtc();
      final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

      String finalContent = content;
      String? encryptedPayload;
      String? encryptionIv;

      // EXPLICIT PLAIN TEXT CONTENT NULLIFICATION FOR LOCKED NOTES:
      // If note is locked, encrypt content and clear plain text content column to empty string
      if (existing != null && existing.lockedAt != null) {
        if (masterKeyBytes == null) {
          AppLogger.e('NotesDao: Cannot update locked note $uuid without masterKeyBytes.');
          return false;
        }
        final encrypted = await CryptoEngine.encryptPayload(content, masterKeyBytes);
        encryptedPayload = jsonEncode({
          'ciphertext': encrypted['ciphertext'],
          'authTag': encrypted['authTag'],
        });
        encryptionIv = encrypted['iv'];
        finalContent = ''; // Explicitly nullify plain text content column
      }

      final success = await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
            NotesCompanion.custom(
              title: Variable(title),
              content: Variable(finalContent),
              encryptedPayload: Variable(encryptedPayload),
              encryptionIv: Variable(encryptionIv),
              cloudSyncStatus: const Variable(0),
              localSyncStatus: const Variable(0),
              updatedAt: Variable(now),
              updateCounter: Variable(newCounter),
              hlc: Variable(newHlc),
              contentVersion: Variable(contentVersion),
            ),
          ) >
          0;
      if (success) {
        AppLogger.d("NotesDao: Updated note '$title' (uuid: $uuid)");
      }
      return success;
    });
  }

  Stream<List<Note>> watchAllNotes() {
    return select(notes).watch();
  }

  /// Stream the total count of active (non-deleted, non-archived) notes across all folders.
  Stream<int> watchActiveNotesCount() {
    final countExpression = notes.uuid.count();
    final query = selectOnly(notes)
      ..addColumns([countExpression])
      ..where(notes.deletedAt.isNull() & notes.archivedAt.isNull());

    return query.watchSingle().map((row) => row.read(countExpression) ?? 0);
  }

  /// Watches active (non-deleted, non-archived) notes sorted directly by SQLite:
  /// 1. Pinned notes first (pinnedAt IS NOT NULL), sorted by pinnedAt timestamp descending.
  /// 2. Unpinned notes sorted according to [sortOption] (name, createdAt, or updatedAt).

  Stream<List<NoteWithFolder>> watchSortedNotes(NoteSortPreference sortOption) {
    final query = select(notes).join([
      leftOuterJoin(folders, folders.uuid.equalsExp(notes.folderId)),
    ]);

    query.where(notes.deletedAt.isNull() & notes.archivedAt.isNull());

    query.orderBy([
      // Pinned notes first, newest pinned first
      OrderingTerm(expression: notes.pinnedAt, mode: OrderingMode.desc, nulls: NullsOrder.last),
      // Secondary sort choice
      if (sortOption == NoteSortPreference.name)
        OrderingTerm(expression: notes.title.collate(Collate.noCase), mode: OrderingMode.asc)
      else if (sortOption == NoteSortPreference.createdAt)
        OrderingTerm(expression: notes.createdAt, mode: OrderingMode.desc)
      else if (sortOption == NoteSortPreference.updatedAt)
        OrderingTerm(expression: notes.updatedAt, mode: OrderingMode.desc)
      else if (sortOption == NoteSortPreference.folder) ...[
        OrderingTerm(expression: folders.name.collate(Collate.noCase), mode: OrderingMode.asc, nulls: NullsOrder.last),
        OrderingTerm(expression: notes.updatedAt, mode: OrderingMode.desc),
      ]
      else if (sortOption == NoteSortPreference.reminderAt) ...[
        OrderingTerm(expression: notes.reminderAt, mode: OrderingMode.asc, nulls: NullsOrder.last),
        OrderingTerm(expression: notes.updatedAt, mode: OrderingMode.desc),
      ],
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return NoteWithFolder(
          note: row.readTable(notes),
          // readTableOrNull handles the LEFT JOIN where a folder might not exist
          folder: row.readTableOrNull(folders),
        );
      }).toList();
    });
  }

  /// Fetches a single note and its folder.
  Future<NoteWithFolder> getNoteById(String uuid) {
    final query = select(notes).join([
      leftOuterJoin(folders, folders.uuid.equalsExp(notes.folderId)),
    ])..where(notes.uuid.equals(uuid));

    return query.map((row) => NoteWithFolder(
      note: row.readTable(notes),
      folder: row.readTableOrNull(folders),
    )).getSingle();
  }

  /// Decrypts the content of a locked note using [masterKeyBytes].
  /// Returns the decrypted plain text content, or [note.content] if not locked or decryption fails.
  Future<String> getDecryptedNoteContent(Note note, List<int>? masterKeyBytes) async {
    if (note.lockedAt == null || note.encryptedPayload == null || note.encryptionIv == null) {
      return note.content;
    }
    if (masterKeyBytes == null) {
      return note.content;
    }
    try {
      String ciphertextBase64 = note.encryptedPayload!;
      String authTagBase64 = note.encryptedPayload!;
      if (note.encryptedPayload!.startsWith('{')) {
        final map = jsonDecode(note.encryptedPayload!) as Map<String, dynamic>;
        ciphertextBase64 = map['ciphertext'] as String? ?? ciphertextBase64;
        authTagBase64 = map['authTag'] as String? ?? authTagBase64;
      }

      return await CryptoEngine.decryptPayload(
        ciphertextBase64: ciphertextBase64,
        ivBase64: note.encryptionIv!,
        authTagBase64: authTagBase64,
        masterKey: masterKeyBytes,
      );
    } catch (e) {
      AppLogger.w('NotesDao: Failed to decrypt content for note ${note.uuid}: $e');
      return note.content;
    }
  }

  Future<int> deleteNote(String uuid) async {
    // Hard Delete
    final count = await (delete(notes)..where((t) => t.uuid.equals(uuid))).go();
    AppLogger.d("NotesDao: Hard-deleted note (uuid: $uuid)");
    return count;
  }

  Future<void> softDeleteNotes(Iterable<String> uuids, {required String platform}) async {
    await transaction(() async {
      final targetNotes = await (select(notes)..where((t) => t.uuid.isIn(uuids))).get();
      final now = DateTime.now().toUtc();

      for (final note in targetNotes) {
        final newCounter = note.updateCounter + 1;
        final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

        await (update(notes)..where((t) => t.uuid.equals(note.uuid))).write(
          NotesCompanion.custom(
            deletedAt: Variable(now),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(now),
            deletedPlatform: Variable(platform),
            updateCounter: Variable(newCounter),
            hlc: Variable(newHlc),
          ),
        );
      }
      AppLogger.d("NotesDao: Soft-deleted ${targetNotes.length} notes (uuids: $uuids)");
    });
  }

  /// Updates only the folder assignment of a note and triggers sync workers
  Future<bool> updateNoteFolder(String uuid, String? folderId) async {
    return await transaction(() async {
      final existing = await (select(notes)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
      final newCounter = (existing?.updateCounter ?? 0) + 1;
      final now = DateTime.now().toUtc();
      final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

      final success = await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
        NotesCompanion.custom(
          folderId: Variable(folderId),
          cloudSyncStatus: const Variable(0),
          localSyncStatus: const Variable(0),
          updatedAt: Variable(now),
          updateCounter: Variable(newCounter),
          hlc: Variable(newHlc),
        ),
      ) > 0;
      if (success) {
        AppLogger.d("NotesDao: Updated folder assignment for note $uuid to folder $folderId");
      }
      return success;
    });
  }

  Future<bool> lockNote(
    String uuid, {
    required bool isLocked,
    List<int>? masterKeyBytes,
  }) async {
    return await transaction(() async {
      final existing = await (select(notes)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
      if (existing == null) return false;

      final newCounter = existing.updateCounter + 1;
      final now = DateTime.now().toUtc();
      final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

      String finalContent = existing.content;
      String? encryptedPayload = existing.encryptedPayload;
      String? encryptionIv = existing.encryptionIv;

      if (isLocked) {
        if (masterKeyBytes == null) {
          AppLogger.e('NotesDao: Cannot lock note $uuid without masterKeyBytes.');
          return false;
        }
        if (existing.content.isNotEmpty) {
          final encrypted = await CryptoEngine.encryptPayload(existing.content, masterKeyBytes);
          encryptedPayload = jsonEncode({
            'ciphertext': encrypted['ciphertext'],
            'authTag': encrypted['authTag'],
          });
          encryptionIv = encrypted['iv'];
        }
        finalContent = ''; // Clear plain text content column
      } else {
        // UNLOCK & RESTORE DECRYPTED CONTENT IF AVAILABLE
        if (masterKeyBytes == null) {
          AppLogger.e('NotesDao: Cannot unlock note $uuid without masterKeyBytes.');
          return false;
        }
        if (existing.encryptedPayload != null && existing.encryptionIv != null) {
          try {
            String ciphertextBase64 = existing.encryptedPayload!;
            String authTagBase64 = existing.encryptedPayload!;
            if (existing.encryptedPayload!.startsWith('{')) {
              final map = jsonDecode(existing.encryptedPayload!) as Map<String, dynamic>;
              ciphertextBase64 = map['ciphertext'] as String? ?? ciphertextBase64;
              authTagBase64 = map['authTag'] as String? ?? authTagBase64;
            }

            final decrypted = await CryptoEngine.decryptPayload(
              ciphertextBase64: ciphertextBase64,
              ivBase64: existing.encryptionIv!,
              authTagBase64: authTagBase64,
              masterKey: masterKeyBytes,
            );
            finalContent = decrypted;
          } catch (e) {
            AppLogger.e('NotesDao: Failed to decrypt note $uuid during unlock: $e');
            return false;
          }
        }
        encryptedPayload = null;
        encryptionIv = null;
      }

      return await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
            NotesCompanion.custom(
              title: Variable(existing.title),
              content: Variable(finalContent),
              encryptedPayload: Variable(encryptedPayload),
              encryptionIv: Variable(encryptionIv),
              lockedAt: Variable(isLocked ? now : null),
              cloudSyncStatus: const Variable(0),
              localSyncStatus: const Variable(0),
              updatedAt: Variable(now),
              updateCounter: Variable(newCounter),
              hlc: Variable(newHlc),
            ),
          ) >
          0;
    });
  }

  Future<bool> updateNoteReminder(
    String uuid,
    DateTime? reminderAt, {
    String? repeatMode,
    String? customDays,
  }) async {
    return await transaction(() async {
      final existing = await (select(notes)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
      final newCounter = (existing?.updateCounter ?? 0) + 1;
      final now = DateTime.now().toUtc();
      final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

      return await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
            NotesCompanion.custom(
              reminderAt: Variable(reminderAt),
              reminderRepeatMode: Variable(repeatMode),
              reminderCustomDays: Variable(customDays),
              cloudSyncStatus: const Variable(0),
              localSyncStatus: const Variable(0),
              updatedAt: Variable(now),
              updateCounter: Variable(newCounter),
              hlc: Variable(newHlc),
            ),
          ) >
          0;
    });
  }

  /// Retrieves all active (non-deleted, non-archived) notes that have a scheduled reminder.
  Future<List<NoteWithFolder>> getNotesWithPendingReminders() async {
    final query = select(notes).join([
      leftOuterJoin(folders, folders.uuid.equalsExp(notes.folderId)),
    ])..where(notes.reminderAt.isNotNull() & notes.deletedAt.isNull() & notes.archivedAt.isNull());

    final rows = await query.get();
    return rows.map((row) {
      return NoteWithFolder(
        note: row.readTable(notes),
        folder: row.readTableOrNull(folders),
      );
    }).toList();
  }

  Future<int> unlockAllNotes({List<int>? masterKeyBytes}) async {
    if (masterKeyBytes == null) {
      AppLogger.e('NotesDao: Cannot unlock all notes without masterKeyBytes.');
      throw StateError('Cannot unlock notes without master key');
    }
    return await transaction(() async {
      final lockedNotes = await (select(notes)..where((t) => t.lockedAt.isNotNull())).get();
      final now = DateTime.now().toUtc();
      int updatedCount = 0;

      for (final note in lockedNotes) {
        final newCounter = note.updateCounter + 1;
        final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

        String restoredContent = note.content;
        if (note.encryptedPayload != null && note.encryptionIv != null) {
          try {
            String ciphertextBase64 = note.encryptedPayload!;
            String authTagBase64 = note.encryptedPayload!;
            if (note.encryptedPayload!.startsWith('{')) {
              final map = jsonDecode(note.encryptedPayload!) as Map<String, dynamic>;
              ciphertextBase64 = map['ciphertext'] as String? ?? ciphertextBase64;
              authTagBase64 = map['authTag'] as String? ?? authTagBase64;
            }

            restoredContent = await CryptoEngine.decryptPayload(
              ciphertextBase64: ciphertextBase64,
              ivBase64: note.encryptionIv!,
              authTagBase64: authTagBase64,
              masterKey: masterKeyBytes,
            );
          } catch (e) {
            AppLogger.e('NotesDao: Failed to decrypt note ${note.uuid} during unlockAll: $e.');
            throw StateError('Failed to decrypt note ${note.uuid} during unlockAll');
          }
        }

        final res = await (update(notes)..where((t) => t.uuid.equals(note.uuid))).write(
          NotesCompanion.custom(
            content: Variable(restoredContent),
            encryptedPayload: const Variable(null),
            encryptionIv: const Variable(null),
            lockedAt: const Variable(null),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(now),
            updateCounter: Variable(newCounter),
            hlc: Variable(newHlc),
          ),
        );
        updatedCount += res;
      }
      return updatedCount;
    });
  }

  /// Re-encrypts all locked notes in database from [oldMasterKey] to [newMasterKey]
  /// offloading decryption and re-encryption to a background Isolate worker.
  Future<int> reencryptAllLockedNotes({
    required List<int> oldMasterKey,
    required List<int> newMasterKey,
  }) async {
    final lockedNotes = await (select(notes)..where((t) => t.lockedAt.isNotNull())).get();
    if (lockedNotes.isEmpty) return 0;

    final itemsToReencrypt = <ReencryptionItem>[];
    for (final note in lockedNotes) {
      if (note.encryptedPayload != null && note.encryptionIv != null) {
        itemsToReencrypt.add(ReencryptionItem(
          uuid: note.uuid,
          encryptedPayload: note.encryptedPayload!,
          encryptionIv: note.encryptionIv!,
        ));
      }
    }
    if (itemsToReencrypt.isEmpty) return 0;

    // 1. Offload 100% of CPU-heavy decryption and re-encryption to background Isolate
    final reencryptedResults = await ReencryptionIsolateWorker.batchReencrypt(
      notes: itemsToReencrypt,
      oldMasterKey: oldMasterKey,
      newMasterKey: newMasterKey,
    );

    // 2. Perform atomic batch update in SQLite on main thread
    return await transaction(() async {
      final now = DateTime.now().toUtc();
      int updatedCount = 0;

      for (final result in reencryptedResults) {
        final existingNote = lockedNotes.firstWhere((n) => n.uuid == result.uuid);
        final newPayload = jsonEncode({
          'ciphertext': result.ciphertext,
          'authTag': result.authTag,
        });

        final newCounter = existingNote.updateCounter + 1;
        final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

        final res = await (update(notes)..where((t) => t.uuid.equals(result.uuid))).write(
          NotesCompanion.custom(
            encryptedPayload: Variable(newPayload),
            encryptionIv: Variable(result.iv),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(now),
            updateCounter: Variable(newCounter),
            hlc: Variable(newHlc),
          ),
        );
        if (res > 0) updatedCount++;
      }
      return updatedCount;
    });
  }

  // =========================================================================
  // SYNC MANAGER HELPER METHODS
  // =========================================================================

  /// CLOUD PUSH: Get local notes waiting for Firebase
  Future<List<Note>> getPendingCloudNotes() {
    return (select(notes)..where((t) => t.cloudSyncStatus.equals(0))).get();
  }

  /// LOCAL PUSH: Get local notes waiting for Wi-Fi P2P
  Future<List<Note>> getPendingLocalNotes() {
    return (select(notes)..where((t) => t.localSyncStatus.equals(0))).get();
  }

  /// HLC DELTA SYNC: Get all active or tombstoned notes modified since [lastSyncedHlc].
  /// If [lastSyncedHlc] is null (e.g. brand new device), returns all notes for initial sync.
  Future<List<Note>> getNotesModifiedSince(String? lastSyncedHlc) {
    if (lastSyncedHlc == null || lastSyncedHlc.isEmpty) {
      return select(notes).get();
    }
    return (select(notes)..where((t) => t.hlc.isBiggerThan(Variable(lastSyncedHlc)))).get();
  }

  /// Helper to safely parse incoming network timestamps
  DateTime? _parseNetworkTimestamp(dynamic timestamp) => TimeHelper.parseToUtcDateTime(timestamp);

  /// MERGE: Upsert notes pulled down from Firebase OR Local Wi-Fi
  Future<void> upsertNoteFromCloud(Map<String, dynamic> incomingData) async {
    final incomingUuid = incomingData['uuid'] as String;
    final incomingUpdatedAt = _parseNetworkTimestamp(incomingData['updatedAt']) ?? DateTime.now().toUtc();

    final noteCompanion = NotesCompanion(
      uuid: Value(incomingUuid),
      title: Value(incomingData['title'] as String),
      content: Value(incomingData['content'] as String),
      color: Value(incomingData['color'] as int? ?? 0xFFFFFFFF),

      // UX Timestamps parsed from network payload
      pinnedAt: Value(_parseNetworkTimestamp(incomingData['pinnedAt'])),
      archivedAt: Value(_parseNetworkTimestamp(incomingData['archivedAt'])),
      lockedAt: Value(_parseNetworkTimestamp(incomingData['lockedAt'])),

      folderId: Value(incomingData['folderId'] as String?),
      tags: Value(incomingData['tags'] as String?),
      creationPlatform: Value(incomingData['creationPlatform'] as String?),
      creationDevice: Value(incomingData['creationDevice'] as String?),

      deletedAt: Value(_parseNetworkTimestamp(incomingData['deletedAt'])),
      reminderAt: incomingData['reminderAt'] != null
          ? Value(_parseNetworkTimestamp(incomingData['reminderAt'])!)
          : const Value.absent(),

      updatedAt: Value(incomingUpdatedAt),
      createdAt: Value(_parseNetworkTimestamp(incomingData['createdAt']) ?? DateTime.now().toUtc()),

      // Apply the network's conflict resolver counter & HLC
      updateCounter: Value(incomingData['updateCounter'] as int? ?? 1),
      hlc: Value(incomingData['hlc'] as String?),

      // CRITICAL: Mark synced for Cloud, but keep pending for Local Wi-Fi
      cloudSyncStatus: const Value(1),
      localSyncStatus: const Value(0),
    );

    await _executeUpsert(incomingUuid, incomingData, noteCompanion);
  }

  /// MERGE: Upsert notes pulled down from Local Wi-Fi
  Future<void> upsertNoteFromLocal(Map<String, dynamic> incomingData) async {
    final incomingUuid = incomingData['uuid'] as String;
    final incomingUpdatedAt = _parseNetworkTimestamp(incomingData['updatedAt']) ?? DateTime.now().toUtc();

    final noteCompanion = NotesCompanion(
      uuid: Value(incomingUuid),
      title: Value(incomingData['title'] as String),
      content: Value(incomingData['content'] as String),
      color: Value(incomingData['color'] as int? ?? 0xFFFFFFFF),

      pinnedAt: Value(_parseNetworkTimestamp(incomingData['pinnedAt'])),
      archivedAt: Value(_parseNetworkTimestamp(incomingData['archivedAt'])),
      lockedAt: Value(_parseNetworkTimestamp(incomingData['lockedAt'])),

      folderId: Value(incomingData['folderId'] as String?),
      tags: Value(incomingData['tags'] as String?),
      creationPlatform: Value(incomingData['creationPlatform'] as String?),
      creationDevice: Value(incomingData['creationDevice'] as String?),

      deletedAt: Value(_parseNetworkTimestamp(incomingData['deletedAt'])),
      reminderAt: incomingData['reminderAt'] != null
          ? Value(_parseNetworkTimestamp(incomingData['reminderAt'])!)
          : const Value.absent(),

      updatedAt: Value(incomingUpdatedAt),
      createdAt: Value(_parseNetworkTimestamp(incomingData['createdAt']) ?? DateTime.now().toUtc()),
      updateCounter: Value(incomingData['updateCounter'] as int? ?? 1),
      hlc: Value(incomingData['hlc'] as String?),

      // INVERTED: Mark synced for Local Wi-Fi, but keep pending for Cloud
      cloudSyncStatus: const Value(0),
      localSyncStatus: const Value(1),
    );

    await _executeUpsert(incomingUuid, incomingData, noteCompanion);
  }

  /// Determines if an incoming note payload should overwrite the local note using HLC-First LWW precedence.
  bool _shouldOverwriteLocalNote({
    required int incomingUpdateCounter,
    required DateTime incomingUpdatedAt,
    required String? incomingHlc,
    required Note existingNote,
  }) {
    // 1. Primary rule: HLC string comparison if both records have valid HLCs
    if (incomingHlc != null && incomingHlc.isNotEmpty && existingNote.hlc != null && existingNote.hlc!.isNotEmpty) {
      final hlcComparison = Hlc.compareStrings(incomingHlc, existingNote.hlc);
      if (hlcComparison != 0) {
        return hlcComparison > 0;
      }
    }

    // 2. Secondary rule: Compare updateCounters
    if (incomingUpdateCounter != existingNote.updateCounter) {
      return incomingUpdateCounter > existingNote.updateCounter;
    }

    // 3. Fallback rule: Compare UTC timestamps
    if (incomingUpdatedAt.millisecondsSinceEpoch != existingNote.updatedAt.millisecondsSinceEpoch) {
      return incomingUpdatedAt.isAfter(existingNote.updatedAt);
    }

    // 4. Tie-breaker: If counter, HLC, and timestamp are identical, preserve local version
    return false;
  }

  /// Private helper to handle the actual write logic for upserts using HLC-First LWW evaluation
  Future<void> _executeUpsert(String uuid, Map<String, dynamic> incomingData, NotesCompanion companion) async {
    final existingNote = await (select(notes)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

    if (existingNote != null) {
      final incomingUpdateCounter = incomingData['updateCounter'] as int? ?? companion.updateCounter.value;
      final incomingUpdatedAt = companion.updatedAt.value;
      final incomingHlc = companion.hlc.value;

      if (_shouldOverwriteLocalNote(
        incomingUpdateCounter: incomingUpdateCounter,
        incomingUpdatedAt: incomingUpdatedAt,
        incomingHlc: incomingHlc,
        existingNote: existingNote,
      )) {
        await (update(notes)..where((t) => t.uuid.equals(uuid))).write(companion);
        AppLogger.d("NotesDao: Overwrote local note $uuid with newer incoming network data.");
      } else {
        AppLogger.d("NotesDao: Ignored older/equal incoming data for note $uuid. Local is newer.");
      }
    } else {
      // Note doesn't exist locally, insert it.
      await into(notes).insert(companion);
      AppLogger.d("NotesDao: Inserted new note $uuid ('${incomingData['title']}') from network.");
    }
  }

  /// CONFIRM CLOUD: Mark notes as successfully pushed to Firebase
  Future<void> markAsCloudSynced(Iterable<String> uuids) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(const NotesCompanion(cloudSyncStatus: Value(1)));
  }

  /// CONFIRM LOCAL: Mark notes as successfully pushed over Wi-Fi
  Future<void> markAsLocalSynced(Iterable<String> uuids) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(const NotesCompanion(localSyncStatus: Value(1)));
  }

  // =========================================================================
  // TRASH PAGE METHODS
  // =========================================================================

  /// VIEW TRASH: Watch only notes that have a deletedAt timestamp

  Stream<List<NoteWithFolder>> watchTrashNotes() {
    final query = select(notes).join([
      leftOuterJoin(folders, folders.uuid.equalsExp(notes.folderId)),
    ]);

    query
      ..where(notes.deletedAt.isNotNull())
      ..orderBy([OrderingTerm(expression: notes.deletedAt, mode: OrderingMode.desc)]);

    return query.watch().map((rows) => rows.map((row) => NoteWithFolder(
      note: row.readTable(notes),
      folder: row.readTableOrNull(folders),
    )).toList());
  }

  Future<bool> restoreNote(String uuid) async {
    return await transaction(() async {
      final existing = await (select(notes)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
      final newCounter = (existing?.updateCounter ?? 0) + 1;
      final now = DateTime.now().toUtc();
      final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

      final success = await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
            NotesCompanion.custom(
              deletedAt: const Variable(null),
              cloudSyncStatus: const Variable(0),
              localSyncStatus: const Variable(0),
              updatedAt: Variable(now),
              updateCounter: Variable(newCounter),
              hlc: Variable(newHlc),
            ),
          ) > 0;
      if (success) {
        AppLogger.d("NotesDao: Restored note $uuid from trash.");
      }
      return success;
    });
  }

  /// EMPTY TRASH: Hard delete all trashed notes and return their UUIDs
  Future<List<String>> emptyLocalTrash() async {
    final trashedNotes = await (select(notes)..where((t) => t.deletedAt.isNotNull())).get();
    final uuidsToDelete = trashedNotes.map((note) => note.uuid).toList();

    final deletedCount = await (delete(notes)..where((t) => t.deletedAt.isNotNull())).go();
    AppLogger.d("NotesDao: Emptied $deletedCount notes from local trash.");

    return uuidsToDelete;
  }

  Future<void> importNotes(List<Note> importedNotes) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(notes, importedNotes);
    });
  }

  // =========================================================================
  // BATCH ACTIONS (PIN, ARCHIVE, FETCH, DUPLICATE)
  // =========================================================================

  /// Sets the pin status for multiple notes
  Future<void> setNotesPinStatus(Iterable<String> uuids, {required bool isPinned}) async {
    await transaction(() async {
      final targetNotes = await (select(notes)..where((t) => t.uuid.isIn(uuids))).get();
      final now = DateTime.now().toUtc();

      for (final note in targetNotes) {
        final newCounter = note.updateCounter + 1;
        final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

        await (update(notes)..where((t) => t.uuid.equals(note.uuid))).write(
          NotesCompanion.custom(
            pinnedAt: Variable(isPinned ? now : null),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(now),
            updateCounter: Variable(newCounter),
            hlc: Variable(newHlc),
          ),
        );
      }
    });
  }

  /// Toggles the pin status for multiple notes (Resolved TODO)
  Future<void> togglePinStatus(Iterable<String> uuids) async {
    await transaction(() async {
      final targetNotes = await (select(notes)..where((t) => t.uuid.isIn(uuids))).get();
      final now = DateTime.now().toUtc();

      for (final note in targetNotes) {
        final newPinnedState = note.pinnedAt == null ? now : null;
        final newCounter = note.updateCounter + 1;
        final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

        await (update(notes)..where((t) => t.uuid.equals(note.uuid))).write(
          NotesCompanion.custom(
            pinnedAt: Variable(newPinnedState),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(now),
            updateCounter: Variable(newCounter),
            hlc: Variable(newHlc),
          ),
        );
      }
    });
  }

  /// Archives multiple notes
  Future<void> archiveNotes(Iterable<String> uuids) async {
    await transaction(() async {
      final targetNotes = await (select(notes)..where((t) => t.uuid.isIn(uuids))).get();
      final now = DateTime.now().toUtc();

      for (final note in targetNotes) {
        final newCounter = note.updateCounter + 1;
        final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

        await (update(notes)..where((t) => t.uuid.equals(note.uuid))).write(
          NotesCompanion.custom(
            archivedAt: Variable(now),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(now),
            updateCounter: Variable(newCounter),
            hlc: Variable(newHlc),
          ),
        );
      }
    });
  }

  /// UNARCHIVE: Helper to restore notes back to the main home screen
  Future<void> unarchiveNotes(Iterable<String> uuids) async {
    await transaction(() async {
      final targetNotes = await (select(notes)..where((t) => t.uuid.isIn(uuids))).get();
      final now = DateTime.now().toUtc();

      for (final note in targetNotes) {
        final newCounter = note.updateCounter + 1;
        final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

        await (update(notes)..where((t) => t.uuid.equals(note.uuid))).write(
          NotesCompanion.custom(
            archivedAt: const Variable(null),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(now),
            updateCounter: Variable(newCounter),
            hlc: Variable(newHlc),
          ),
        );
      }
    });
  }

  /// VIEW ARCHIVE: Watch only notes that are archived and not in the trash

  Stream<List<NoteWithFolder>> watchArchivedNotes() {
    final query = select(notes).join([
      leftOuterJoin(folders, folders.uuid.equalsExp(notes.folderId)),
    ]);

    query
      ..where(notes.archivedAt.isNotNull() & notes.deletedAt.isNull())
      ..orderBy([OrderingTerm(expression: notes.updatedAt, mode: OrderingMode.desc)]);

    return query.watch().map((rows) => rows.map((row) => NoteWithFolder(
      note: row.readTable(notes),
      folder: row.readTableOrNull(folders),
    )).toList());
  }

  /// Fetches specific notes (Used for duplication)
  Future<List<Note>> getNotesByUuids(Iterable<String> uuids) {
    return (select(notes)..where((t) => t.uuid.isIn(uuids))).get();
  }

  /// Inserts multiple notes at once (Used for duplication)
  Future<void> insertMultipleNotes(List<NotesCompanion> newNotes) async {
    final preparedNotes = newNotes.map((companion) {
      final now = companion.updatedAt.present ? companion.updatedAt.value : DateTime.now().toUtc();
      final counter = companion.updateCounter.present ? companion.updateCounter.value : 1;
      final hlcStr = companion.hlc.present && companion.hlc.value != null
          ? companion.hlc.value!
          : _generateHlc(counter: counter, lastKnownTime: now);

      return companion.copyWith(
        updateCounter: Value(counter),
        hlc: Value(hlcStr),
      );
    }).toList();

    await batch((batch) {
      batch.insertAll(notes, preparedNotes);
    });
  }

  /// RESTORE BATCH: Restores multiple notes from the trash
  Future<void> restoreNotesBatch(Iterable<String> uuids) async {
    await transaction(() async {
      final targetNotes = await (select(notes)..where((t) => t.uuid.isIn(uuids))).get();
      final now = DateTime.now().toUtc();

      for (final note in targetNotes) {
        final newCounter = note.updateCounter + 1;
        final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

        await (update(notes)..where((t) => t.uuid.equals(note.uuid))).write(
          NotesCompanion.custom(
            deletedAt: const Variable(null),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(now),
            updateCounter: Variable(newCounter),
            hlc: Variable(newHlc),
          ),
        );
      }
    });
  }

  /// HARD DELETE BATCH: Permanently deletes specific notes (Returns UUIDs for Firebase sync)
  Future<List<String>> hardDeleteNotesBatch(Iterable<String> uuids) async {
    await (delete(notes)..where((t) => t.uuid.isIn(uuids))).go();
    return uuids.toList();
  }

  Future<List<Note>> getAllNotes() async {
    return await select(notes).get();
  }
}
