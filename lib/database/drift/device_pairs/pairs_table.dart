import 'package:drift/drift.dart';

class DevicePairs extends Table {
  TextColumn get deviceUuid => text()();

  @override
  Set<Column> get primaryKey => {deviceUuid};

  TextColumn get deviceName => text()();

  DateTimeColumn get lastSeenAsHostAt => dateTime().nullable()();

  DateTimeColumn get lastSeenAsClientAt => dateTime().nullable()();

  DateTimeColumn get firstPairedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
