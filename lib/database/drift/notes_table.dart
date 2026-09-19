import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// To trigger fresh code gen use 'dart run build_runner build'
class Notes extends Table {

  // PRIMARY KEYS & CORE DATA
  // The local fast-lookup ID (Only used for local UI, NEVER use this for syncing)
  // IntColumn get id => integer().autoIncrement()();


// The Global Sync ID. This is what we use to compare notes between devices.
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4())();

  TextColumn get title => text().withLength(min: 0, max: 255)();
  TextColumn get content => text()();


  // UI & UX FEATURES
  IntColumn get color => integer().withDefault(const Constant(0xFFFFFFFF))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  // Note: Stored as a delimited string (e.g., "|work|urgent|") for accurate searching
  TextColumn get tags => text().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();

  // Future-proofing: If we ever allow image/audio uploads, this boolean
  // lets your UI show a paperclip icon without parsing the whole content string.
  BoolColumn get hasAttachments => boolean().withDefault(const Constant(false))();


  // EDITOR & COLLAB (FUTURE-PROOFING)
  // e.g., 'plain_text', 'markdown', 'checklist', 'drawing'
  TextColumn get contentType => text().withDefault(const Constant('plain_text'))();
  // Prepares the UI for collaborative features
  BoolColumn get isShared => boolean().withDefault(const Constant(false))();


  // RELATIONAL DATA
  // Future-proofing: Points to the firestoreId of a Folder. Null means it sits on the root screen.
  TextColumn get folderId => text().nullable()();


  // MULTI-TENANT SECURITY
  // Future-proofing: Building the privacy wall.
  TextColumn get ownerUid => text().nullable()();
  TextColumn get ownerEmail => text().nullable()();


  // TIMESTAMPS (THE LWW ENGINE)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // REQUIRES a timestamp to compare. It defaults to the creation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // Essential for P2P: Soft deletes ("Tombstones"). If you hard-delete a note,
  // the other device won't know, and will just re-sync it back to you.
  DateTimeColumn get deletedAt => dateTime().nullable()();


  // SYNC ENGINE
  // TextColumn get firestoreId => text().nullable()();
  IntColumn get cloudSyncStatus => integer().withDefault(const Constant(0))();
  IntColumn get localSyncStatus => integer().withDefault(const Constant(0))();
  // Increments on every edit. More reliable than timestamps for advanced conflict resolution.
  IntColumn get versionCounter => integer().withDefault(const Constant(1))();


  // METADATA & DEBUGGING
  TextColumn get creationPlatform => text().nullable()();
  TextColumn get creationDevice => text().nullable()();

  // Future-proofing: When a conflict happens, it helps to know which device caused it.
  TextColumn get lastEditedPlatform => text().nullable()();
  TextColumn get lastEditedDevice => text().nullable()();


  // Tracks which platform initiated the soft-delete (e.g., 'android', 'windows')
  TextColumn get deletedPlatform => text().nullable()();
  TextColumn get deletedDevice => text().nullable()();
}