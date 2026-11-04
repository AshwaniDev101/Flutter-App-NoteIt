import 'package:drift/drift.dart';

class SyncedDevices extends Table {
  // --- CORE IDENTITY ---
  TextColumn get deviceUuid => text()();

  // Original broadcasted name from the device (e.g., "Desktop-XT49")
  TextColumn get deviceName => text()();

  // Lets the user rename the device in their UI (e.g., "My Work Laptop")
  TextColumn get customAlias => text().nullable()();

  // 'android', 'windows', 'mac', 'linux' - useful for displaying UI icons
  TextColumn get deviceType => text().nullable()();

  // --- NETWORK & FAST RECONNECT ---
  TextColumn get lastKnownIp => text().nullable()();
  IntColumn get lastKnownPort => integer().nullable()();

  // Protects the live WebSocket connection from parsing errors
  IntColumn get protocolVersion => integer().nullable()();

  // --- SECURITY & TRUST ---
  // Pre-shared authentication token exchanged during QR pairing
  TextColumn get authKey => text().nullable()();

  // --- ROLES & CONNECTION HISTORY ---
  DateTimeColumn get lastSeenAsHostAt => dateTime().nullable()();
  DateTimeColumn get lastSeenAsClientAt => dateTime().nullable()();
  DateTimeColumn get firstPairedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {deviceUuid};
}
