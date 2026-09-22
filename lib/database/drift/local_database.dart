import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'device_pairs/device_pairs_dao.dart';
import 'device_pairs/pairs_table.dart';
import 'notes/notes_dao.dart';
import 'notes/notes_table.dart';

part 'local_database.g.dart';

/// Riverpod provider exposing a single, shared instance of [LocalDatabase].
///
/// Automatically binds database lifecycle disposal to Riverpod's [Ref.onDispose],
/// guaranteeing underlying SQLite file locks are cleanly released during app teardown or testing.

final localDatabaseProvider = Provider((ref) {
  return LocalDatabase();
});

@DriftDatabase(tables: [Notes, DevicePairs], daos: [NotesDao, DevicePairsDao])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase()
    : super(
        driftDatabase(
          name: 'note_it_db',
          // Routes native persistent storage to the application's sandboxed support directory (`AppData` on Windows)
          // to comply with MSIX packaging and avoid OneDrive locking collisions.
          // Without this the 'my_notes_db' will be created in Windows Document folder
          native: const DriftNativeOptions(
            databaseDirectory: getApplicationSupportDirectory,
          ),

          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 1;
}
