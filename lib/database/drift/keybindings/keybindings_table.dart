import 'package:drift/drift.dart';

@TableIndex(name: 'idx_keybindings_updated_at', columns: {#updatedAt})
@TableIndex(name: 'idx_keybindings_deleted_at', columns: {#deletedAt})
class AppKeybindings extends Table {
  // --- CORE IDENTITY ---
  // The internal name of the action ('search', 'new_note', 'toggle_menu')
  TextColumn get actionName => text()();

  // If syncing across devices, this prevents Mac shortcuts from overwriting Windows ones.
  // e.g., 'windows', 'macos', 'android'
  TextColumn get targetPlatform => text().withDefault(const Constant('windows'))();

  @override
  Set<Column> get primaryKey => {actionName, targetPlatform};

  // --- UI & LOGIC ---
  // The visual label for your KeyHint UI ("S", "N", "M")
  TextColumn get keyLabel => text()();

  // The actual integer ID of the logical key (LogicalKeyboardKey.keyId)
  IntColumn get keyId => integer()();

  // Modifiers (These stay as booleans because they are part of a fixed chord, not a time-based state)
  BoolColumn get useCtrl => boolean().withDefault(const Constant(false))();
  BoolColumn get useAlt => boolean().withDefault(const Constant(false))();
  BoolColumn get useShift => boolean().withDefault(const Constant(false))();
  BoolColumn get useMeta => boolean().withDefault(const Constant(false))(); // Mac Cmd key etc

  // [UPGRADED FROM BOOLEAN]: Replaces 'isEnabled'
  // Null = Enabled. Timestamp = Disabled. Allows LWW conflict resolution during sync.
  DateTimeColumn get disabledAt => dateTime().nullable()();

  // Helps you group shortcuts in your Settings UI ('Global', 'Editor', 'Navigation')
  TextColumn get category => text().withDefault(const Constant('General'))();

  // --- VERSIONING & COMPATIBILITY ---
  // Protects user preferences from getting corrupted if you change the table structure later
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  // --- THE SYNC FOUNDATION ---
  // Allows user preferences to sync across their devices seamlessly
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get updateCounter => integer().withDefault(const Constant(1))();
}