import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// To trigger fresh code gen use 'dart run build_runner build'

// --- PERFORMANCE INDEXES ---
// Creates hidden, alphabetized lookup tables sorted by specific columns.
// Multiple row IDs (note indexes) can be mapped to a single value.
//
// This ensures that when we load a folder, we aren't scanning every single
// row in the database one by one. Instead, SQLite jumps the cursor straight
// to 'FolderID2' and grabs all matching notes instantly.
//
// Behind the scenes example:
// FolderID1 : Row #4
// FolderID2 : Row #12
// FolderID2 : Row #18
// FolderID3 : Row #21
//
// We index our heaviest queries: opening a folder (folder_id), finding
// notes that need to be synced (updated_at), and filtering out trash (deleted_at).
@TableIndex(name: 'idx_notes_updated_at', columns: {#updatedAt})
@TableIndex(name: 'idx_notes_active', columns: {#deletedAt, #archivedAt})
@TableIndex(name: 'idx_notes_folder', columns: {#folderId})
class Notes extends Table {
  // PRIMARY KEY
  // completely offline on multiple devices without ID collisions when they finally sync.
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4())();

  // CORE DATA
  TextColumn get title => text().withLength(min: 0, max: 255)();

  TextColumn get content => text()();

  IntColumn get color => integer().withDefault(const Constant(0xFFFFFFFF))();

  // Tracks table-level changes (e.g., 1 = Base schema, 2 = Added 'isFavorite' column).
  // Older apps can usually still edit the text, they just ignore the new columns.
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  // Tracks the format of the 'content' string (e.g., 1 = Plain text, 2 = Checklist).
  // If an older app sees a higher contentVersion, it MUST lock the editor to prevent
  // overwriting and corrupting the rich-text JSON.
  IntColumn get contentVersion => integer().withDefault(const Constant(1))();

  // UX TIMESTAMPS (The "Boolean Replacements")
  // We use DateTimes instead of Booleans (e.g., isPinned) so the sync engine knows
  // WHICH device's action happened last (Last-Writer-Wins) if a note is modified offline.
  // Null = False.
  DateTimeColumn get pinnedAt => dateTime().nullable()();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  DateTimeColumn get lockedAt => dateTime().nullable()();

  // ATTACHMENTS
  // Avoids storing heavy BLOBs in SQLite to keep the database fast.
  // localAttachmentPath: The file path on the current Android/Windows device.
  // cloudAttachmentUrl: The Firebase Storage URL for cross-device syncing.
  TextColumn get localAttachmentPath => text().nullable()();

  TextColumn get cloudAttachmentUrl => text().nullable()();

  // NAVIGATION & TAGS
  TextColumn get folderId => text().nullable()();

  TextColumn get tags => text().nullable()();

  DateTimeColumn get reminderAt => dateTime().nullable()();

  // SECURITY
  // Crucial for Firebase Security Rules. Ensures only the owner can read/write this note
  // when synced to the cloud. Also helps filter notes locally if multiple accounts share a device.
  TextColumn get ownerUid => text().nullable()();

  // SYNC TIMESTAMPS & VERSIONING
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // The "Tombstone" Pattern: We soft-delete notes instead of hard-deleting them.
  // If we hard-deleted, other offline devices wouldn't know it was deleted and would
  // just sync the note back. The cloud reads this and tells all devices to delete it.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // Conflict resolution counter. Increments by 1 on EVERY local edit.
  // If two devices edit offline, the cloud uses this to know which payload has more
  // recent work, completely ignoring broken/inaccurate device system clocks.
  IntColumn get updateCounter => integer().withDefault(const Constant(1))();

  // SYNC STATUS
  // Typically maps to an Enum (e.g., 0 = synced, 1 = pending, 2 = error).
  // cloudSyncStatus tracks Firebase sync. localSyncStatus tracks P2P Wi-Fi sync.
  IntColumn get cloudSyncStatus => integer().withDefault(const Constant(0))();

  IntColumn get localSyncStatus => integer().withDefault(const Constant(0))();

  // METADATA (Debugging tools)
  // Helps track down sync bugs in edge cases (e.g., "Why did this note delete? Ah, Windows did it.")
  TextColumn get creationPlatform => text().nullable()();
  TextColumn get creationDevice => text().nullable()(); // e.g., "Pixel 7", "DESKTOP-XT49"

  TextColumn get lastEditedPlatform => text().nullable()();
  TextColumn get lastEditedDevice => text().nullable()();

  TextColumn get deletedPlatform => text().nullable()();
  TextColumn get deletedDevice => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};



}
