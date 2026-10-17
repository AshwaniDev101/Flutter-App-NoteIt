import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// --- PERFORMANCE INDEXES ---
@TableIndex(name: 'idx_folders_updated_at', columns: {#updatedAt})
@TableIndex(name: 'idx_folders_active', columns: {#deletedAt})
class Folders extends Table {
  // PRIMARY KEY
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4())();

  // CORE DATA
  TextColumn get name => text().withLength(min: 1, max: 255)();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();

  // SECURITY
  TextColumn get ownerUid => text().nullable()();

  // SYNC TIMESTAMPS & VERSIONING
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // ADDED: Tracks pin status and time for sorting
  DateTimeColumn get pinnedAt => dateTime().nullable()();

  IntColumn get updateCounter => integer().withDefault(const Constant(1))();

  // SYNC STATUS (0 = synced, 1 = pending)
  IntColumn get cloudSyncStatus => integer().withDefault(const Constant(0))();
  IntColumn get localSyncStatus => integer().withDefault(const Constant(0))();

  // METADATA
  TextColumn get creationPlatform => text().nullable()();
  TextColumn get creationDevice => text().nullable()();
  TextColumn get lastEditedPlatform => text().nullable()();
  TextColumn get lastEditedDevice => text().nullable()();
  TextColumn get deletedPlatform => text().nullable()();
  TextColumn get deletedDevice => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}