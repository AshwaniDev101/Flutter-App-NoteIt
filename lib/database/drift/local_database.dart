import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../features/workspace/providers/active_workspace_provider.dart';
import 'keybindings/keybindings_dao.dart';
import 'keybindings/keybindings_table.dart';
import 'synced_devices/synced_devices_dao.dart';
import 'synced_devices/synced_devices_table.dart';
import 'notes/notes_dao.dart';
import 'notes/notes_table.dart';
import 'folders/folders_dao.dart';
import 'folders/folders_table.dart';

part 'local_database.g.dart';

/// Riverpod provider exposing a single, shared instance of [LocalDatabase].
///
/// Automatically binds database lifecycle disposal to Riverpod's [Ref.onDispose],
/// guaranteeing underlying SQLite file locks are cleanly released during app teardown or testing.

final localDatabaseProvider = Provider((ref) {
  final dbFileName = ref.watch(activeWorkspaceProvider.select((p) => p.dbFileName));
  final db = LocalDatabase(dbFileName);
  ref.onDispose(() async {
    await db.close();
  });
  return db;
});

/// Physically deletes all local database and manifest files from the
/// application support directory.
Future<void> deleteDatabaseFiles() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final dbDir = Directory(dir.path);
    if (await dbDir.exists()) {
      final entities = dbDir.listSync();
      for (final entity in entities) {
        if (entity is File &&
            (entity.path.contains('note_it_db') ||
                entity.path.contains('workspace_') ||
                entity.path.contains('profile_') ||
                entity.path.endsWith('manifest.json'))) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
  } catch (_) {}
}

// 2. Add Folders and FoldersDao to the annotation
@DriftDatabase(
    tables: [Notes, Folders, SyncedDevices, AppKeybindings],
    daos: [NotesDao, FoldersDao, SyncedDevicesDao, KeybindingsDao]
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase([String dbName = 'note_it_db'])
      : super(
    driftDatabase(
      name: dbName,
      // Routes native persistent storage to the application's sandboxed support directory (`AppData` on Windows)
      // to comply with MSIX packaging and avoid OneDrive locking collisions.
      // Without this the 'my_notes_db' will be created in Windows Document folder
      native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),

      web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
    ),
  ) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  @override
  int get schemaVersion => 1;
}