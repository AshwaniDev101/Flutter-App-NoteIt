import 'package:drift/drift.dart';

class SyncedDevices extends Table {
  TextColumn get deviceUuid => text()();

  @override
  Set<Column> get primaryKey => {deviceUuid};

  TextColumn get deviceName => text()();

  // Added for Fast Reconnect
  TextColumn get lastKnownIp => text().nullable()();

  IntColumn get lastKnownPort => integer().nullable()();

  DateTimeColumn get lastSeenAsHostAt => dateTime().nullable()();

  DateTimeColumn get lastSeenAsClientAt => dateTime().nullable()();

  DateTimeColumn get firstPairedAt => dateTime().withDefault(currentDateAndTime)();
}
