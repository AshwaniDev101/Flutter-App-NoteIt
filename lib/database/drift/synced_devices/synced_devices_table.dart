import 'package:drift/drift.dart';

class SyncedDevices extends Table {
  // --- Core Identity ---
  TextColumn get deviceUuid => text()();

  @override
  Set<Column> get primaryKey => {deviceUuid};

  // Original broadcasted name from the device "Desktop-XT49")
  TextColumn get deviceName => text()();

  // Lets the user rename the device in their UI ("My Work Laptop")
  TextColumn get customAlias => text().nullable()();

  // --- Network & Fast Reconnect ---
  TextColumn get lastKnownIp => text().nullable()();
  IntColumn get lastKnownPort => integer().nullable()();

  // --- Roles & Connection History ---
  DateTimeColumn get lastSeenAsHostAt => dateTime().nullable()();
  DateTimeColumn get lastSeenAsClientAt => dateTime().nullable()();
  DateTimeColumn get firstPairedAt => dateTime().withDefault(currentDateAndTime)();

  // --- Security & Trust ---
  // If false, automatically reject WebSocket connection attempts from this UUID
  BoolColumn get isTrusted => boolean().withDefault(const Constant(true))();

  // For end-to-end encryption handshakes and verifying peer identity
  TextColumn get publicKey => text().nullable()();

  // For basic authorization tokens/passwords if the user locks a session
  TextColumn get authKey => text().nullable()();

  // --- Metadata & Compatibility ---
  // 'android', 'windows', 'mac', 'linux' - useful for displaying UI icons
  TextColumn get deviceType => text().nullable()();

  // Very important for the future: If we change WebSocket JSON structure
  // in a year, we can check this to ensure we don't send unsupported data to an older app version.
  IntColumn get protocolVersion => integer().nullable()();

  // --- Synchronization State ---
  // "Only send me the records that changed after this exact time."
  DateTimeColumn get lastSuccessfulSyncAt => dateTime().nullable()();
}