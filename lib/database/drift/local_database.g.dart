// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  static const VerificationMeta _cloudSyncStatusMeta = const VerificationMeta(
    'cloudSyncStatus',
  );
  @override
  late final GeneratedColumn<int> cloudSyncStatus = GeneratedColumn<int>(
    'cloud_sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localSyncStatusMeta = const VerificationMeta(
    'localSyncStatus',
  );
  @override
  late final GeneratedColumn<int> localSyncStatus = GeneratedColumn<int>(
    'local_sync_status',
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
  static const VerificationMeta _lastEditedPlatformMeta =
      const VerificationMeta('lastEditedPlatform');
  @override
  late final GeneratedColumn<String> lastEditedPlatform =
      GeneratedColumn<String>(
        'last_edited_platform',
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
  static const VerificationMeta _deletedDeviceMeta = const VerificationMeta(
    'deletedDevice',
  );
  @override
  late final GeneratedColumn<String> deletedDevice = GeneratedColumn<String>(
    'deleted_device',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
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
    cloudSyncStatus,
    localSyncStatus,
    versionCounter,
    creationPlatform,
    creationDevice,
    lastEditedPlatform,
    lastEditedDevice,
    deletedPlatform,
    deletedDevice,
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
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
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
    if (data.containsKey('cloud_sync_status')) {
      context.handle(
        _cloudSyncStatusMeta,
        cloudSyncStatus.isAcceptableOrUnknown(
          data['cloud_sync_status']!,
          _cloudSyncStatusMeta,
        ),
      );
    }
    if (data.containsKey('local_sync_status')) {
      context.handle(
        _localSyncStatusMeta,
        localSyncStatus.isAcceptableOrUnknown(
          data['local_sync_status']!,
          _localSyncStatusMeta,
        ),
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
    if (data.containsKey('last_edited_platform')) {
      context.handle(
        _lastEditedPlatformMeta,
        lastEditedPlatform.isAcceptableOrUnknown(
          data['last_edited_platform']!,
          _lastEditedPlatformMeta,
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
    if (data.containsKey('deleted_device')) {
      context.handle(
        _deletedDeviceMeta,
        deletedDevice.isAcceptableOrUnknown(
          data['deleted_device']!,
          _deletedDeviceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
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
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      cloudSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cloud_sync_status'],
      )!,
      localSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_sync_status'],
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
      lastEditedPlatform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_edited_platform'],
      ),
      lastEditedDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_edited_device'],
      ),
      deletedPlatform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_platform'],
      ),
      deletedDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_device'],
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String uuid;
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
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int cloudSyncStatus;
  final int localSyncStatus;
  final int versionCounter;
  final String? creationPlatform;
  final String? creationDevice;
  final String? lastEditedPlatform;
  final String? lastEditedDevice;
  final String? deletedPlatform;
  final String? deletedDevice;
  const Note({
    required this.uuid,
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
    required this.updatedAt,
    this.deletedAt,
    required this.cloudSyncStatus,
    required this.localSyncStatus,
    required this.versionCounter,
    this.creationPlatform,
    this.creationDevice,
    this.lastEditedPlatform,
    this.lastEditedDevice,
    this.deletedPlatform,
    this.deletedDevice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
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
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['cloud_sync_status'] = Variable<int>(cloudSyncStatus);
    map['local_sync_status'] = Variable<int>(localSyncStatus);
    map['version_counter'] = Variable<int>(versionCounter);
    if (!nullToAbsent || creationPlatform != null) {
      map['creation_platform'] = Variable<String>(creationPlatform);
    }
    if (!nullToAbsent || creationDevice != null) {
      map['creation_device'] = Variable<String>(creationDevice);
    }
    if (!nullToAbsent || lastEditedPlatform != null) {
      map['last_edited_platform'] = Variable<String>(lastEditedPlatform);
    }
    if (!nullToAbsent || lastEditedDevice != null) {
      map['last_edited_device'] = Variable<String>(lastEditedDevice);
    }
    if (!nullToAbsent || deletedPlatform != null) {
      map['deleted_platform'] = Variable<String>(deletedPlatform);
    }
    if (!nullToAbsent || deletedDevice != null) {
      map['deleted_device'] = Variable<String>(deletedDevice);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      uuid: Value(uuid),
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
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      cloudSyncStatus: Value(cloudSyncStatus),
      localSyncStatus: Value(localSyncStatus),
      versionCounter: Value(versionCounter),
      creationPlatform: creationPlatform == null && nullToAbsent
          ? const Value.absent()
          : Value(creationPlatform),
      creationDevice: creationDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(creationDevice),
      lastEditedPlatform: lastEditedPlatform == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEditedPlatform),
      lastEditedDevice: lastEditedDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEditedDevice),
      deletedPlatform: deletedPlatform == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedPlatform),
      deletedDevice: deletedDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedDevice),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      uuid: serializer.fromJson<String>(json['uuid']),
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
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      cloudSyncStatus: serializer.fromJson<int>(json['cloudSyncStatus']),
      localSyncStatus: serializer.fromJson<int>(json['localSyncStatus']),
      versionCounter: serializer.fromJson<int>(json['versionCounter']),
      creationPlatform: serializer.fromJson<String?>(json['creationPlatform']),
      creationDevice: serializer.fromJson<String?>(json['creationDevice']),
      lastEditedPlatform: serializer.fromJson<String?>(
        json['lastEditedPlatform'],
      ),
      lastEditedDevice: serializer.fromJson<String?>(json['lastEditedDevice']),
      deletedPlatform: serializer.fromJson<String?>(json['deletedPlatform']),
      deletedDevice: serializer.fromJson<String?>(json['deletedDevice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
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
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'cloudSyncStatus': serializer.toJson<int>(cloudSyncStatus),
      'localSyncStatus': serializer.toJson<int>(localSyncStatus),
      'versionCounter': serializer.toJson<int>(versionCounter),
      'creationPlatform': serializer.toJson<String?>(creationPlatform),
      'creationDevice': serializer.toJson<String?>(creationDevice),
      'lastEditedPlatform': serializer.toJson<String?>(lastEditedPlatform),
      'lastEditedDevice': serializer.toJson<String?>(lastEditedDevice),
      'deletedPlatform': serializer.toJson<String?>(deletedPlatform),
      'deletedDevice': serializer.toJson<String?>(deletedDevice),
    };
  }

  Note copyWith({
    String? uuid,
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
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? cloudSyncStatus,
    int? localSyncStatus,
    int? versionCounter,
    Value<String?> creationPlatform = const Value.absent(),
    Value<String?> creationDevice = const Value.absent(),
    Value<String?> lastEditedPlatform = const Value.absent(),
    Value<String?> lastEditedDevice = const Value.absent(),
    Value<String?> deletedPlatform = const Value.absent(),
    Value<String?> deletedDevice = const Value.absent(),
  }) => Note(
    uuid: uuid ?? this.uuid,
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
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    cloudSyncStatus: cloudSyncStatus ?? this.cloudSyncStatus,
    localSyncStatus: localSyncStatus ?? this.localSyncStatus,
    versionCounter: versionCounter ?? this.versionCounter,
    creationPlatform: creationPlatform.present
        ? creationPlatform.value
        : this.creationPlatform,
    creationDevice: creationDevice.present
        ? creationDevice.value
        : this.creationDevice,
    lastEditedPlatform: lastEditedPlatform.present
        ? lastEditedPlatform.value
        : this.lastEditedPlatform,
    lastEditedDevice: lastEditedDevice.present
        ? lastEditedDevice.value
        : this.lastEditedDevice,
    deletedPlatform: deletedPlatform.present
        ? deletedPlatform.value
        : this.deletedPlatform,
    deletedDevice: deletedDevice.present
        ? deletedDevice.value
        : this.deletedDevice,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
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
      cloudSyncStatus: data.cloudSyncStatus.present
          ? data.cloudSyncStatus.value
          : this.cloudSyncStatus,
      localSyncStatus: data.localSyncStatus.present
          ? data.localSyncStatus.value
          : this.localSyncStatus,
      versionCounter: data.versionCounter.present
          ? data.versionCounter.value
          : this.versionCounter,
      creationPlatform: data.creationPlatform.present
          ? data.creationPlatform.value
          : this.creationPlatform,
      creationDevice: data.creationDevice.present
          ? data.creationDevice.value
          : this.creationDevice,
      lastEditedPlatform: data.lastEditedPlatform.present
          ? data.lastEditedPlatform.value
          : this.lastEditedPlatform,
      lastEditedDevice: data.lastEditedDevice.present
          ? data.lastEditedDevice.value
          : this.lastEditedDevice,
      deletedPlatform: data.deletedPlatform.present
          ? data.deletedPlatform.value
          : this.deletedPlatform,
      deletedDevice: data.deletedDevice.present
          ? data.deletedDevice.value
          : this.deletedDevice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('uuid: $uuid, ')
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
          ..write('cloudSyncStatus: $cloudSyncStatus, ')
          ..write('localSyncStatus: $localSyncStatus, ')
          ..write('versionCounter: $versionCounter, ')
          ..write('creationPlatform: $creationPlatform, ')
          ..write('creationDevice: $creationDevice, ')
          ..write('lastEditedPlatform: $lastEditedPlatform, ')
          ..write('lastEditedDevice: $lastEditedDevice, ')
          ..write('deletedPlatform: $deletedPlatform, ')
          ..write('deletedDevice: $deletedDevice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    uuid,
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
    cloudSyncStatus,
    localSyncStatus,
    versionCounter,
    creationPlatform,
    creationDevice,
    lastEditedPlatform,
    lastEditedDevice,
    deletedPlatform,
    deletedDevice,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.uuid == this.uuid &&
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
          other.cloudSyncStatus == this.cloudSyncStatus &&
          other.localSyncStatus == this.localSyncStatus &&
          other.versionCounter == this.versionCounter &&
          other.creationPlatform == this.creationPlatform &&
          other.creationDevice == this.creationDevice &&
          other.lastEditedPlatform == this.lastEditedPlatform &&
          other.lastEditedDevice == this.lastEditedDevice &&
          other.deletedPlatform == this.deletedPlatform &&
          other.deletedDevice == this.deletedDevice);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> uuid;
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
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> cloudSyncStatus;
  final Value<int> localSyncStatus;
  final Value<int> versionCounter;
  final Value<String?> creationPlatform;
  final Value<String?> creationDevice;
  final Value<String?> lastEditedPlatform;
  final Value<String?> lastEditedDevice;
  final Value<String?> deletedPlatform;
  final Value<String?> deletedDevice;
  final Value<int> rowid;
  const NotesCompanion({
    this.uuid = const Value.absent(),
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
    this.cloudSyncStatus = const Value.absent(),
    this.localSyncStatus = const Value.absent(),
    this.versionCounter = const Value.absent(),
    this.creationPlatform = const Value.absent(),
    this.creationDevice = const Value.absent(),
    this.lastEditedPlatform = const Value.absent(),
    this.lastEditedDevice = const Value.absent(),
    this.deletedPlatform = const Value.absent(),
    this.deletedDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    this.uuid = const Value.absent(),
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
    this.cloudSyncStatus = const Value.absent(),
    this.localSyncStatus = const Value.absent(),
    this.versionCounter = const Value.absent(),
    this.creationPlatform = const Value.absent(),
    this.creationDevice = const Value.absent(),
    this.lastEditedPlatform = const Value.absent(),
    this.lastEditedDevice = const Value.absent(),
    this.deletedPlatform = const Value.absent(),
    this.deletedDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : title = Value(title),
       content = Value(content);
  static Insertable<Note> custom({
    Expression<String>? uuid,
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
    Expression<int>? cloudSyncStatus,
    Expression<int>? localSyncStatus,
    Expression<int>? versionCounter,
    Expression<String>? creationPlatform,
    Expression<String>? creationDevice,
    Expression<String>? lastEditedPlatform,
    Expression<String>? lastEditedDevice,
    Expression<String>? deletedPlatform,
    Expression<String>? deletedDevice,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
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
      if (cloudSyncStatus != null) 'cloud_sync_status': cloudSyncStatus,
      if (localSyncStatus != null) 'local_sync_status': localSyncStatus,
      if (versionCounter != null) 'version_counter': versionCounter,
      if (creationPlatform != null) 'creation_platform': creationPlatform,
      if (creationDevice != null) 'creation_device': creationDevice,
      if (lastEditedPlatform != null)
        'last_edited_platform': lastEditedPlatform,
      if (lastEditedDevice != null) 'last_edited_device': lastEditedDevice,
      if (deletedPlatform != null) 'deleted_platform': deletedPlatform,
      if (deletedDevice != null) 'deleted_device': deletedDevice,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? uuid,
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
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? cloudSyncStatus,
    Value<int>? localSyncStatus,
    Value<int>? versionCounter,
    Value<String?>? creationPlatform,
    Value<String?>? creationDevice,
    Value<String?>? lastEditedPlatform,
    Value<String?>? lastEditedDevice,
    Value<String?>? deletedPlatform,
    Value<String?>? deletedDevice,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      uuid: uuid ?? this.uuid,
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
      cloudSyncStatus: cloudSyncStatus ?? this.cloudSyncStatus,
      localSyncStatus: localSyncStatus ?? this.localSyncStatus,
      versionCounter: versionCounter ?? this.versionCounter,
      creationPlatform: creationPlatform ?? this.creationPlatform,
      creationDevice: creationDevice ?? this.creationDevice,
      lastEditedPlatform: lastEditedPlatform ?? this.lastEditedPlatform,
      lastEditedDevice: lastEditedDevice ?? this.lastEditedDevice,
      deletedPlatform: deletedPlatform ?? this.deletedPlatform,
      deletedDevice: deletedDevice ?? this.deletedDevice,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
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
    if (cloudSyncStatus.present) {
      map['cloud_sync_status'] = Variable<int>(cloudSyncStatus.value);
    }
    if (localSyncStatus.present) {
      map['local_sync_status'] = Variable<int>(localSyncStatus.value);
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
    if (lastEditedPlatform.present) {
      map['last_edited_platform'] = Variable<String>(lastEditedPlatform.value);
    }
    if (lastEditedDevice.present) {
      map['last_edited_device'] = Variable<String>(lastEditedDevice.value);
    }
    if (deletedPlatform.present) {
      map['deleted_platform'] = Variable<String>(deletedPlatform.value);
    }
    if (deletedDevice.present) {
      map['deleted_device'] = Variable<String>(deletedDevice.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('uuid: $uuid, ')
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
          ..write('cloudSyncStatus: $cloudSyncStatus, ')
          ..write('localSyncStatus: $localSyncStatus, ')
          ..write('versionCounter: $versionCounter, ')
          ..write('creationPlatform: $creationPlatform, ')
          ..write('creationDevice: $creationDevice, ')
          ..write('lastEditedPlatform: $lastEditedPlatform, ')
          ..write('lastEditedDevice: $lastEditedDevice, ')
          ..write('deletedPlatform: $deletedPlatform, ')
          ..write('deletedDevice: $deletedDevice, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicePairsTable extends DevicePairs
    with TableInfo<$DevicePairsTable, DevicePair> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicePairsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceUuidMeta = const VerificationMeta(
    'deviceUuid',
  );
  @override
  late final GeneratedColumn<String> deviceUuid = GeneratedColumn<String>(
    'device_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAsHostAtMeta = const VerificationMeta(
    'lastSeenAsHostAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAsHostAt =
      GeneratedColumn<DateTime>(
        'last_seen_as_host_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSeenAsClientAtMeta =
      const VerificationMeta('lastSeenAsClientAt');
  @override
  late final GeneratedColumn<DateTime> lastSeenAsClientAt =
      GeneratedColumn<DateTime>(
        'last_seen_as_client_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _firstPairedAtMeta = const VerificationMeta(
    'firstPairedAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstPairedAt =
      GeneratedColumn<DateTime>(
        'first_paired_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    deviceUuid,
    deviceName,
    lastSeenAsHostAt,
    lastSeenAsClientAt,
    firstPairedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_pairs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DevicePair> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_uuid')) {
      context.handle(
        _deviceUuidMeta,
        deviceUuid.isAcceptableOrUnknown(data['device_uuid']!, _deviceUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceUuidMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('last_seen_as_host_at')) {
      context.handle(
        _lastSeenAsHostAtMeta,
        lastSeenAsHostAt.isAcceptableOrUnknown(
          data['last_seen_as_host_at']!,
          _lastSeenAsHostAtMeta,
        ),
      );
    }
    if (data.containsKey('last_seen_as_client_at')) {
      context.handle(
        _lastSeenAsClientAtMeta,
        lastSeenAsClientAt.isAcceptableOrUnknown(
          data['last_seen_as_client_at']!,
          _lastSeenAsClientAtMeta,
        ),
      );
    }
    if (data.containsKey('first_paired_at')) {
      context.handle(
        _firstPairedAtMeta,
        firstPairedAt.isAcceptableOrUnknown(
          data['first_paired_at']!,
          _firstPairedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceUuid};
  @override
  DevicePair map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DevicePair(
      deviceUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_uuid'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      lastSeenAsHostAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_as_host_at'],
      ),
      lastSeenAsClientAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_as_client_at'],
      ),
      firstPairedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_paired_at'],
      )!,
    );
  }

  @override
  $DevicePairsTable createAlias(String alias) {
    return $DevicePairsTable(attachedDatabase, alias);
  }
}

class DevicePair extends DataClass implements Insertable<DevicePair> {
  final String deviceUuid;
  final String deviceName;
  final DateTime? lastSeenAsHostAt;
  final DateTime? lastSeenAsClientAt;
  final DateTime firstPairedAt;
  const DevicePair({
    required this.deviceUuid,
    required this.deviceName,
    this.lastSeenAsHostAt,
    this.lastSeenAsClientAt,
    required this.firstPairedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_uuid'] = Variable<String>(deviceUuid);
    map['device_name'] = Variable<String>(deviceName);
    if (!nullToAbsent || lastSeenAsHostAt != null) {
      map['last_seen_as_host_at'] = Variable<DateTime>(lastSeenAsHostAt);
    }
    if (!nullToAbsent || lastSeenAsClientAt != null) {
      map['last_seen_as_client_at'] = Variable<DateTime>(lastSeenAsClientAt);
    }
    map['first_paired_at'] = Variable<DateTime>(firstPairedAt);
    return map;
  }

  DevicePairsCompanion toCompanion(bool nullToAbsent) {
    return DevicePairsCompanion(
      deviceUuid: Value(deviceUuid),
      deviceName: Value(deviceName),
      lastSeenAsHostAt: lastSeenAsHostAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAsHostAt),
      lastSeenAsClientAt: lastSeenAsClientAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAsClientAt),
      firstPairedAt: Value(firstPairedAt),
    );
  }

  factory DevicePair.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DevicePair(
      deviceUuid: serializer.fromJson<String>(json['deviceUuid']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      lastSeenAsHostAt: serializer.fromJson<DateTime?>(
        json['lastSeenAsHostAt'],
      ),
      lastSeenAsClientAt: serializer.fromJson<DateTime?>(
        json['lastSeenAsClientAt'],
      ),
      firstPairedAt: serializer.fromJson<DateTime>(json['firstPairedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceUuid': serializer.toJson<String>(deviceUuid),
      'deviceName': serializer.toJson<String>(deviceName),
      'lastSeenAsHostAt': serializer.toJson<DateTime?>(lastSeenAsHostAt),
      'lastSeenAsClientAt': serializer.toJson<DateTime?>(lastSeenAsClientAt),
      'firstPairedAt': serializer.toJson<DateTime>(firstPairedAt),
    };
  }

  DevicePair copyWith({
    String? deviceUuid,
    String? deviceName,
    Value<DateTime?> lastSeenAsHostAt = const Value.absent(),
    Value<DateTime?> lastSeenAsClientAt = const Value.absent(),
    DateTime? firstPairedAt,
  }) => DevicePair(
    deviceUuid: deviceUuid ?? this.deviceUuid,
    deviceName: deviceName ?? this.deviceName,
    lastSeenAsHostAt: lastSeenAsHostAt.present
        ? lastSeenAsHostAt.value
        : this.lastSeenAsHostAt,
    lastSeenAsClientAt: lastSeenAsClientAt.present
        ? lastSeenAsClientAt.value
        : this.lastSeenAsClientAt,
    firstPairedAt: firstPairedAt ?? this.firstPairedAt,
  );
  DevicePair copyWithCompanion(DevicePairsCompanion data) {
    return DevicePair(
      deviceUuid: data.deviceUuid.present
          ? data.deviceUuid.value
          : this.deviceUuid,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      lastSeenAsHostAt: data.lastSeenAsHostAt.present
          ? data.lastSeenAsHostAt.value
          : this.lastSeenAsHostAt,
      lastSeenAsClientAt: data.lastSeenAsClientAt.present
          ? data.lastSeenAsClientAt.value
          : this.lastSeenAsClientAt,
      firstPairedAt: data.firstPairedAt.present
          ? data.firstPairedAt.value
          : this.firstPairedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DevicePair(')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('deviceName: $deviceName, ')
          ..write('lastSeenAsHostAt: $lastSeenAsHostAt, ')
          ..write('lastSeenAsClientAt: $lastSeenAsClientAt, ')
          ..write('firstPairedAt: $firstPairedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceUuid,
    deviceName,
    lastSeenAsHostAt,
    lastSeenAsClientAt,
    firstPairedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DevicePair &&
          other.deviceUuid == this.deviceUuid &&
          other.deviceName == this.deviceName &&
          other.lastSeenAsHostAt == this.lastSeenAsHostAt &&
          other.lastSeenAsClientAt == this.lastSeenAsClientAt &&
          other.firstPairedAt == this.firstPairedAt);
}

class DevicePairsCompanion extends UpdateCompanion<DevicePair> {
  final Value<String> deviceUuid;
  final Value<String> deviceName;
  final Value<DateTime?> lastSeenAsHostAt;
  final Value<DateTime?> lastSeenAsClientAt;
  final Value<DateTime> firstPairedAt;
  final Value<int> rowid;
  const DevicePairsCompanion({
    this.deviceUuid = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.lastSeenAsHostAt = const Value.absent(),
    this.lastSeenAsClientAt = const Value.absent(),
    this.firstPairedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicePairsCompanion.insert({
    required String deviceUuid,
    required String deviceName,
    this.lastSeenAsHostAt = const Value.absent(),
    this.lastSeenAsClientAt = const Value.absent(),
    this.firstPairedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceUuid = Value(deviceUuid),
       deviceName = Value(deviceName);
  static Insertable<DevicePair> custom({
    Expression<String>? deviceUuid,
    Expression<String>? deviceName,
    Expression<DateTime>? lastSeenAsHostAt,
    Expression<DateTime>? lastSeenAsClientAt,
    Expression<DateTime>? firstPairedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceUuid != null) 'device_uuid': deviceUuid,
      if (deviceName != null) 'device_name': deviceName,
      if (lastSeenAsHostAt != null) 'last_seen_as_host_at': lastSeenAsHostAt,
      if (lastSeenAsClientAt != null)
        'last_seen_as_client_at': lastSeenAsClientAt,
      if (firstPairedAt != null) 'first_paired_at': firstPairedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicePairsCompanion copyWith({
    Value<String>? deviceUuid,
    Value<String>? deviceName,
    Value<DateTime?>? lastSeenAsHostAt,
    Value<DateTime?>? lastSeenAsClientAt,
    Value<DateTime>? firstPairedAt,
    Value<int>? rowid,
  }) {
    return DevicePairsCompanion(
      deviceUuid: deviceUuid ?? this.deviceUuid,
      deviceName: deviceName ?? this.deviceName,
      lastSeenAsHostAt: lastSeenAsHostAt ?? this.lastSeenAsHostAt,
      lastSeenAsClientAt: lastSeenAsClientAt ?? this.lastSeenAsClientAt,
      firstPairedAt: firstPairedAt ?? this.firstPairedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceUuid.present) {
      map['device_uuid'] = Variable<String>(deviceUuid.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (lastSeenAsHostAt.present) {
      map['last_seen_as_host_at'] = Variable<DateTime>(lastSeenAsHostAt.value);
    }
    if (lastSeenAsClientAt.present) {
      map['last_seen_as_client_at'] = Variable<DateTime>(
        lastSeenAsClientAt.value,
      );
    }
    if (firstPairedAt.present) {
      map['first_paired_at'] = Variable<DateTime>(firstPairedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicePairsCompanion(')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('deviceName: $deviceName, ')
          ..write('lastSeenAsHostAt: $lastSeenAsHostAt, ')
          ..write('lastSeenAsClientAt: $lastSeenAsClientAt, ')
          ..write('firstPairedAt: $firstPairedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $DevicePairsTable devicePairs = $DevicePairsTable(this);
  late final NotesDao notesDao = NotesDao(this as LocalDatabase);
  late final DevicePairsDao devicePairsDao = DevicePairsDao(
    this as LocalDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [notes, devicePairs];
}

typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<String> uuid,
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
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> cloudSyncStatus,
      Value<int> localSyncStatus,
      Value<int> versionCounter,
      Value<String?> creationPlatform,
      Value<String?> creationDevice,
      Value<String?> lastEditedPlatform,
      Value<String?> lastEditedDevice,
      Value<String?> deletedPlatform,
      Value<String?> deletedDevice,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> uuid,
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
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> cloudSyncStatus,
      Value<int> localSyncStatus,
      Value<int> versionCounter,
      Value<String?> creationPlatform,
      Value<String?> creationDevice,
      Value<String?> lastEditedPlatform,
      Value<String?> lastEditedDevice,
      Value<String?> deletedPlatform,
      Value<String?> deletedDevice,
      Value<int> rowid,
    });

class $$NotesTableFilterComposer
    extends Composer<_$LocalDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
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

  ColumnFilters<int> get cloudSyncStatus => $composableBuilder(
    column: $table.cloudSyncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localSyncStatus => $composableBuilder(
    column: $table.localSyncStatus,
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

  ColumnFilters<String> get lastEditedPlatform => $composableBuilder(
    column: $table.lastEditedPlatform,
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

  ColumnFilters<String> get deletedDevice => $composableBuilder(
    column: $table.deletedDevice,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$LocalDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
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

  ColumnOrderings<int> get cloudSyncStatus => $composableBuilder(
    column: $table.cloudSyncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localSyncStatus => $composableBuilder(
    column: $table.localSyncStatus,
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

  ColumnOrderings<String> get lastEditedPlatform => $composableBuilder(
    column: $table.lastEditedPlatform,
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

  ColumnOrderings<String> get deletedDevice => $composableBuilder(
    column: $table.deletedDevice,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

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

  GeneratedColumn<int> get cloudSyncStatus => $composableBuilder(
    column: $table.cloudSyncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localSyncStatus => $composableBuilder(
    column: $table.localSyncStatus,
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

  GeneratedColumn<String> get lastEditedPlatform => $composableBuilder(
    column: $table.lastEditedPlatform,
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

  GeneratedColumn<String> get deletedDevice => $composableBuilder(
    column: $table.deletedDevice,
    builder: (column) => column,
  );
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$LocalDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$LocalDatabase db, $NotesTable table)
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
                Value<String> uuid = const Value.absent(),
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
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> cloudSyncStatus = const Value.absent(),
                Value<int> localSyncStatus = const Value.absent(),
                Value<int> versionCounter = const Value.absent(),
                Value<String?> creationPlatform = const Value.absent(),
                Value<String?> creationDevice = const Value.absent(),
                Value<String?> lastEditedPlatform = const Value.absent(),
                Value<String?> lastEditedDevice = const Value.absent(),
                Value<String?> deletedPlatform = const Value.absent(),
                Value<String?> deletedDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                uuid: uuid,
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
                cloudSyncStatus: cloudSyncStatus,
                localSyncStatus: localSyncStatus,
                versionCounter: versionCounter,
                creationPlatform: creationPlatform,
                creationDevice: creationDevice,
                lastEditedPlatform: lastEditedPlatform,
                lastEditedDevice: lastEditedDevice,
                deletedPlatform: deletedPlatform,
                deletedDevice: deletedDevice,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
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
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> cloudSyncStatus = const Value.absent(),
                Value<int> localSyncStatus = const Value.absent(),
                Value<int> versionCounter = const Value.absent(),
                Value<String?> creationPlatform = const Value.absent(),
                Value<String?> creationDevice = const Value.absent(),
                Value<String?> lastEditedPlatform = const Value.absent(),
                Value<String?> lastEditedDevice = const Value.absent(),
                Value<String?> deletedPlatform = const Value.absent(),
                Value<String?> deletedDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                uuid: uuid,
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
                cloudSyncStatus: cloudSyncStatus,
                localSyncStatus: localSyncStatus,
                versionCounter: versionCounter,
                creationPlatform: creationPlatform,
                creationDevice: creationDevice,
                lastEditedPlatform: lastEditedPlatform,
                lastEditedDevice: lastEditedDevice,
                deletedPlatform: deletedPlatform,
                deletedDevice: deletedDevice,
                rowid: rowid,
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
      _$LocalDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$LocalDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$DevicePairsTableCreateCompanionBuilder =
    DevicePairsCompanion Function({
      required String deviceUuid,
      required String deviceName,
      Value<DateTime?> lastSeenAsHostAt,
      Value<DateTime?> lastSeenAsClientAt,
      Value<DateTime> firstPairedAt,
      Value<int> rowid,
    });
typedef $$DevicePairsTableUpdateCompanionBuilder =
    DevicePairsCompanion Function({
      Value<String> deviceUuid,
      Value<String> deviceName,
      Value<DateTime?> lastSeenAsHostAt,
      Value<DateTime?> lastSeenAsClientAt,
      Value<DateTime> firstPairedAt,
      Value<int> rowid,
    });

class $$DevicePairsTableFilterComposer
    extends Composer<_$LocalDatabase, $DevicePairsTable> {
  $$DevicePairsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAsHostAt => $composableBuilder(
    column: $table.lastSeenAsHostAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAsClientAt => $composableBuilder(
    column: $table.lastSeenAsClientAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstPairedAt => $composableBuilder(
    column: $table.firstPairedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DevicePairsTableOrderingComposer
    extends Composer<_$LocalDatabase, $DevicePairsTable> {
  $$DevicePairsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAsHostAt => $composableBuilder(
    column: $table.lastSeenAsHostAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAsClientAt => $composableBuilder(
    column: $table.lastSeenAsClientAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstPairedAt => $composableBuilder(
    column: $table.firstPairedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DevicePairsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $DevicePairsTable> {
  $$DevicePairsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAsHostAt => $composableBuilder(
    column: $table.lastSeenAsHostAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAsClientAt => $composableBuilder(
    column: $table.lastSeenAsClientAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstPairedAt => $composableBuilder(
    column: $table.firstPairedAt,
    builder: (column) => column,
  );
}

class $$DevicePairsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $DevicePairsTable,
          DevicePair,
          $$DevicePairsTableFilterComposer,
          $$DevicePairsTableOrderingComposer,
          $$DevicePairsTableAnnotationComposer,
          $$DevicePairsTableCreateCompanionBuilder,
          $$DevicePairsTableUpdateCompanionBuilder,
          (
            DevicePair,
            BaseReferences<_$LocalDatabase, $DevicePairsTable, DevicePair>,
          ),
          DevicePair,
          PrefetchHooks Function()
        > {
  $$DevicePairsTableTableManager(_$LocalDatabase db, $DevicePairsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicePairsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicePairsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicePairsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceUuid = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<DateTime?> lastSeenAsHostAt = const Value.absent(),
                Value<DateTime?> lastSeenAsClientAt = const Value.absent(),
                Value<DateTime> firstPairedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicePairsCompanion(
                deviceUuid: deviceUuid,
                deviceName: deviceName,
                lastSeenAsHostAt: lastSeenAsHostAt,
                lastSeenAsClientAt: lastSeenAsClientAt,
                firstPairedAt: firstPairedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceUuid,
                required String deviceName,
                Value<DateTime?> lastSeenAsHostAt = const Value.absent(),
                Value<DateTime?> lastSeenAsClientAt = const Value.absent(),
                Value<DateTime> firstPairedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicePairsCompanion.insert(
                deviceUuid: deviceUuid,
                deviceName: deviceName,
                lastSeenAsHostAt: lastSeenAsHostAt,
                lastSeenAsClientAt: lastSeenAsClientAt,
                firstPairedAt: firstPairedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DevicePairsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $DevicePairsTable,
      DevicePair,
      $$DevicePairsTableFilterComposer,
      $$DevicePairsTableOrderingComposer,
      $$DevicePairsTableAnnotationComposer,
      $$DevicePairsTableCreateCompanionBuilder,
      $$DevicePairsTableUpdateCompanionBuilder,
      (
        DevicePair,
        BaseReferences<_$LocalDatabase, $DevicePairsTable, DevicePair>,
      ),
      DevicePair,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$DevicePairsTableTableManager get devicePairs =>
      $$DevicePairsTableTableManager(_db, _db.devicePairs);
}
