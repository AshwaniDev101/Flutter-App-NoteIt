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

class $SyncedDevicesTable extends SyncedDevices
    with TableInfo<$SyncedDevicesTable, SyncedDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedDevicesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _lastKnownIpMeta = const VerificationMeta(
    'lastKnownIp',
  );
  @override
  late final GeneratedColumn<String> lastKnownIp = GeneratedColumn<String>(
    'last_known_ip',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastKnownPortMeta = const VerificationMeta(
    'lastKnownPort',
  );
  @override
  late final GeneratedColumn<int> lastKnownPort = GeneratedColumn<int>(
    'last_known_port',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    lastKnownIp,
    lastKnownPort,
    lastSeenAsHostAt,
    lastSeenAsClientAt,
    firstPairedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synced_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncedDevice> instance, {
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
    if (data.containsKey('last_known_ip')) {
      context.handle(
        _lastKnownIpMeta,
        lastKnownIp.isAcceptableOrUnknown(
          data['last_known_ip']!,
          _lastKnownIpMeta,
        ),
      );
    }
    if (data.containsKey('last_known_port')) {
      context.handle(
        _lastKnownPortMeta,
        lastKnownPort.isAcceptableOrUnknown(
          data['last_known_port']!,
          _lastKnownPortMeta,
        ),
      );
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
  SyncedDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedDevice(
      deviceUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_uuid'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      lastKnownIp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_known_ip'],
      ),
      lastKnownPort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_known_port'],
      ),
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
  $SyncedDevicesTable createAlias(String alias) {
    return $SyncedDevicesTable(attachedDatabase, alias);
  }
}

class SyncedDevice extends DataClass implements Insertable<SyncedDevice> {
  final String deviceUuid;
  final String deviceName;
  final String? lastKnownIp;
  final int? lastKnownPort;
  final DateTime? lastSeenAsHostAt;
  final DateTime? lastSeenAsClientAt;
  final DateTime firstPairedAt;
  const SyncedDevice({
    required this.deviceUuid,
    required this.deviceName,
    this.lastKnownIp,
    this.lastKnownPort,
    this.lastSeenAsHostAt,
    this.lastSeenAsClientAt,
    required this.firstPairedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_uuid'] = Variable<String>(deviceUuid);
    map['device_name'] = Variable<String>(deviceName);
    if (!nullToAbsent || lastKnownIp != null) {
      map['last_known_ip'] = Variable<String>(lastKnownIp);
    }
    if (!nullToAbsent || lastKnownPort != null) {
      map['last_known_port'] = Variable<int>(lastKnownPort);
    }
    if (!nullToAbsent || lastSeenAsHostAt != null) {
      map['last_seen_as_host_at'] = Variable<DateTime>(lastSeenAsHostAt);
    }
    if (!nullToAbsent || lastSeenAsClientAt != null) {
      map['last_seen_as_client_at'] = Variable<DateTime>(lastSeenAsClientAt);
    }
    map['first_paired_at'] = Variable<DateTime>(firstPairedAt);
    return map;
  }

  SyncedDevicesCompanion toCompanion(bool nullToAbsent) {
    return SyncedDevicesCompanion(
      deviceUuid: Value(deviceUuid),
      deviceName: Value(deviceName),
      lastKnownIp: lastKnownIp == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownIp),
      lastKnownPort: lastKnownPort == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownPort),
      lastSeenAsHostAt: lastSeenAsHostAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAsHostAt),
      lastSeenAsClientAt: lastSeenAsClientAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAsClientAt),
      firstPairedAt: Value(firstPairedAt),
    );
  }

  factory SyncedDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedDevice(
      deviceUuid: serializer.fromJson<String>(json['deviceUuid']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      lastKnownIp: serializer.fromJson<String?>(json['lastKnownIp']),
      lastKnownPort: serializer.fromJson<int?>(json['lastKnownPort']),
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
      'lastKnownIp': serializer.toJson<String?>(lastKnownIp),
      'lastKnownPort': serializer.toJson<int?>(lastKnownPort),
      'lastSeenAsHostAt': serializer.toJson<DateTime?>(lastSeenAsHostAt),
      'lastSeenAsClientAt': serializer.toJson<DateTime?>(lastSeenAsClientAt),
      'firstPairedAt': serializer.toJson<DateTime>(firstPairedAt),
    };
  }

  SyncedDevice copyWith({
    String? deviceUuid,
    String? deviceName,
    Value<String?> lastKnownIp = const Value.absent(),
    Value<int?> lastKnownPort = const Value.absent(),
    Value<DateTime?> lastSeenAsHostAt = const Value.absent(),
    Value<DateTime?> lastSeenAsClientAt = const Value.absent(),
    DateTime? firstPairedAt,
  }) => SyncedDevice(
    deviceUuid: deviceUuid ?? this.deviceUuid,
    deviceName: deviceName ?? this.deviceName,
    lastKnownIp: lastKnownIp.present ? lastKnownIp.value : this.lastKnownIp,
    lastKnownPort: lastKnownPort.present
        ? lastKnownPort.value
        : this.lastKnownPort,
    lastSeenAsHostAt: lastSeenAsHostAt.present
        ? lastSeenAsHostAt.value
        : this.lastSeenAsHostAt,
    lastSeenAsClientAt: lastSeenAsClientAt.present
        ? lastSeenAsClientAt.value
        : this.lastSeenAsClientAt,
    firstPairedAt: firstPairedAt ?? this.firstPairedAt,
  );
  SyncedDevice copyWithCompanion(SyncedDevicesCompanion data) {
    return SyncedDevice(
      deviceUuid: data.deviceUuid.present
          ? data.deviceUuid.value
          : this.deviceUuid,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      lastKnownIp: data.lastKnownIp.present
          ? data.lastKnownIp.value
          : this.lastKnownIp,
      lastKnownPort: data.lastKnownPort.present
          ? data.lastKnownPort.value
          : this.lastKnownPort,
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
    return (StringBuffer('SyncedDevice(')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('deviceName: $deviceName, ')
          ..write('lastKnownIp: $lastKnownIp, ')
          ..write('lastKnownPort: $lastKnownPort, ')
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
    lastKnownIp,
    lastKnownPort,
    lastSeenAsHostAt,
    lastSeenAsClientAt,
    firstPairedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedDevice &&
          other.deviceUuid == this.deviceUuid &&
          other.deviceName == this.deviceName &&
          other.lastKnownIp == this.lastKnownIp &&
          other.lastKnownPort == this.lastKnownPort &&
          other.lastSeenAsHostAt == this.lastSeenAsHostAt &&
          other.lastSeenAsClientAt == this.lastSeenAsClientAt &&
          other.firstPairedAt == this.firstPairedAt);
}

class SyncedDevicesCompanion extends UpdateCompanion<SyncedDevice> {
  final Value<String> deviceUuid;
  final Value<String> deviceName;
  final Value<String?> lastKnownIp;
  final Value<int?> lastKnownPort;
  final Value<DateTime?> lastSeenAsHostAt;
  final Value<DateTime?> lastSeenAsClientAt;
  final Value<DateTime> firstPairedAt;
  final Value<int> rowid;
  const SyncedDevicesCompanion({
    this.deviceUuid = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.lastKnownIp = const Value.absent(),
    this.lastKnownPort = const Value.absent(),
    this.lastSeenAsHostAt = const Value.absent(),
    this.lastSeenAsClientAt = const Value.absent(),
    this.firstPairedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedDevicesCompanion.insert({
    required String deviceUuid,
    required String deviceName,
    this.lastKnownIp = const Value.absent(),
    this.lastKnownPort = const Value.absent(),
    this.lastSeenAsHostAt = const Value.absent(),
    this.lastSeenAsClientAt = const Value.absent(),
    this.firstPairedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceUuid = Value(deviceUuid),
       deviceName = Value(deviceName);
  static Insertable<SyncedDevice> custom({
    Expression<String>? deviceUuid,
    Expression<String>? deviceName,
    Expression<String>? lastKnownIp,
    Expression<int>? lastKnownPort,
    Expression<DateTime>? lastSeenAsHostAt,
    Expression<DateTime>? lastSeenAsClientAt,
    Expression<DateTime>? firstPairedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceUuid != null) 'device_uuid': deviceUuid,
      if (deviceName != null) 'device_name': deviceName,
      if (lastKnownIp != null) 'last_known_ip': lastKnownIp,
      if (lastKnownPort != null) 'last_known_port': lastKnownPort,
      if (lastSeenAsHostAt != null) 'last_seen_as_host_at': lastSeenAsHostAt,
      if (lastSeenAsClientAt != null)
        'last_seen_as_client_at': lastSeenAsClientAt,
      if (firstPairedAt != null) 'first_paired_at': firstPairedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedDevicesCompanion copyWith({
    Value<String>? deviceUuid,
    Value<String>? deviceName,
    Value<String?>? lastKnownIp,
    Value<int?>? lastKnownPort,
    Value<DateTime?>? lastSeenAsHostAt,
    Value<DateTime?>? lastSeenAsClientAt,
    Value<DateTime>? firstPairedAt,
    Value<int>? rowid,
  }) {
    return SyncedDevicesCompanion(
      deviceUuid: deviceUuid ?? this.deviceUuid,
      deviceName: deviceName ?? this.deviceName,
      lastKnownIp: lastKnownIp ?? this.lastKnownIp,
      lastKnownPort: lastKnownPort ?? this.lastKnownPort,
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
    if (lastKnownIp.present) {
      map['last_known_ip'] = Variable<String>(lastKnownIp.value);
    }
    if (lastKnownPort.present) {
      map['last_known_port'] = Variable<int>(lastKnownPort.value);
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
    return (StringBuffer('SyncedDevicesCompanion(')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('deviceName: $deviceName, ')
          ..write('lastKnownIp: $lastKnownIp, ')
          ..write('lastKnownPort: $lastKnownPort, ')
          ..write('lastSeenAsHostAt: $lastSeenAsHostAt, ')
          ..write('lastSeenAsClientAt: $lastSeenAsClientAt, ')
          ..write('firstPairedAt: $firstPairedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppKeybindingsTable extends AppKeybindings
    with TableInfo<$AppKeybindingsTable, AppKeybinding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppKeybindingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actionNameMeta = const VerificationMeta(
    'actionName',
  );
  @override
  late final GeneratedColumn<String> actionName = GeneratedColumn<String>(
    'action_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyLabelMeta = const VerificationMeta(
    'keyLabel',
  );
  @override
  late final GeneratedColumn<String> keyLabel = GeneratedColumn<String>(
    'key_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<int> keyId = GeneratedColumn<int>(
    'key_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useCtrlMeta = const VerificationMeta(
    'useCtrl',
  );
  @override
  late final GeneratedColumn<bool> useCtrl = GeneratedColumn<bool>(
    'use_ctrl',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_ctrl" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _useAltMeta = const VerificationMeta('useAlt');
  @override
  late final GeneratedColumn<bool> useAlt = GeneratedColumn<bool>(
    'use_alt',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_alt" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _useShiftMeta = const VerificationMeta(
    'useShift',
  );
  @override
  late final GeneratedColumn<bool> useShift = GeneratedColumn<bool>(
    'use_shift',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_shift" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _useMetaMeta = const VerificationMeta(
    'useMeta',
  );
  @override
  late final GeneratedColumn<bool> useMeta = GeneratedColumn<bool>(
    'use_meta',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_meta" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('General'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    actionName,
    keyLabel,
    keyId,
    useCtrl,
    useAlt,
    useShift,
    useMeta,
    isEnabled,
    category,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_keybindings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppKeybinding> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('action_name')) {
      context.handle(
        _actionNameMeta,
        actionName.isAcceptableOrUnknown(data['action_name']!, _actionNameMeta),
      );
    } else if (isInserting) {
      context.missing(_actionNameMeta);
    }
    if (data.containsKey('key_label')) {
      context.handle(
        _keyLabelMeta,
        keyLabel.isAcceptableOrUnknown(data['key_label']!, _keyLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_keyLabelMeta);
    }
    if (data.containsKey('key_id')) {
      context.handle(
        _keyIdMeta,
        keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_keyIdMeta);
    }
    if (data.containsKey('use_ctrl')) {
      context.handle(
        _useCtrlMeta,
        useCtrl.isAcceptableOrUnknown(data['use_ctrl']!, _useCtrlMeta),
      );
    }
    if (data.containsKey('use_alt')) {
      context.handle(
        _useAltMeta,
        useAlt.isAcceptableOrUnknown(data['use_alt']!, _useAltMeta),
      );
    }
    if (data.containsKey('use_shift')) {
      context.handle(
        _useShiftMeta,
        useShift.isAcceptableOrUnknown(data['use_shift']!, _useShiftMeta),
      );
    }
    if (data.containsKey('use_meta')) {
      context.handle(
        _useMetaMeta,
        useMeta.isAcceptableOrUnknown(data['use_meta']!, _useMetaMeta),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actionName};
  @override
  AppKeybinding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppKeybinding(
      actionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_name'],
      )!,
      keyLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_label'],
      )!,
      keyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}key_id'],
      )!,
      useCtrl: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_ctrl'],
      )!,
      useAlt: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_alt'],
      )!,
      useShift: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_shift'],
      )!,
      useMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_meta'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
    );
  }

  @override
  $AppKeybindingsTable createAlias(String alias) {
    return $AppKeybindingsTable(attachedDatabase, alias);
  }
}

class AppKeybinding extends DataClass implements Insertable<AppKeybinding> {
  final String actionName;
  final String keyLabel;
  final int keyId;
  final bool useCtrl;
  final bool useAlt;
  final bool useShift;
  final bool useMeta;
  final bool isEnabled;
  final String category;
  const AppKeybinding({
    required this.actionName,
    required this.keyLabel,
    required this.keyId,
    required this.useCtrl,
    required this.useAlt,
    required this.useShift,
    required this.useMeta,
    required this.isEnabled,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['action_name'] = Variable<String>(actionName);
    map['key_label'] = Variable<String>(keyLabel);
    map['key_id'] = Variable<int>(keyId);
    map['use_ctrl'] = Variable<bool>(useCtrl);
    map['use_alt'] = Variable<bool>(useAlt);
    map['use_shift'] = Variable<bool>(useShift);
    map['use_meta'] = Variable<bool>(useMeta);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['category'] = Variable<String>(category);
    return map;
  }

  AppKeybindingsCompanion toCompanion(bool nullToAbsent) {
    return AppKeybindingsCompanion(
      actionName: Value(actionName),
      keyLabel: Value(keyLabel),
      keyId: Value(keyId),
      useCtrl: Value(useCtrl),
      useAlt: Value(useAlt),
      useShift: Value(useShift),
      useMeta: Value(useMeta),
      isEnabled: Value(isEnabled),
      category: Value(category),
    );
  }

  factory AppKeybinding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppKeybinding(
      actionName: serializer.fromJson<String>(json['actionName']),
      keyLabel: serializer.fromJson<String>(json['keyLabel']),
      keyId: serializer.fromJson<int>(json['keyId']),
      useCtrl: serializer.fromJson<bool>(json['useCtrl']),
      useAlt: serializer.fromJson<bool>(json['useAlt']),
      useShift: serializer.fromJson<bool>(json['useShift']),
      useMeta: serializer.fromJson<bool>(json['useMeta']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      category: serializer.fromJson<String>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actionName': serializer.toJson<String>(actionName),
      'keyLabel': serializer.toJson<String>(keyLabel),
      'keyId': serializer.toJson<int>(keyId),
      'useCtrl': serializer.toJson<bool>(useCtrl),
      'useAlt': serializer.toJson<bool>(useAlt),
      'useShift': serializer.toJson<bool>(useShift),
      'useMeta': serializer.toJson<bool>(useMeta),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'category': serializer.toJson<String>(category),
    };
  }

  AppKeybinding copyWith({
    String? actionName,
    String? keyLabel,
    int? keyId,
    bool? useCtrl,
    bool? useAlt,
    bool? useShift,
    bool? useMeta,
    bool? isEnabled,
    String? category,
  }) => AppKeybinding(
    actionName: actionName ?? this.actionName,
    keyLabel: keyLabel ?? this.keyLabel,
    keyId: keyId ?? this.keyId,
    useCtrl: useCtrl ?? this.useCtrl,
    useAlt: useAlt ?? this.useAlt,
    useShift: useShift ?? this.useShift,
    useMeta: useMeta ?? this.useMeta,
    isEnabled: isEnabled ?? this.isEnabled,
    category: category ?? this.category,
  );
  AppKeybinding copyWithCompanion(AppKeybindingsCompanion data) {
    return AppKeybinding(
      actionName: data.actionName.present
          ? data.actionName.value
          : this.actionName,
      keyLabel: data.keyLabel.present ? data.keyLabel.value : this.keyLabel,
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      useCtrl: data.useCtrl.present ? data.useCtrl.value : this.useCtrl,
      useAlt: data.useAlt.present ? data.useAlt.value : this.useAlt,
      useShift: data.useShift.present ? data.useShift.value : this.useShift,
      useMeta: data.useMeta.present ? data.useMeta.value : this.useMeta,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppKeybinding(')
          ..write('actionName: $actionName, ')
          ..write('keyLabel: $keyLabel, ')
          ..write('keyId: $keyId, ')
          ..write('useCtrl: $useCtrl, ')
          ..write('useAlt: $useAlt, ')
          ..write('useShift: $useShift, ')
          ..write('useMeta: $useMeta, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    actionName,
    keyLabel,
    keyId,
    useCtrl,
    useAlt,
    useShift,
    useMeta,
    isEnabled,
    category,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppKeybinding &&
          other.actionName == this.actionName &&
          other.keyLabel == this.keyLabel &&
          other.keyId == this.keyId &&
          other.useCtrl == this.useCtrl &&
          other.useAlt == this.useAlt &&
          other.useShift == this.useShift &&
          other.useMeta == this.useMeta &&
          other.isEnabled == this.isEnabled &&
          other.category == this.category);
}

class AppKeybindingsCompanion extends UpdateCompanion<AppKeybinding> {
  final Value<String> actionName;
  final Value<String> keyLabel;
  final Value<int> keyId;
  final Value<bool> useCtrl;
  final Value<bool> useAlt;
  final Value<bool> useShift;
  final Value<bool> useMeta;
  final Value<bool> isEnabled;
  final Value<String> category;
  final Value<int> rowid;
  const AppKeybindingsCompanion({
    this.actionName = const Value.absent(),
    this.keyLabel = const Value.absent(),
    this.keyId = const Value.absent(),
    this.useCtrl = const Value.absent(),
    this.useAlt = const Value.absent(),
    this.useShift = const Value.absent(),
    this.useMeta = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppKeybindingsCompanion.insert({
    required String actionName,
    required String keyLabel,
    required int keyId,
    this.useCtrl = const Value.absent(),
    this.useAlt = const Value.absent(),
    this.useShift = const Value.absent(),
    this.useMeta = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : actionName = Value(actionName),
       keyLabel = Value(keyLabel),
       keyId = Value(keyId);
  static Insertable<AppKeybinding> custom({
    Expression<String>? actionName,
    Expression<String>? keyLabel,
    Expression<int>? keyId,
    Expression<bool>? useCtrl,
    Expression<bool>? useAlt,
    Expression<bool>? useShift,
    Expression<bool>? useMeta,
    Expression<bool>? isEnabled,
    Expression<String>? category,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actionName != null) 'action_name': actionName,
      if (keyLabel != null) 'key_label': keyLabel,
      if (keyId != null) 'key_id': keyId,
      if (useCtrl != null) 'use_ctrl': useCtrl,
      if (useAlt != null) 'use_alt': useAlt,
      if (useShift != null) 'use_shift': useShift,
      if (useMeta != null) 'use_meta': useMeta,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (category != null) 'category': category,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppKeybindingsCompanion copyWith({
    Value<String>? actionName,
    Value<String>? keyLabel,
    Value<int>? keyId,
    Value<bool>? useCtrl,
    Value<bool>? useAlt,
    Value<bool>? useShift,
    Value<bool>? useMeta,
    Value<bool>? isEnabled,
    Value<String>? category,
    Value<int>? rowid,
  }) {
    return AppKeybindingsCompanion(
      actionName: actionName ?? this.actionName,
      keyLabel: keyLabel ?? this.keyLabel,
      keyId: keyId ?? this.keyId,
      useCtrl: useCtrl ?? this.useCtrl,
      useAlt: useAlt ?? this.useAlt,
      useShift: useShift ?? this.useShift,
      useMeta: useMeta ?? this.useMeta,
      isEnabled: isEnabled ?? this.isEnabled,
      category: category ?? this.category,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actionName.present) {
      map['action_name'] = Variable<String>(actionName.value);
    }
    if (keyLabel.present) {
      map['key_label'] = Variable<String>(keyLabel.value);
    }
    if (keyId.present) {
      map['key_id'] = Variable<int>(keyId.value);
    }
    if (useCtrl.present) {
      map['use_ctrl'] = Variable<bool>(useCtrl.value);
    }
    if (useAlt.present) {
      map['use_alt'] = Variable<bool>(useAlt.value);
    }
    if (useShift.present) {
      map['use_shift'] = Variable<bool>(useShift.value);
    }
    if (useMeta.present) {
      map['use_meta'] = Variable<bool>(useMeta.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppKeybindingsCompanion(')
          ..write('actionName: $actionName, ')
          ..write('keyLabel: $keyLabel, ')
          ..write('keyId: $keyId, ')
          ..write('useCtrl: $useCtrl, ')
          ..write('useAlt: $useAlt, ')
          ..write('useShift: $useShift, ')
          ..write('useMeta: $useMeta, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('category: $category, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $SyncedDevicesTable syncedDevices = $SyncedDevicesTable(this);
  late final $AppKeybindingsTable appKeybindings = $AppKeybindingsTable(this);
  late final NotesDao notesDao = NotesDao(this as LocalDatabase);
  late final SyncedDevicesDao syncedDevicesDao = SyncedDevicesDao(
    this as LocalDatabase,
  );
  late final KeybindingsDao keybindingsDao = KeybindingsDao(
    this as LocalDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notes,
    syncedDevices,
    appKeybindings,
  ];
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
typedef $$SyncedDevicesTableCreateCompanionBuilder =
    SyncedDevicesCompanion Function({
      required String deviceUuid,
      required String deviceName,
      Value<String?> lastKnownIp,
      Value<int?> lastKnownPort,
      Value<DateTime?> lastSeenAsHostAt,
      Value<DateTime?> lastSeenAsClientAt,
      Value<DateTime> firstPairedAt,
      Value<int> rowid,
    });
typedef $$SyncedDevicesTableUpdateCompanionBuilder =
    SyncedDevicesCompanion Function({
      Value<String> deviceUuid,
      Value<String> deviceName,
      Value<String?> lastKnownIp,
      Value<int?> lastKnownPort,
      Value<DateTime?> lastSeenAsHostAt,
      Value<DateTime?> lastSeenAsClientAt,
      Value<DateTime> firstPairedAt,
      Value<int> rowid,
    });

class $$SyncedDevicesTableFilterComposer
    extends Composer<_$LocalDatabase, $SyncedDevicesTable> {
  $$SyncedDevicesTableFilterComposer({
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

  ColumnFilters<String> get lastKnownIp => $composableBuilder(
    column: $table.lastKnownIp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastKnownPort => $composableBuilder(
    column: $table.lastKnownPort,
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

class $$SyncedDevicesTableOrderingComposer
    extends Composer<_$LocalDatabase, $SyncedDevicesTable> {
  $$SyncedDevicesTableOrderingComposer({
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

  ColumnOrderings<String> get lastKnownIp => $composableBuilder(
    column: $table.lastKnownIp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastKnownPort => $composableBuilder(
    column: $table.lastKnownPort,
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

class $$SyncedDevicesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $SyncedDevicesTable> {
  $$SyncedDevicesTableAnnotationComposer({
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

  GeneratedColumn<String> get lastKnownIp => $composableBuilder(
    column: $table.lastKnownIp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastKnownPort => $composableBuilder(
    column: $table.lastKnownPort,
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

class $$SyncedDevicesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $SyncedDevicesTable,
          SyncedDevice,
          $$SyncedDevicesTableFilterComposer,
          $$SyncedDevicesTableOrderingComposer,
          $$SyncedDevicesTableAnnotationComposer,
          $$SyncedDevicesTableCreateCompanionBuilder,
          $$SyncedDevicesTableUpdateCompanionBuilder,
          (
            SyncedDevice,
            BaseReferences<_$LocalDatabase, $SyncedDevicesTable, SyncedDevice>,
          ),
          SyncedDevice,
          PrefetchHooks Function()
        > {
  $$SyncedDevicesTableTableManager(
    _$LocalDatabase db,
    $SyncedDevicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncedDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncedDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncedDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceUuid = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String?> lastKnownIp = const Value.absent(),
                Value<int?> lastKnownPort = const Value.absent(),
                Value<DateTime?> lastSeenAsHostAt = const Value.absent(),
                Value<DateTime?> lastSeenAsClientAt = const Value.absent(),
                Value<DateTime> firstPairedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedDevicesCompanion(
                deviceUuid: deviceUuid,
                deviceName: deviceName,
                lastKnownIp: lastKnownIp,
                lastKnownPort: lastKnownPort,
                lastSeenAsHostAt: lastSeenAsHostAt,
                lastSeenAsClientAt: lastSeenAsClientAt,
                firstPairedAt: firstPairedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceUuid,
                required String deviceName,
                Value<String?> lastKnownIp = const Value.absent(),
                Value<int?> lastKnownPort = const Value.absent(),
                Value<DateTime?> lastSeenAsHostAt = const Value.absent(),
                Value<DateTime?> lastSeenAsClientAt = const Value.absent(),
                Value<DateTime> firstPairedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedDevicesCompanion.insert(
                deviceUuid: deviceUuid,
                deviceName: deviceName,
                lastKnownIp: lastKnownIp,
                lastKnownPort: lastKnownPort,
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

typedef $$SyncedDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $SyncedDevicesTable,
      SyncedDevice,
      $$SyncedDevicesTableFilterComposer,
      $$SyncedDevicesTableOrderingComposer,
      $$SyncedDevicesTableAnnotationComposer,
      $$SyncedDevicesTableCreateCompanionBuilder,
      $$SyncedDevicesTableUpdateCompanionBuilder,
      (
        SyncedDevice,
        BaseReferences<_$LocalDatabase, $SyncedDevicesTable, SyncedDevice>,
      ),
      SyncedDevice,
      PrefetchHooks Function()
    >;
typedef $$AppKeybindingsTableCreateCompanionBuilder =
    AppKeybindingsCompanion Function({
      required String actionName,
      required String keyLabel,
      required int keyId,
      Value<bool> useCtrl,
      Value<bool> useAlt,
      Value<bool> useShift,
      Value<bool> useMeta,
      Value<bool> isEnabled,
      Value<String> category,
      Value<int> rowid,
    });
typedef $$AppKeybindingsTableUpdateCompanionBuilder =
    AppKeybindingsCompanion Function({
      Value<String> actionName,
      Value<String> keyLabel,
      Value<int> keyId,
      Value<bool> useCtrl,
      Value<bool> useAlt,
      Value<bool> useShift,
      Value<bool> useMeta,
      Value<bool> isEnabled,
      Value<String> category,
      Value<int> rowid,
    });

class $$AppKeybindingsTableFilterComposer
    extends Composer<_$LocalDatabase, $AppKeybindingsTable> {
  $$AppKeybindingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actionName => $composableBuilder(
    column: $table.actionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyLabel => $composableBuilder(
    column: $table.keyLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get keyId => $composableBuilder(
    column: $table.keyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useCtrl => $composableBuilder(
    column: $table.useCtrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useAlt => $composableBuilder(
    column: $table.useAlt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useShift => $composableBuilder(
    column: $table.useShift,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useMeta => $composableBuilder(
    column: $table.useMeta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppKeybindingsTableOrderingComposer
    extends Composer<_$LocalDatabase, $AppKeybindingsTable> {
  $$AppKeybindingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actionName => $composableBuilder(
    column: $table.actionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyLabel => $composableBuilder(
    column: $table.keyLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keyId => $composableBuilder(
    column: $table.keyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useCtrl => $composableBuilder(
    column: $table.useCtrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useAlt => $composableBuilder(
    column: $table.useAlt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useShift => $composableBuilder(
    column: $table.useShift,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useMeta => $composableBuilder(
    column: $table.useMeta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppKeybindingsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $AppKeybindingsTable> {
  $$AppKeybindingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actionName => $composableBuilder(
    column: $table.actionName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keyLabel =>
      $composableBuilder(column: $table.keyLabel, builder: (column) => column);

  GeneratedColumn<int> get keyId =>
      $composableBuilder(column: $table.keyId, builder: (column) => column);

  GeneratedColumn<bool> get useCtrl =>
      $composableBuilder(column: $table.useCtrl, builder: (column) => column);

  GeneratedColumn<bool> get useAlt =>
      $composableBuilder(column: $table.useAlt, builder: (column) => column);

  GeneratedColumn<bool> get useShift =>
      $composableBuilder(column: $table.useShift, builder: (column) => column);

  GeneratedColumn<bool> get useMeta =>
      $composableBuilder(column: $table.useMeta, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);
}

class $$AppKeybindingsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $AppKeybindingsTable,
          AppKeybinding,
          $$AppKeybindingsTableFilterComposer,
          $$AppKeybindingsTableOrderingComposer,
          $$AppKeybindingsTableAnnotationComposer,
          $$AppKeybindingsTableCreateCompanionBuilder,
          $$AppKeybindingsTableUpdateCompanionBuilder,
          (
            AppKeybinding,
            BaseReferences<
              _$LocalDatabase,
              $AppKeybindingsTable,
              AppKeybinding
            >,
          ),
          AppKeybinding,
          PrefetchHooks Function()
        > {
  $$AppKeybindingsTableTableManager(
    _$LocalDatabase db,
    $AppKeybindingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppKeybindingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppKeybindingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppKeybindingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> actionName = const Value.absent(),
                Value<String> keyLabel = const Value.absent(),
                Value<int> keyId = const Value.absent(),
                Value<bool> useCtrl = const Value.absent(),
                Value<bool> useAlt = const Value.absent(),
                Value<bool> useShift = const Value.absent(),
                Value<bool> useMeta = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppKeybindingsCompanion(
                actionName: actionName,
                keyLabel: keyLabel,
                keyId: keyId,
                useCtrl: useCtrl,
                useAlt: useAlt,
                useShift: useShift,
                useMeta: useMeta,
                isEnabled: isEnabled,
                category: category,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String actionName,
                required String keyLabel,
                required int keyId,
                Value<bool> useCtrl = const Value.absent(),
                Value<bool> useAlt = const Value.absent(),
                Value<bool> useShift = const Value.absent(),
                Value<bool> useMeta = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppKeybindingsCompanion.insert(
                actionName: actionName,
                keyLabel: keyLabel,
                keyId: keyId,
                useCtrl: useCtrl,
                useAlt: useAlt,
                useShift: useShift,
                useMeta: useMeta,
                isEnabled: isEnabled,
                category: category,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppKeybindingsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $AppKeybindingsTable,
      AppKeybinding,
      $$AppKeybindingsTableFilterComposer,
      $$AppKeybindingsTableOrderingComposer,
      $$AppKeybindingsTableAnnotationComposer,
      $$AppKeybindingsTableCreateCompanionBuilder,
      $$AppKeybindingsTableUpdateCompanionBuilder,
      (
        AppKeybinding,
        BaseReferences<_$LocalDatabase, $AppKeybindingsTable, AppKeybinding>,
      ),
      AppKeybinding,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$SyncedDevicesTableTableManager get syncedDevices =>
      $$SyncedDevicesTableTableManager(_db, _db.syncedDevices);
  $$AppKeybindingsTableTableManager get appKeybindings =>
      $$AppKeybindingsTableTableManager(_db, _db.appKeybindings);
}
