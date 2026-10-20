import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../database/drift/folders/folders_dao.dart';
import '../../database/drift/local_database.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../database/sync/sync_orchestrator.dart';
import 'backup_utils.dart';
import 'export_page.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref);
});

class BackupService {
  final Ref ref;
  final _uuidGen = const Uuid();

  BackupService(this.ref);

  FoldersDao get foldersDao => ref.read(foldersDaoProvider);
  NotesDao get notesDao => ref.read(notesDaoProvider);

  /// Generates backup file content string and file extension based on scope and format
  Future<({String content, String extension, int notesCount, int foldersCount})> generateBackup({
    required ExportFormat format,
    required ExportScope scope,
    required bool includeLockedNotes,
  }) async {
    final allNotes = await notesDao.getAllNotes();
    final allFolders = await foldersDao.getAllFolders();

    final activeFolders = scope == ExportScope.notesOnly
        ? <Folder>[]
        : allFolders.where((f) => f.deletedAt == null).toList();

    final notesToExport = scope == ExportScope.foldersOnly
        ? <Note>[]
        : allNotes.where((note) {
            if (note.deletedAt != null) return false;
            if (note.lockedAt != null && !includeLockedNotes) return false;
            return true;
          }).toList();

    if (notesToExport.isEmpty && activeFolders.isEmpty) {
      return (content: '', extension: '', notesCount: 0, foldersCount: 0);
    }

    final folderNameMap = <String, String>{
      for (var f in allFolders) f.uuid: f.name,
    };

    String fileContent = '';
    String extension = '';

    if (format == ExportFormat.json) {
      final Map<String, dynamic> exportPayload = {
        'version': 1,
        'appName': 'NoteIt',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'folders': activeFolders.map((f) => f.toJson()).toList(),
        'notes': notesToExport.map((n) => n.toJson()).toList(),
      };

      fileContent = const JsonEncoder.withIndent('  ').convert(exportPayload);
      extension = 'json';
    } else if (format == ExportFormat.csv) {
      if (scope == ExportScope.foldersOnly) {
        final List<String> folderHeaders = [
          'uuid',
          'name',
          'colorIndex',
          'pinnedAt',
          'createdAt',
          'updatedAt',
        ];

        final List<Map<String, dynamic>> folderRows = activeFolders.map((f) => f.toJson()).toList();
        fileContent = BackupUtils.encodeCsv(folderHeaders, folderRows);
      } else {
        final List<String> csvHeaders = [
          'uuid',
          'title',
          'content',
          'folderName',
          'folderId',
          'color',
          'tags',
          'contentVersion',
          'pinnedAt',
          'archivedAt',
          'lockedAt',
          'createdAt',
          'updatedAt',
        ];

        final List<Map<String, dynamic>> noteRows = notesToExport.map((note) {
          final map = note.toJson();
          map['folderName'] = folderNameMap[note.folderId] ?? '';
          return map;
        }).toList();

        fileContent = BackupUtils.encodeCsv(csvHeaders, noteRows);
      }
      extension = 'csv';
    }

    return (
      content: fileContent,
      extension: extension,
      notesCount: notesToExport.length,
      foldersCount: activeFolders.length,
    );
  }

  /// Executes database insertion/upsert for raw imported maps
  Future<({int importedNotes, int importedFolders})> executeImport({
    required List<Map<String, dynamic>> rawFolderMaps,
    required List<Map<String, dynamic>> rawNoteMaps,
    required bool useFreshTimestamp,
    required bool importAsDuplicates,
  }) async {
    final now = DateTime.now().toUtc();
    final Map<String, String> remappedFolderIds = {};

    final List<Folder> foldersToInsert = [];
    for (final map in rawFolderMaps) {
      final originalUuid = map['uuid']?.toString() ?? const Uuid().v4();
      final targetUuid = importAsDuplicates ? _uuidGen.v4() : originalUuid;

      if (importAsDuplicates) {
        remappedFolderIds[originalUuid] = targetUuid;
      }

      final createdAt = useFreshTimestamp
          ? now
          : (BackupUtils.parseToDateTime(map['createdAt']) ?? now);

      final updatedAt = useFreshTimestamp
          ? now
          : (BackupUtils.parseToDateTime(map['updatedAt']) ?? now);

      foldersToInsert.add(Folder(
        uuid: targetUuid,
        name: map['name']?.toString() ?? 'Imported Folder',
        colorIndex: int.tryParse(map['colorIndex']?.toString() ?? '0') ?? 0,
        createdAt: createdAt,
        updatedAt: updatedAt,
        pinnedAt: BackupUtils.parseToDateTime(map['pinnedAt']),
        deletedAt: BackupUtils.parseToDateTime(map['deletedAt']),
        updateCounter: 1,
        cloudSyncStatus: 0,
        localSyncStatus: 0,
      ));
    }

    if (foldersToInsert.isNotEmpty) {
      await foldersDao.importFolders(foldersToInsert);
    }

    final List<Note> notesToInsert = [];
    for (final map in rawNoteMaps) {
      final originalUuid = map['uuid']?.toString() ?? const Uuid().v4();
      final targetUuid = importAsDuplicates ? _uuidGen.v4() : originalUuid;

      String? folderId = map['folderId']?.toString();
      if (importAsDuplicates && folderId != null && remappedFolderIds.containsKey(folderId)) {
        folderId = remappedFolderIds[folderId];
      }

      final createdAt = useFreshTimestamp
          ? now
          : (BackupUtils.parseToDateTime(map['createdAt']) ?? now);

      final updatedAt = useFreshTimestamp
          ? now
          : (BackupUtils.parseToDateTime(map['updatedAt']) ?? now);

      notesToInsert.add(Note(
        uuid: targetUuid,
        title: map['title']?.toString() ?? '',
        content: map['content']?.toString() ?? '',
        folderId: folderId,
        color: int.tryParse(map['color']?.toString() ?? '0') ?? 0,
        tags: map['tags']?.toString(),
        contentVersion: int.tryParse(map['contentVersion']?.toString() ?? '0') ?? 0,
        pinnedAt: BackupUtils.parseToDateTime(map['pinnedAt']),
        archivedAt: BackupUtils.parseToDateTime(map['archivedAt']),
        lockedAt: BackupUtils.parseToDateTime(map['lockedAt']),
        createdAt: createdAt,
        updatedAt: updatedAt,
        updateCounter: 1,
        cloudSyncStatus: 0,
        localSyncStatus: 0,
        schemaVersion: 1,
      ));
    }

    if (notesToInsert.isNotEmpty) {
      await notesDao.importNotes(notesToInsert);
    }

    ref.read(syncOrchestratorProvider).triggerSync();

    return (
      importedNotes: notesToInsert.length,
      importedFolders: foldersToInsert.length,
    );
  }
}
