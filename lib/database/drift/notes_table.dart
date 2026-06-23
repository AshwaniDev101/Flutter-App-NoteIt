import 'package:drift/drift.dart';

// This is the class for the table definition
// Regenerate drift db : flutter pub run build_runner build --delete-conflicting-outputs
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 0, max: 255)();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  // For firebase sync
  TextColumn get firestoreId => text().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))(); // 0 = Pending Sync, 1 = Synced
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))(); // True if deleted offline

}
