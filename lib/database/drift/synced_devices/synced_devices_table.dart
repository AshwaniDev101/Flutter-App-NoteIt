import 'package:drift/drift.dart';

@TableIndex(name: 'idx_synced_devices_updated_at', columns: {#updatedAt})
@TableIndex(name: 'idx_synced_devices_deleted_at', columns: {#deletedAt})
class SyncedDevices extends Table {
  // --- CORE IDENTITY ---
  TextColumn get deviceUuid => text()();

  // Original broadcasted name from the device (e.g., "Desktop-XT49")
  TextColumn get deviceName => text()();

  // Lets the user rename the device in their UI (e.g., "My Work Laptop")
  TextColumn get customAlias => text().nullable()();

  // --- NETWORK & FAST RECONNECT ---
  TextColumn get lastKnownIp => text().nullable()();
  IntColumn get lastKnownPort => integer().nullable()();

  // --- ROLES & CONNECTION HISTORY ---
  DateTimeColumn get lastSeenAsHostAt => dateTime().nullable()();
  DateTimeColumn get lastSeenAsClientAt => dateTime().nullable()();
  DateTimeColumn get firstPairedAt => dateTime().withDefault(currentDateAndTime)();

  // --- SECURITY & TRUST ---
  // If null, the device is trusted. If a timestamp exists, access is revoked.
  DateTimeColumn get blockedAt => dateTime().nullable()();

  // For end-to-end encryption handshakes and verifying peer identity
  TextColumn get publicKey => text().nullable()();

  // For basic authorization tokens/passwords if the user locks a session
  TextColumn get authKey => text().nullable()();

  // --- METADATA & COMPATIBILITY ---
  // Tracks table-level changes to protect older apps during Firebase sync
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  // 'android', 'windows', 'mac', 'linux' - useful for displaying UI icons
  TextColumn get deviceType => text().nullable()();

  // Protects the live WebSocket connection from parsing errors
  IntColumn get protocolVersion => integer().nullable()();

  // --- SYNCHRONIZATION STATE ---
  // "Only send me the records that changed after this exact time."
  DateTimeColumn get lastSuccessfulSyncAt => dateTime().nullable()();

  // The Sync Engine Foundation (Prepares this table for Firebase)
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get updateCounter => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {deviceUuid};
}