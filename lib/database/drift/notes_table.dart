import 'package:drift/drift.dart';

// This is the class for the table definition
class Notes extends Table {
  // Local Database ID
  // Note: Drift works best with auto-incrementing integers for local storage.
  // We use this for local operations, and use `firestoreId` for cloud string IDs.
  IntColumn get id => integer().autoIncrement()();

  // Note Data
  TextColumn get title => text().withLength(min: 0, max: 255)();
  TextColumn get content => text()();
  IntColumn get color => integer().withDefault(const Constant(0xFFFFFFFF))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();

  // Nullable Data
  TextColumn get tags => text().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  // Firebase Sync Engine Columns
  TextColumn get firestoreId => text().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))(); // 0 = Pending, 1 = Synced
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // Meta Data
  TextColumn get creationPlatform => text().nullable()();
  TextColumn get creationDevice => text().nullable()();
}