// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFFFFFFFF),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderAtMeta = const VerificationMeta(
    'reminderAt',
  );
  @override
  late final GeneratedColumn<DateTime> reminderAt = GeneratedColumn<DateTime>(
    'reminder_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasAttachmentsMeta = const VerificationMeta(
    'hasAttachments',
  );
  @override
  late final GeneratedColumn<bool> hasAttachments = GeneratedColumn<bool>(
    'has_attachments',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_attachments" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('plain_text'),
  );
  static const VerificationMeta _isSharedMeta = const VerificationMeta(
    'isShared',
  );
  @override
  late final GeneratedColumn<bool> isShared = GeneratedColumn<bool>(
    'is_shared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_shared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerUidMeta = const VerificationMeta(
    'ownerUid',
  );
  @override
  late final GeneratedColumn<String> ownerUid = GeneratedColumn<String>(
    'owner_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerEmailMeta = const VerificationMeta(
    'ownerEmail',
  );
  @override
  late final GeneratedColumn<String> ownerEmail = GeneratedColumn<String>(
    'owner_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firestoreIdMeta = const VerificationMeta(
    'firestoreId',
  );
  @override
  late final GeneratedColumn<String> firestoreId = GeneratedColumn<String>(
    'firestore_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _versionCounterMeta = const VerificationMeta(
    'versionCounter',
  );
  @override
  late final GeneratedColumn<int> versionCounter = GeneratedColumn<int>(
    'version_counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _creationPlatformMeta = const VerificationMeta(
    'creationPlatform',
  );
  @override
  late final GeneratedColumn<String> creationPlatform = GeneratedColumn<String>(
    'creation_platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creationDeviceMeta = const VerificationMeta(
    'creationDevice',
  );
  @override
  late final GeneratedColumn<String> creationDevice = GeneratedColumn<String>(
    'creation_device',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastEditedDeviceMeta = const VerificationMeta(
    'lastEditedDevice',
  );
  @override
  late final GeneratedColumn<String> lastEditedDevice = GeneratedColumn<String>(
    'last_edited_device',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedPlatformMeta = const VerificationMeta(
    'deletedPlatform',
  );
  @override
  late final GeneratedColumn<String> deletedPlatform = GeneratedColumn<String>(
    'deleted_platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    color,
    isPinned,
    isArchived,
    isLocked,
    position,
    tags,
    reminderAt,
    hasAttachments,
    contentType,
    isShared,
    folderId,
    ownerUid,
    ownerEmail,
    createdAt,
    updatedAt,
    deletedAt,
    firestoreId,
    syncStatus,
    versionCounter,
    creationPlatform,
    creationDevice,
    lastEditedDevice,
    deletedPlatform,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('reminder_at')) {
      context.handle(
        _reminderAtMeta,
        reminderAt.isAcceptableOrUnknown(data['reminder_at']!, _reminderAtMeta),
      );
    }
    if (data.containsKey('has_attachments')) {
      context.handle(
        _hasAttachmentsMeta,
        hasAttachments.isAcceptableOrUnknown(
          data['has_attachments']!,
          _hasAttachmentsMeta,
        ),
      );
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    }
    if (data.containsKey('is_shared')) {
      context.handle(
        _isSharedMeta,
        isShared.isAcceptableOrUnknown(data['is_shared']!, _isSharedMeta),
      );
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('owner_uid')) {
      context.handle(
        _ownerUidMeta,
        ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta),
      );
    }
    if (data.containsKey('owner_email')) {
      context.handle(
        _ownerEmailMeta,
        ownerEmail.isAcceptableOrUnknown(data['owner_email']!, _ownerEmailMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('firestore_id')) {
      context.handle(
        _firestoreIdMeta,
        firestoreId.isAcceptableOrUnknown(
          data['firestore_id']!,
          _firestoreIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version_counter')) {
      context.handle(
        _versionCounterMeta,
        versionCounter.isAcceptableOrUnknown(
          data['version_counter']!,
          _versionCounterMeta,
        ),
      );
    }
    if (data.containsKey('creation_platform')) {
      context.handle(
        _creationPlatformMeta,
        creationPlatform.isAcceptableOrUnknown(
          data['creation_platform']!,
          _creationPlatformMeta,
        ),
      );
    }
    if (data.containsKey('creation_device')) {
      context.handle(
        _creationDeviceMeta,
        creationDevice.isAcceptableOrUnknown(
          data['creation_device']!,
          _creationDeviceMeta,
        ),
      );
    }
    if (data.containsKey('last_edited_device')) {
      context.handle(
        _lastEditedDeviceMeta,
        lastEditedDevice.isAcceptableOrUnknown(
          data['last_edited_device']!,
          _lastEditedDeviceMeta,
        ),
      );
    }
    if (data.containsKey('deleted_platform')) {
      context.handle(
        _deletedPlatformMeta,
        deletedPlatform.isAcceptableOrUnknown(
          data['deleted_platform']!,
          _deletedPlatformMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locked'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      reminderAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reminder_at'],
      ),
      hasAttachments: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_attachments'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      isShared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_shared'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      ownerUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_uid'],
      ),
      ownerEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_email'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      firestoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firestore_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      versionCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_counter'],
      )!,
      creationPlatform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creation_platform'],
      ),
      creationDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creation_device'],
      ),
      lastEditedDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_edited_device'],
      ),
      deletedPlatform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_platform'],
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final String title;
  final String content;
  final int color;
  final bool isPinned;
  final bool isArchived;
  final bool isLocked;
  final int position;
  final String? tags;
  final DateTime? reminderAt;
  final bool hasAttachments;
  final String contentType;
  final bool isShared;
  final String? folderId;
  final String? ownerUid;
  final String? ownerEmail;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? firestoreId;
  final int syncStatus;
  final int versionCounter;
  final String? creationPlatform;
  final String? creationDevice;
  final String? lastEditedDevice;
  final String? deletedPlatform;
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.isPinned,
    required this.isArchived,
    required this.isLocked,
    required this.position,
    this.tags,
    this.reminderAt,
    required this.hasAttachments,
    required this.contentType,
    required this.isShared,
    this.folderId,
    this.ownerUid,
    this.ownerEmail,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.firestoreId,
    required this.syncStatus,
    required this.versionCounter,
    this.creationPlatform,
    this.creationDevice,
    this.lastEditedDevice,
    this.deletedPlatform,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['color'] = Variable<int>(color);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_locked'] = Variable<bool>(isLocked);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<DateTime>(reminderAt);
    }
    map['has_attachments'] = Variable<bool>(hasAttachments);
    map['content_type'] = Variable<String>(contentType);
    map['is_shared'] = Variable<bool>(isShared);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    if (!nullToAbsent || ownerUid != null) {
      map['owner_uid'] = Variable<String>(ownerUid);
    }
    if (!nullToAbsent || ownerEmail != null) {
      map['owner_email'] = Variable<String>(ownerEmail);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || firestoreId != null) {
      map['firestore_id'] = Variable<String>(firestoreId);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['version_counter'] = Variable<int>(versionCounter);
    if (!nullToAbsent || creationPlatform != null) {
      map['creation_platform'] = Variable<String>(creationPlatform);
    }
    if (!nullToAbsent || creationDevice != null) {
      map['creation_device'] = Variable<String>(creationDevice);
    }
    if (!nullToAbsent || lastEditedDevice != null) {
      map['last_edited_device'] = Variable<String>(lastEditedDevice);
    }
    if (!nullToAbsent || deletedPlatform != null) {
      map['deleted_platform'] = Variable<String>(deletedPlatform);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      color: Value(color),
      isPinned: Value(isPinned),
      isArchived: Value(isArchived),
      isLocked: Value(isLocked),
      position: Value(position),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      hasAttachments: Value(hasAttachments),
      contentType: Value(contentType),
      isShared: Value(isShared),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      ownerUid: ownerUid == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUid),
      ownerEmail: ownerEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerEmail),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      firestoreId: firestoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(firestoreId),
      syncStatus: Value(syncStatus),
      versionCounter: Value(versionCounter),
      creationPlatform: creationPlatform == null && nullToAbsent
          ? const Value.absent()
          : Value(creationPlatform),
      creationDevice: creationDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(creationDevice),
      lastEditedDevice: lastEditedDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEditedDevice),
      deletedPlatform: deletedPlatform == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedPlatform),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      color: serializer.fromJson<int>(json['color']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      position: serializer.fromJson<int>(json['position']),
      tags: serializer.fromJson<String?>(json['tags']),
      reminderAt: serializer.fromJson<DateTime?>(json['reminderAt']),
      hasAttachments: serializer.fromJson<bool>(json['hasAttachments']),
      contentType: serializer.fromJson<String>(json['contentType']),
      isShared: serializer.fromJson<bool>(json['isShared']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      ownerUid: serializer.fromJson<String?>(json['ownerUid']),
      ownerEmail: serializer.fromJson<String?>(json['ownerEmail']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      firestoreId: serializer.fromJson<String?>(json['firestoreId']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      versionCounter: serializer.fromJson<int>(json['versionCounter']),
      creationPlatform: serializer.fromJson<String?>(json['creationPlatform']),
      creationDevice: serializer.fromJson<String?>(json['creationDevice']),
      lastEditedDevice: serializer.fromJson<String?>(json['lastEditedDevice']),
      deletedPlatform: serializer.fromJson<String?>(json['deletedPlatform']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'color': serializer.toJson<int>(color),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isLocked': serializer.toJson<bool>(isLocked),
      'position': serializer.toJson<int>(position),
      'tags': serializer.toJson<String?>(tags),
      'reminderAt': serializer.toJson<DateTime?>(reminderAt),
      'hasAttachments': serializer.toJson<bool>(hasAttachments),
      'contentType': serializer.toJson<String>(contentType),
      'isShared': serializer.toJson<bool>(isShared),
      'folderId': serializer.toJson<String?>(folderId),
      'ownerUid': serializer.toJson<String?>(ownerUid),
      'ownerEmail': serializer.toJson<String?>(ownerEmail),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'firestoreId': serializer.toJson<String?>(firestoreId),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'versionCounter': serializer.toJson<int>(versionCounter),
      'creationPlatform': serializer.toJson<String?>(creationPlatform),
      'creationDevice': serializer.toJson<String?>(creationDevice),
      'lastEditedDevice': serializer.toJson<String?>(lastEditedDevice),
      'deletedPlatform': serializer.toJson<String?>(deletedPlatform),
    };
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? color,
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
    int? position,
    Value<String?> tags = const Value.absent(),
    Value<DateTime?> reminderAt = const Value.absent(),
    bool? hasAttachments,
    String? contentType,
    bool? isShared,
    Value<String?> folderId = const Value.absent(),
    Value<String?> ownerUid = const Value.absent(),
    Value<String?> ownerEmail = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> firestoreId = const Value.absent(),
    int? syncStatus,
    int? versionCounter,
    Value<String?> creationPlatform = const Value.absent(),
    Value<String?> creationDevice = const Value.absent(),
    Value<String?> lastEditedDevice = const Value.absent(),
    Value<String?> deletedPlatform = const Value.absent(),
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    color: color ?? this.color,
    isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived,
    isLocked: isLocked ?? this.isLocked,
    position: position ?? this.position,
    tags: tags.present ? tags.value : this.tags,
    reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
    hasAttachments: hasAttachments ?? this.hasAttachments,
    contentType: contentType ?? this.contentType,
    isShared: isShared ?? this.isShared,
    folderId: folderId.present ? folderId.value : this.folderId,
    ownerUid: ownerUid.present ? ownerUid.value : this.ownerUid,
    ownerEmail: ownerEmail.present ? ownerEmail.value : this.ownerEmail,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    firestoreId: firestoreId.present ? firestoreId.value : this.firestoreId,
    syncStatus: syncStatus ?? this.syncStatus,
    versionCounter: versionCounter ?? this.versionCounter,
    creationPlatform: creationPlatform.present
        ? creationPlatform.value
        : this.creationPlatform,
    creationDevice: creationDevice.present
        ? creationDevice.value
        : this.creationDevice,
    lastEditedDevice: lastEditedDevice.present
        ? lastEditedDevice.value
        : this.lastEditedDevice,
    deletedPlatform: deletedPlatform.present
        ? deletedPlatform.value
        : this.deletedPlatform,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      color: data.color.present ? data.color.value : this.color,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      position: data.position.present ? data.position.value : this.position,
      tags: data.tags.present ? data.tags.value : this.tags,
      reminderAt: data.reminderAt.present
          ? data.reminderAt.value
          : this.reminderAt,
      hasAttachments: data.hasAttachments.present
          ? data.hasAttachments.value
          : this.hasAttachments,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      isShared: data.isShared.present ? data.isShared.value : this.isShared,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      ownerEmail: data.ownerEmail.present
          ? data.ownerEmail.value
          : this.ownerEmail,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      firestoreId: data.firestoreId.present
          ? data.firestoreId.value
          : this.firestoreId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      versionCounter: data.versionCounter.present
          ? data.versionCounter.value
          : this.versionCounter,
      creationPlatform: data.creationPlatform.present
          ? data.creationPlatform.value
          : this.creationPlatform,
      creationDevice: data.creationDevice.present
          ? data.creationDevice.value
          : this.creationDevice,
      lastEditedDevice: data.lastEditedDevice.present
          ? data.lastEditedDevice.value
          : this.lastEditedDevice,
      deletedPlatform: data.deletedPlatform.present
          ? data.deletedPlatform.value
          : this.deletedPlatform,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('color: $color, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('isLocked: $isLocked, ')
          ..write('position: $position, ')
          ..write('tags: $tags, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('contentType: $contentType, ')
          ..write('isShared: $isShared, ')
          ..write('folderId: $folderId, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('ownerEmail: $ownerEmail, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('versionCounter: $versionCounter, ')
          ..write('creationPlatform: $creationPlatform, ')
          ..write('creationDevice: $creationDevice, ')
          ..write('lastEditedDevice: $lastEditedDevice, ')
          ..write('deletedPlatform: $deletedPlatform')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    content,
    color,
    isPinned,
    isArchived,
    isLocked,
    position,
    tags,
    reminderAt,
    hasAttachments,
    contentType,
    isShared,
    folderId,
    ownerUid,
    ownerEmail,
    createdAt,
    updatedAt,
    deletedAt,
    firestoreId,
    syncStatus,
    versionCounter,
    creationPlatform,
    creationDevice,
    lastEditedDevice,
    deletedPlatform,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.color == this.color &&
          other.isPinned == this.isPinned &&
          other.isArchived == this.isArchived &&
          other.isLocked == this.isLocked &&
          other.position == this.position &&
          other.tags == this.tags &&
          other.reminderAt == this.reminderAt &&
          other.hasAttachments == this.hasAttachments &&
          other.contentType == this.contentType &&
          other.isShared == this.isShared &&
          other.folderId == this.folderId &&
          other.ownerUid == this.ownerUid &&
          other.ownerEmail == this.ownerEmail &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.firestoreId == this.firestoreId &&
          other.syncStatus == this.syncStatus &&
          other.versionCounter == this.versionCounter &&
          other.creationPlatform == this.creationPlatform &&
          other.creationDevice == this.creationDevice &&
          other.lastEditedDevice == this.lastEditedDevice &&
          other.deletedPlatform == this.deletedPlatform);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<int> color;
  final Value<bool> isPinned;
  final Value<bool> isArchived;
  final Value<bool> isLocked;
  final Value<int> position;
  final Value<String?> tags;
  final Value<DateTime?> reminderAt;
  final Value<bool> hasAttachments;
  final Value<String> contentType;
  final Value<bool> isShared;
  final Value<String?> folderId;
  final Value<String?> ownerUid;
  final Value<String?> ownerEmail;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> firestoreId;
  final Value<int> syncStatus;
  final Value<int> versionCounter;
  final Value<String?> creationPlatform;
  final Value<String?> creationDevice;
  final Value<String?> lastEditedDevice;
  final Value<String?> deletedPlatform;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.color = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.position = const Value.absent(),
    this.tags = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.hasAttachments = const Value.absent(),
    this.contentType = const Value.absent(),
    this.isShared = const Value.absent(),
    this.folderId = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.ownerEmail = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.versionCounter = const Value.absent(),
    this.creationPlatform = const Value.absent(),
    this.creationDevice = const Value.absent(),
    this.lastEditedDevice = const Value.absent(),
    this.deletedPlatform = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String content,
    this.color = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.position = const Value.absent(),
    this.tags = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.hasAttachments = const Value.absent(),
    this.contentType = const Value.absent(),
    this.isShared = const Value.absent(),
    this.folderId = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.ownerEmail = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.versionCounter = const Value.absent(),
    this.creationPlatform = const Value.absent(),
    this.creationDevice = const Value.absent(),
    this.lastEditedDevice = const Value.absent(),
    this.deletedPlatform = const Value.absent(),
  }) : title = Value(title),
       content = Value(content);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<int>? color,
    Expression<bool>? isPinned,
    Expression<bool>? isArchived,
    Expression<bool>? isLocked,
    Expression<int>? position,
    Expression<String>? tags,
    Expression<DateTime>? reminderAt,
    Expression<bool>? hasAttachments,
    Expression<String>? contentType,
    Expression<bool>? isShared,
    Expression<String>? folderId,
    Expression<String>? ownerUid,
    Expression<String>? ownerEmail,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? firestoreId,
    Expression<int>? syncStatus,
    Expression<int>? versionCounter,
    Expression<String>? creationPlatform,
    Expression<String>? creationDevice,
    Expression<String>? lastEditedDevice,
    Expression<String>? deletedPlatform,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (color != null) 'color': color,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isArchived != null) 'is_archived': isArchived,
      if (isLocked != null) 'is_locked': isLocked,
      if (position != null) 'position': position,
      if (tags != null) 'tags': tags,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (hasAttachments != null) 'has_attachments': hasAttachments,
      if (contentType != null) 'content_type': contentType,
      if (isShared != null) 'is_shared': isShared,
      if (folderId != null) 'folder_id': folderId,
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (ownerEmail != null) 'owner_email': ownerEmail,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (firestoreId != null) 'firestore_id': firestoreId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (versionCounter != null) 'version_counter': versionCounter,
      if (creationPlatform != null) 'creation_platform': creationPlatform,
      if (creationDevice != null) 'creation_device': creationDevice,
      if (lastEditedDevice != null) 'last_edited_device': lastEditedDevice,
      if (deletedPlatform != null) 'deleted_platform': deletedPlatform,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? content,
    Value<int>? color,
    Value<bool>? isPinned,
    Value<bool>? isArchived,
    Value<bool>? isLocked,
    Value<int>? position,
    Value<String?>? tags,
    Value<DateTime?>? reminderAt,
    Value<bool>? hasAttachments,
    Value<String>? contentType,
    Value<bool>? isShared,
    Value<String?>? folderId,
    Value<String?>? ownerUid,
    Value<String?>? ownerEmail,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? firestoreId,
    Value<int>? syncStatus,
    Value<int>? versionCounter,
    Value<String?>? creationPlatform,
    Value<String?>? creationDevice,
    Value<String?>? lastEditedDevice,
    Value<String?>? deletedPlatform,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isLocked: isLocked ?? this.isLocked,
      position: position ?? this.position,
      tags: tags ?? this.tags,
      reminderAt: reminderAt ?? this.reminderAt,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      contentType: contentType ?? this.contentType,
      isShared: isShared ?? this.isShared,
      folderId: folderId ?? this.folderId,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      firestoreId: firestoreId ?? this.firestoreId,
      syncStatus: syncStatus ?? this.syncStatus,
      versionCounter: versionCounter ?? this.versionCounter,
      creationPlatform: creationPlatform ?? this.creationPlatform,
      creationDevice: creationDevice ?? this.creationDevice,
      lastEditedDevice: lastEditedDevice ?? this.lastEditedDevice,
      deletedPlatform: deletedPlatform ?? this.deletedPlatform,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<DateTime>(reminderAt.value);
    }
    if (hasAttachments.present) {
      map['has_attachments'] = Variable<bool>(hasAttachments.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (isShared.present) {
      map['is_shared'] = Variable<bool>(isShared.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
    }
    if (ownerEmail.present) {
      map['owner_email'] = Variable<String>(ownerEmail.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (firestoreId.present) {
      map['firestore_id'] = Variable<String>(firestoreId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (versionCounter.present) {
      map['version_counter'] = Variable<int>(versionCounter.value);
    }
    if (creationPlatform.present) {
      map['creation_platform'] = Variable<String>(creationPlatform.value);
    }
    if (creationDevice.present) {
      map['creation_device'] = Variable<String>(creationDevice.value);
    }
    if (lastEditedDevice.present) {
      map['last_edited_device'] = Variable<String>(lastEditedDevice.value);
    }
    if (deletedPlatform.present) {
      map['deleted_platform'] = Variable<String>(deletedPlatform.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('color: $color, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('isLocked: $isLocked, ')
          ..write('position: $position, ')
          ..write('tags: $tags, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('contentType: $contentType, ')
          ..write('isShared: $isShared, ')
          ..write('folderId: $folderId, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('ownerEmail: $ownerEmail, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('versionCounter: $versionCounter, ')
          ..write('creationPlatform: $creationPlatform, ')
          ..write('creationDevice: $creationDevice, ')
          ..write('lastEditedDevice: $lastEditedDevice, ')
          ..write('deletedPlatform: $deletedPlatform')
          ..write(')'))
        .toString();
  }
}

abstract class _$NoteDriftDatabase extends GeneratedDatabase {
  _$NoteDriftDatabase(QueryExecutor e) : super(e);
  $NoteDriftDatabaseManager get managers => $NoteDriftDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [notes];
}

typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      required String title,
      required String content,
      Value<int> color,
      Value<bool> isPinned,
      Value<bool> isArchived,
      Value<bool> isLocked,
      Value<int> position,
      Value<String?> tags,
      Value<DateTime?> reminderAt,
      Value<bool> hasAttachments,
      Value<String> contentType,
      Value<bool> isShared,
      Value<String?> folderId,
      Value<String?> ownerUid,
      Value<String?> ownerEmail,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> firestoreId,
      Value<int> syncStatus,
      Value<int> versionCounter,
      Value<String?> creationPlatform,
      Value<String?> creationDevice,
      Value<String?> lastEditedDevice,
      Value<String?> deletedPlatform,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> content,
      Value<int> color,
      Value<bool> isPinned,
      Value<bool> isArchived,
      Value<bool> isLocked,
      Value<int> position,
      Value<String?> tags,
      Value<DateTime?> reminderAt,
      Value<bool> hasAttachments,
      Value<String> contentType,
      Value<bool> isShared,
      Value<String?> folderId,
      Value<String?> ownerUid,
      Value<String?> ownerEmail,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> firestoreId,
      Value<int> syncStatus,
      Value<int> versionCounter,
      Value<String?> creationPlatform,
      Value<String?> creationDevice,
      Value<String?> lastEditedDevice,
      Value<String?> deletedPlatform,
    });

class $$NotesTableFilterComposer
    extends Composer<_$NoteDriftDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUid => $composableBuilder(
    column: $table.ownerUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerEmail => $composableBuilder(
    column: $table.ownerEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionCounter => $composableBuilder(
    column: $table.versionCounter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creationPlatform => $composableBuilder(
    column: $table.creationPlatform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creationDevice => $composableBuilder(
    column: $table.creationDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastEditedDevice => $composableBuilder(
    column: $table.lastEditedDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedPlatform => $composableBuilder(
    column: $table.deletedPlatform,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$NoteDriftDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUid => $composableBuilder(
    column: $table.ownerUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerEmail => $composableBuilder(
    column: $table.ownerEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionCounter => $composableBuilder(
    column: $table.versionCounter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creationPlatform => $composableBuilder(
    column: $table.creationPlatform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creationDevice => $composableBuilder(
    column: $table.creationDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastEditedDevice => $composableBuilder(
    column: $table.lastEditedDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedPlatform => $composableBuilder(
    column: $table.deletedPlatform,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$NoteDriftDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isShared =>
      $composableBuilder(column: $table.isShared, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get ownerUid =>
      $composableBuilder(column: $table.ownerUid, builder: (column) => column);

  GeneratedColumn<String> get ownerEmail => $composableBuilder(
    column: $table.ownerEmail,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get versionCounter => $composableBuilder(
    column: $table.versionCounter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creationPlatform => $composableBuilder(
    column: $table.creationPlatform,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creationDevice => $composableBuilder(
    column: $table.creationDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastEditedDevice => $composableBuilder(
    column: $table.lastEditedDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deletedPlatform => $composableBuilder(
    column: $table.deletedPlatform,
    builder: (column) => column,
  );
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$NoteDriftDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$NoteDriftDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$NoteDriftDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<bool> hasAttachments = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<bool> isShared = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<String?> ownerUid = const Value.absent(),
                Value<String?> ownerEmail = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> versionCounter = const Value.absent(),
                Value<String?> creationPlatform = const Value.absent(),
                Value<String?> creationDevice = const Value.absent(),
                Value<String?> lastEditedDevice = const Value.absent(),
                Value<String?> deletedPlatform = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                title: title,
                content: content,
                color: color,
                isPinned: isPinned,
                isArchived: isArchived,
                isLocked: isLocked,
                position: position,
                tags: tags,
                reminderAt: reminderAt,
                hasAttachments: hasAttachments,
                contentType: contentType,
                isShared: isShared,
                folderId: folderId,
                ownerUid: ownerUid,
                ownerEmail: ownerEmail,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                firestoreId: firestoreId,
                syncStatus: syncStatus,
                versionCounter: versionCounter,
                creationPlatform: creationPlatform,
                creationDevice: creationDevice,
                lastEditedDevice: lastEditedDevice,
                deletedPlatform: deletedPlatform,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String content,
                Value<int> color = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<bool> hasAttachments = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<bool> isShared = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<String?> ownerUid = const Value.absent(),
                Value<String?> ownerEmail = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> versionCounter = const Value.absent(),
                Value<String?> creationPlatform = const Value.absent(),
                Value<String?> creationDevice = const Value.absent(),
                Value<String?> lastEditedDevice = const Value.absent(),
                Value<String?> deletedPlatform = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                title: title,
                content: content,
                color: color,
                isPinned: isPinned,
                isArchived: isArchived,
                isLocked: isLocked,
                position: position,
                tags: tags,
                reminderAt: reminderAt,
                hasAttachments: hasAttachments,
                contentType: contentType,
                isShared: isShared,
                folderId: folderId,
                ownerUid: ownerUid,
                ownerEmail: ownerEmail,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                firestoreId: firestoreId,
                syncStatus: syncStatus,
                versionCounter: versionCounter,
                creationPlatform: creationPlatform,
                creationDevice: creationDevice,
                lastEditedDevice: lastEditedDevice,
                deletedPlatform: deletedPlatform,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$NoteDriftDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$NoteDriftDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;

class $NoteDriftDatabaseManager {
  final _$NoteDriftDatabase _db;
  $NoteDriftDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
}
