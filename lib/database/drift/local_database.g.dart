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
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _contentVersionMeta = const VerificationMeta(
    'contentVersion',
  );
  @override
  late final GeneratedColumn<int> contentVersion = GeneratedColumn<int>(
    'content_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta(
    'pinnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
    'pinned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockedAtMeta = const VerificationMeta(
    'lockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lockedAt = GeneratedColumn<DateTime>(
    'locked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localAttachmentPathMeta =
      const VerificationMeta('localAttachmentPath');
  @override
  late final GeneratedColumn<String> localAttachmentPath =
      GeneratedColumn<String>(
        'local_attachment_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cloudAttachmentUrlMeta =
      const VerificationMeta('cloudAttachmentUrl');
  @override
  late final GeneratedColumn<String> cloudAttachmentUrl =
      GeneratedColumn<String>(
        'cloud_attachment_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
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
  static const VerificationMeta _updateCounterMeta = const VerificationMeta(
    'updateCounter',
  );
  @override
  late final GeneratedColumn<int> updateCounter = GeneratedColumn<int>(
    'update_counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
    schemaVersion,
    contentVersion,
    pinnedAt,
    archivedAt,
    lockedAt,
    localAttachmentPath,
    cloudAttachmentUrl,
    folderId,
    tags,
    reminderAt,
    ownerUid,
    createdAt,
    updatedAt,
    deletedAt,
    updateCounter,
    cloudSyncStatus,
    localSyncStatus,
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
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('content_version')) {
      context.handle(
        _contentVersionMeta,
        contentVersion.isAcceptableOrUnknown(
          data['content_version']!,
          _contentVersionMeta,
        ),
      );
    }
    if (data.containsKey('pinned_at')) {
      context.handle(
        _pinnedAtMeta,
        pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('locked_at')) {
      context.handle(
        _lockedAtMeta,
        lockedAt.isAcceptableOrUnknown(data['locked_at']!, _lockedAtMeta),
      );
    }
    if (data.containsKey('local_attachment_path')) {
      context.handle(
        _localAttachmentPathMeta,
        localAttachmentPath.isAcceptableOrUnknown(
          data['local_attachment_path']!,
          _localAttachmentPathMeta,
        ),
      );
    }
    if (data.containsKey('cloud_attachment_url')) {
      context.handle(
        _cloudAttachmentUrlMeta,
        cloudAttachmentUrl.isAcceptableOrUnknown(
          data['cloud_attachment_url']!,
          _cloudAttachmentUrlMeta,
        ),
      );
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
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
    if (data.containsKey('owner_uid')) {
      context.handle(
        _ownerUidMeta,
        ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta),
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
    if (data.containsKey('update_counter')) {
      context.handle(
        _updateCounterMeta,
        updateCounter.isAcceptableOrUnknown(
          data['update_counter']!,
          _updateCounterMeta,
        ),
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
  Set<GeneratedColumn> get $primaryKey => {uuid};
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
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_version'],
      )!,
      pinnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pinned_at'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      lockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_at'],
      ),
      localAttachmentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_attachment_path'],
      ),
      cloudAttachmentUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_attachment_url'],
      ),
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      reminderAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reminder_at'],
      ),
      ownerUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_uid'],
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
      updateCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_counter'],
      )!,
      cloudSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cloud_sync_status'],
      )!,
      localSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_sync_status'],
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
  final int schemaVersion;
  final int contentVersion;
  final DateTime? pinnedAt;
  final DateTime? archivedAt;
  final DateTime? lockedAt;
  final String? localAttachmentPath;
  final String? cloudAttachmentUrl;
  final String? folderId;
  final String? tags;
  final DateTime? reminderAt;
  final String? ownerUid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int updateCounter;
  final int cloudSyncStatus;
  final int localSyncStatus;
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
    required this.schemaVersion,
    required this.contentVersion,
    this.pinnedAt,
    this.archivedAt,
    this.lockedAt,
    this.localAttachmentPath,
    this.cloudAttachmentUrl,
    this.folderId,
    this.tags,
    this.reminderAt,
    this.ownerUid,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.updateCounter,
    required this.cloudSyncStatus,
    required this.localSyncStatus,
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
    map['schema_version'] = Variable<int>(schemaVersion);
    map['content_version'] = Variable<int>(contentVersion);
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || lockedAt != null) {
      map['locked_at'] = Variable<DateTime>(lockedAt);
    }
    if (!nullToAbsent || localAttachmentPath != null) {
      map['local_attachment_path'] = Variable<String>(localAttachmentPath);
    }
    if (!nullToAbsent || cloudAttachmentUrl != null) {
      map['cloud_attachment_url'] = Variable<String>(cloudAttachmentUrl);
    }
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<DateTime>(reminderAt);
    }
    if (!nullToAbsent || ownerUid != null) {
      map['owner_uid'] = Variable<String>(ownerUid);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['update_counter'] = Variable<int>(updateCounter);
    map['cloud_sync_status'] = Variable<int>(cloudSyncStatus);
    map['local_sync_status'] = Variable<int>(localSyncStatus);
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
      schemaVersion: Value(schemaVersion),
      contentVersion: Value(contentVersion),
      pinnedAt: pinnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      lockedAt: lockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedAt),
      localAttachmentPath: localAttachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localAttachmentPath),
      cloudAttachmentUrl: cloudAttachmentUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudAttachmentUrl),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      ownerUid: ownerUid == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      updateCounter: Value(updateCounter),
      cloudSyncStatus: Value(cloudSyncStatus),
      localSyncStatus: Value(localSyncStatus),
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
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      contentVersion: serializer.fromJson<int>(json['contentVersion']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      lockedAt: serializer.fromJson<DateTime?>(json['lockedAt']),
      localAttachmentPath: serializer.fromJson<String?>(
        json['localAttachmentPath'],
      ),
      cloudAttachmentUrl: serializer.fromJson<String?>(
        json['cloudAttachmentUrl'],
      ),
      folderId: serializer.fromJson<String?>(json['folderId']),
      tags: serializer.fromJson<String?>(json['tags']),
      reminderAt: serializer.fromJson<DateTime?>(json['reminderAt']),
      ownerUid: serializer.fromJson<String?>(json['ownerUid']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      updateCounter: serializer.fromJson<int>(json['updateCounter']),
      cloudSyncStatus: serializer.fromJson<int>(json['cloudSyncStatus']),
      localSyncStatus: serializer.fromJson<int>(json['localSyncStatus']),
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
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'contentVersion': serializer.toJson<int>(contentVersion),
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'lockedAt': serializer.toJson<DateTime?>(lockedAt),
      'localAttachmentPath': serializer.toJson<String?>(localAttachmentPath),
      'cloudAttachmentUrl': serializer.toJson<String?>(cloudAttachmentUrl),
      'folderId': serializer.toJson<String?>(folderId),
      'tags': serializer.toJson<String?>(tags),
      'reminderAt': serializer.toJson<DateTime?>(reminderAt),
      'ownerUid': serializer.toJson<String?>(ownerUid),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'updateCounter': serializer.toJson<int>(updateCounter),
      'cloudSyncStatus': serializer.toJson<int>(cloudSyncStatus),
      'localSyncStatus': serializer.toJson<int>(localSyncStatus),
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
    int? schemaVersion,
    int? contentVersion,
    Value<DateTime?> pinnedAt = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<DateTime?> lockedAt = const Value.absent(),
    Value<String?> localAttachmentPath = const Value.absent(),
    Value<String?> cloudAttachmentUrl = const Value.absent(),
    Value<String?> folderId = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<DateTime?> reminderAt = const Value.absent(),
    Value<String?> ownerUid = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? updateCounter,
    int? cloudSyncStatus,
    int? localSyncStatus,
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
    schemaVersion: schemaVersion ?? this.schemaVersion,
    contentVersion: contentVersion ?? this.contentVersion,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    lockedAt: lockedAt.present ? lockedAt.value : this.lockedAt,
    localAttachmentPath: localAttachmentPath.present
        ? localAttachmentPath.value
        : this.localAttachmentPath,
    cloudAttachmentUrl: cloudAttachmentUrl.present
        ? cloudAttachmentUrl.value
        : this.cloudAttachmentUrl,
    folderId: folderId.present ? folderId.value : this.folderId,
    tags: tags.present ? tags.value : this.tags,
    reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
    ownerUid: ownerUid.present ? ownerUid.value : this.ownerUid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    updateCounter: updateCounter ?? this.updateCounter,
    cloudSyncStatus: cloudSyncStatus ?? this.cloudSyncStatus,
    localSyncStatus: localSyncStatus ?? this.localSyncStatus,
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
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      lockedAt: data.lockedAt.present ? data.lockedAt.value : this.lockedAt,
      localAttachmentPath: data.localAttachmentPath.present
          ? data.localAttachmentPath.value
          : this.localAttachmentPath,
      cloudAttachmentUrl: data.cloudAttachmentUrl.present
          ? data.cloudAttachmentUrl.value
          : this.cloudAttachmentUrl,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      tags: data.tags.present ? data.tags.value : this.tags,
      reminderAt: data.reminderAt.present
          ? data.reminderAt.value
          : this.reminderAt,
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      updateCounter: data.updateCounter.present
          ? data.updateCounter.value
          : this.updateCounter,
      cloudSyncStatus: data.cloudSyncStatus.present
          ? data.cloudSyncStatus.value
          : this.cloudSyncStatus,
      localSyncStatus: data.localSyncStatus.present
          ? data.localSyncStatus.value
          : this.localSyncStatus,
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
          ..write('schemaVersion: $schemaVersion, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('lockedAt: $lockedAt, ')
          ..write('localAttachmentPath: $localAttachmentPath, ')
          ..write('cloudAttachmentUrl: $cloudAttachmentUrl, ')
          ..write('folderId: $folderId, ')
          ..write('tags: $tags, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updateCounter: $updateCounter, ')
          ..write('cloudSyncStatus: $cloudSyncStatus, ')
          ..write('localSyncStatus: $localSyncStatus, ')
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
    schemaVersion,
    contentVersion,
    pinnedAt,
    archivedAt,
    lockedAt,
    localAttachmentPath,
    cloudAttachmentUrl,
    folderId,
    tags,
    reminderAt,
    ownerUid,
    createdAt,
    updatedAt,
    deletedAt,
    updateCounter,
    cloudSyncStatus,
    localSyncStatus,
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
          other.schemaVersion == this.schemaVersion &&
          other.contentVersion == this.contentVersion &&
          other.pinnedAt == this.pinnedAt &&
          other.archivedAt == this.archivedAt &&
          other.lockedAt == this.lockedAt &&
          other.localAttachmentPath == this.localAttachmentPath &&
          other.cloudAttachmentUrl == this.cloudAttachmentUrl &&
          other.folderId == this.folderId &&
          other.tags == this.tags &&
          other.reminderAt == this.reminderAt &&
          other.ownerUid == this.ownerUid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.updateCounter == this.updateCounter &&
          other.cloudSyncStatus == this.cloudSyncStatus &&
          other.localSyncStatus == this.localSyncStatus &&
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
  final Value<int> schemaVersion;
  final Value<int> contentVersion;
  final Value<DateTime?> pinnedAt;
  final Value<DateTime?> archivedAt;
  final Value<DateTime?> lockedAt;
  final Value<String?> localAttachmentPath;
  final Value<String?> cloudAttachmentUrl;
  final Value<String?> folderId;
  final Value<String?> tags;
  final Value<DateTime?> reminderAt;
  final Value<String?> ownerUid;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> updateCounter;
  final Value<int> cloudSyncStatus;
  final Value<int> localSyncStatus;
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
    this.schemaVersion = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.lockedAt = const Value.absent(),
    this.localAttachmentPath = const Value.absent(),
    this.cloudAttachmentUrl = const Value.absent(),
    this.folderId = const Value.absent(),
    this.tags = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.updateCounter = const Value.absent(),
    this.cloudSyncStatus = const Value.absent(),
    this.localSyncStatus = const Value.absent(),
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
    this.schemaVersion = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.lockedAt = const Value.absent(),
    this.localAttachmentPath = const Value.absent(),
    this.cloudAttachmentUrl = const Value.absent(),
    this.folderId = const Value.absent(),
    this.tags = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.updateCounter = const Value.absent(),
    this.cloudSyncStatus = const Value.absent(),
    this.localSyncStatus = const Value.absent(),
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
    Expression<int>? schemaVersion,
    Expression<int>? contentVersion,
    Expression<DateTime>? pinnedAt,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? lockedAt,
    Expression<String>? localAttachmentPath,
    Expression<String>? cloudAttachmentUrl,
    Expression<String>? folderId,
    Expression<String>? tags,
    Expression<DateTime>? reminderAt,
    Expression<String>? ownerUid,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? updateCounter,
    Expression<int>? cloudSyncStatus,
    Expression<int>? localSyncStatus,
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
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (contentVersion != null) 'content_version': contentVersion,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (lockedAt != null) 'locked_at': lockedAt,
      if (localAttachmentPath != null)
        'local_attachment_path': localAttachmentPath,
      if (cloudAttachmentUrl != null)
        'cloud_attachment_url': cloudAttachmentUrl,
      if (folderId != null) 'folder_id': folderId,
      if (tags != null) 'tags': tags,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (updateCounter != null) 'update_counter': updateCounter,
      if (cloudSyncStatus != null) 'cloud_sync_status': cloudSyncStatus,
      if (localSyncStatus != null) 'local_sync_status': localSyncStatus,
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
    Value<int>? schemaVersion,
    Value<int>? contentVersion,
    Value<DateTime?>? pinnedAt,
    Value<DateTime?>? archivedAt,
    Value<DateTime?>? lockedAt,
    Value<String?>? localAttachmentPath,
    Value<String?>? cloudAttachmentUrl,
    Value<String?>? folderId,
    Value<String?>? tags,
    Value<DateTime?>? reminderAt,
    Value<String?>? ownerUid,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? updateCounter,
    Value<int>? cloudSyncStatus,
    Value<int>? localSyncStatus,
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
      schemaVersion: schemaVersion ?? this.schemaVersion,
      contentVersion: contentVersion ?? this.contentVersion,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      lockedAt: lockedAt ?? this.lockedAt,
      localAttachmentPath: localAttachmentPath ?? this.localAttachmentPath,
      cloudAttachmentUrl: cloudAttachmentUrl ?? this.cloudAttachmentUrl,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      reminderAt: reminderAt ?? this.reminderAt,
      ownerUid: ownerUid ?? this.ownerUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      updateCounter: updateCounter ?? this.updateCounter,
      cloudSyncStatus: cloudSyncStatus ?? this.cloudSyncStatus,
      localSyncStatus: localSyncStatus ?? this.localSyncStatus,
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
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<int>(contentVersion.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (lockedAt.present) {
      map['locked_at'] = Variable<DateTime>(lockedAt.value);
    }
    if (localAttachmentPath.present) {
      map['local_attachment_path'] = Variable<String>(
        localAttachmentPath.value,
      );
    }
    if (cloudAttachmentUrl.present) {
      map['cloud_attachment_url'] = Variable<String>(cloudAttachmentUrl.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<DateTime>(reminderAt.value);
    }
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
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
    if (updateCounter.present) {
      map['update_counter'] = Variable<int>(updateCounter.value);
    }
    if (cloudSyncStatus.present) {
      map['cloud_sync_status'] = Variable<int>(cloudSyncStatus.value);
    }
    if (localSyncStatus.present) {
      map['local_sync_status'] = Variable<int>(localSyncStatus.value);
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
          ..write('schemaVersion: $schemaVersion, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('lockedAt: $lockedAt, ')
          ..write('localAttachmentPath: $localAttachmentPath, ')
          ..write('cloudAttachmentUrl: $cloudAttachmentUrl, ')
          ..write('folderId: $folderId, ')
          ..write('tags: $tags, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updateCounter: $updateCounter, ')
          ..write('cloudSyncStatus: $cloudSyncStatus, ')
          ..write('localSyncStatus: $localSyncStatus, ')
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

class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta(
    'pinnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
    'pinned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updateCounterMeta = const VerificationMeta(
    'updateCounter',
  );
  @override
  late final GeneratedColumn<int> updateCounter = GeneratedColumn<int>(
    'update_counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
    name,
    colorIndex,
    ownerUid,
    createdAt,
    updatedAt,
    deletedAt,
    pinnedAt,
    updateCounter,
    cloudSyncStatus,
    localSyncStatus,
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
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    }
    if (data.containsKey('owner_uid')) {
      context.handle(
        _ownerUidMeta,
        ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta),
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
    if (data.containsKey('pinned_at')) {
      context.handle(
        _pinnedAtMeta,
        pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta),
      );
    }
    if (data.containsKey('update_counter')) {
      context.handle(
        _updateCounterMeta,
        updateCounter.isAcceptableOrUnknown(
          data['update_counter']!,
          _updateCounterMeta,
        ),
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
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      )!,
      ownerUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_uid'],
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
      pinnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pinned_at'],
      ),
      updateCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_counter'],
      )!,
      cloudSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cloud_sync_status'],
      )!,
      localSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_sync_status'],
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
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final String uuid;
  final String name;
  final int colorIndex;
  final String? ownerUid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? pinnedAt;
  final int updateCounter;
  final int cloudSyncStatus;
  final int localSyncStatus;
  final String? creationPlatform;
  final String? creationDevice;
  final String? lastEditedPlatform;
  final String? lastEditedDevice;
  final String? deletedPlatform;
  final String? deletedDevice;
  const Folder({
    required this.uuid,
    required this.name,
    required this.colorIndex,
    this.ownerUid,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.pinnedAt,
    required this.updateCounter,
    required this.cloudSyncStatus,
    required this.localSyncStatus,
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
    map['name'] = Variable<String>(name);
    map['color_index'] = Variable<int>(colorIndex);
    if (!nullToAbsent || ownerUid != null) {
      map['owner_uid'] = Variable<String>(ownerUid);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
    map['update_counter'] = Variable<int>(updateCounter);
    map['cloud_sync_status'] = Variable<int>(cloudSyncStatus);
    map['local_sync_status'] = Variable<int>(localSyncStatus);
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

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      uuid: Value(uuid),
      name: Value(name),
      colorIndex: Value(colorIndex),
      ownerUid: ownerUid == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pinnedAt: pinnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedAt),
      updateCounter: Value(updateCounter),
      cloudSyncStatus: Value(cloudSyncStatus),
      localSyncStatus: Value(localSyncStatus),
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

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      ownerUid: serializer.fromJson<String?>(json['ownerUid']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
      updateCounter: serializer.fromJson<int>(json['updateCounter']),
      cloudSyncStatus: serializer.fromJson<int>(json['cloudSyncStatus']),
      localSyncStatus: serializer.fromJson<int>(json['localSyncStatus']),
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
      'name': serializer.toJson<String>(name),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'ownerUid': serializer.toJson<String?>(ownerUid),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
      'updateCounter': serializer.toJson<int>(updateCounter),
      'cloudSyncStatus': serializer.toJson<int>(cloudSyncStatus),
      'localSyncStatus': serializer.toJson<int>(localSyncStatus),
      'creationPlatform': serializer.toJson<String?>(creationPlatform),
      'creationDevice': serializer.toJson<String?>(creationDevice),
      'lastEditedPlatform': serializer.toJson<String?>(lastEditedPlatform),
      'lastEditedDevice': serializer.toJson<String?>(lastEditedDevice),
      'deletedPlatform': serializer.toJson<String?>(deletedPlatform),
      'deletedDevice': serializer.toJson<String?>(deletedDevice),
    };
  }

  Folder copyWith({
    String? uuid,
    String? name,
    int? colorIndex,
    Value<String?> ownerUid = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> pinnedAt = const Value.absent(),
    int? updateCounter,
    int? cloudSyncStatus,
    int? localSyncStatus,
    Value<String?> creationPlatform = const Value.absent(),
    Value<String?> creationDevice = const Value.absent(),
    Value<String?> lastEditedPlatform = const Value.absent(),
    Value<String?> lastEditedDevice = const Value.absent(),
    Value<String?> deletedPlatform = const Value.absent(),
    Value<String?> deletedDevice = const Value.absent(),
  }) => Folder(
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    colorIndex: colorIndex ?? this.colorIndex,
    ownerUid: ownerUid.present ? ownerUid.value : this.ownerUid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    updateCounter: updateCounter ?? this.updateCounter,
    cloudSyncStatus: cloudSyncStatus ?? this.cloudSyncStatus,
    localSyncStatus: localSyncStatus ?? this.localSyncStatus,
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
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      updateCounter: data.updateCounter.present
          ? data.updateCounter.value
          : this.updateCounter,
      cloudSyncStatus: data.cloudSyncStatus.present
          ? data.cloudSyncStatus.value
          : this.cloudSyncStatus,
      localSyncStatus: data.localSyncStatus.present
          ? data.localSyncStatus.value
          : this.localSyncStatus,
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
    return (StringBuffer('Folder(')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('updateCounter: $updateCounter, ')
          ..write('cloudSyncStatus: $cloudSyncStatus, ')
          ..write('localSyncStatus: $localSyncStatus, ')
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
  int get hashCode => Object.hash(
    uuid,
    name,
    colorIndex,
    ownerUid,
    createdAt,
    updatedAt,
    deletedAt,
    pinnedAt,
    updateCounter,
    cloudSyncStatus,
    localSyncStatus,
    creationPlatform,
    creationDevice,
    lastEditedPlatform,
    lastEditedDevice,
    deletedPlatform,
    deletedDevice,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.colorIndex == this.colorIndex &&
          other.ownerUid == this.ownerUid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pinnedAt == this.pinnedAt &&
          other.updateCounter == this.updateCounter &&
          other.cloudSyncStatus == this.cloudSyncStatus &&
          other.localSyncStatus == this.localSyncStatus &&
          other.creationPlatform == this.creationPlatform &&
          other.creationDevice == this.creationDevice &&
          other.lastEditedPlatform == this.lastEditedPlatform &&
          other.lastEditedDevice == this.lastEditedDevice &&
          other.deletedPlatform == this.deletedPlatform &&
          other.deletedDevice == this.deletedDevice);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<String> uuid;
  final Value<String> name;
  final Value<int> colorIndex;
  final Value<String?> ownerUid;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> pinnedAt;
  final Value<int> updateCounter;
  final Value<int> cloudSyncStatus;
  final Value<int> localSyncStatus;
  final Value<String?> creationPlatform;
  final Value<String?> creationDevice;
  final Value<String?> lastEditedPlatform;
  final Value<String?> lastEditedDevice;
  final Value<String?> deletedPlatform;
  final Value<String?> deletedDevice;
  final Value<int> rowid;
  const FoldersCompanion({
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.updateCounter = const Value.absent(),
    this.cloudSyncStatus = const Value.absent(),
    this.localSyncStatus = const Value.absent(),
    this.creationPlatform = const Value.absent(),
    this.creationDevice = const Value.absent(),
    this.lastEditedPlatform = const Value.absent(),
    this.lastEditedDevice = const Value.absent(),
    this.deletedPlatform = const Value.absent(),
    this.deletedDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    this.uuid = const Value.absent(),
    required String name,
    this.colorIndex = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.updateCounter = const Value.absent(),
    this.cloudSyncStatus = const Value.absent(),
    this.localSyncStatus = const Value.absent(),
    this.creationPlatform = const Value.absent(),
    this.creationDevice = const Value.absent(),
    this.lastEditedPlatform = const Value.absent(),
    this.lastEditedDevice = const Value.absent(),
    this.deletedPlatform = const Value.absent(),
    this.deletedDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Folder> custom({
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<int>? colorIndex,
    Expression<String>? ownerUid,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? pinnedAt,
    Expression<int>? updateCounter,
    Expression<int>? cloudSyncStatus,
    Expression<int>? localSyncStatus,
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
      if (name != null) 'name': name,
      if (colorIndex != null) 'color_index': colorIndex,
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (updateCounter != null) 'update_counter': updateCounter,
      if (cloudSyncStatus != null) 'cloud_sync_status': cloudSyncStatus,
      if (localSyncStatus != null) 'local_sync_status': localSyncStatus,
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

  FoldersCompanion copyWith({
    Value<String>? uuid,
    Value<String>? name,
    Value<int>? colorIndex,
    Value<String?>? ownerUid,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? pinnedAt,
    Value<int>? updateCounter,
    Value<int>? cloudSyncStatus,
    Value<int>? localSyncStatus,
    Value<String?>? creationPlatform,
    Value<String?>? creationDevice,
    Value<String?>? lastEditedPlatform,
    Value<String?>? lastEditedDevice,
    Value<String?>? deletedPlatform,
    Value<String?>? deletedDevice,
    Value<int>? rowid,
  }) {
    return FoldersCompanion(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      ownerUid: ownerUid ?? this.ownerUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      updateCounter: updateCounter ?? this.updateCounter,
      cloudSyncStatus: cloudSyncStatus ?? this.cloudSyncStatus,
      localSyncStatus: localSyncStatus ?? this.localSyncStatus,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
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
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
    }
    if (updateCounter.present) {
      map['update_counter'] = Variable<int>(updateCounter.value);
    }
    if (cloudSyncStatus.present) {
      map['cloud_sync_status'] = Variable<int>(cloudSyncStatus.value);
    }
    if (localSyncStatus.present) {
      map['local_sync_status'] = Variable<int>(localSyncStatus.value);
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
    return (StringBuffer('FoldersCompanion(')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('updateCounter: $updateCounter, ')
          ..write('cloudSyncStatus: $cloudSyncStatus, ')
          ..write('localSyncStatus: $localSyncStatus, ')
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
  static const VerificationMeta _customAliasMeta = const VerificationMeta(
    'customAlias',
  );
  @override
  late final GeneratedColumn<String> customAlias = GeneratedColumn<String>(
    'custom_alias',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _blockedAtMeta = const VerificationMeta(
    'blockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> blockedAt = GeneratedColumn<DateTime>(
    'blocked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authKeyMeta = const VerificationMeta(
    'authKey',
  );
  @override
  late final GeneratedColumn<String> authKey = GeneratedColumn<String>(
    'auth_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _deviceTypeMeta = const VerificationMeta(
    'deviceType',
  );
  @override
  late final GeneratedColumn<String> deviceType = GeneratedColumn<String>(
    'device_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _protocolVersionMeta = const VerificationMeta(
    'protocolVersion',
  );
  @override
  late final GeneratedColumn<int> protocolVersion = GeneratedColumn<int>(
    'protocol_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSuccessfulSyncAtMeta =
      const VerificationMeta('lastSuccessfulSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessfulSyncAt =
      GeneratedColumn<DateTime>(
        'last_successful_sync_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
  static const VerificationMeta _updateCounterMeta = const VerificationMeta(
    'updateCounter',
  );
  @override
  late final GeneratedColumn<int> updateCounter = GeneratedColumn<int>(
    'update_counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceUuid,
    deviceName,
    customAlias,
    lastKnownIp,
    lastKnownPort,
    lastSeenAsHostAt,
    lastSeenAsClientAt,
    firstPairedAt,
    blockedAt,
    publicKey,
    authKey,
    schemaVersion,
    deviceType,
    protocolVersion,
    lastSuccessfulSyncAt,
    updatedAt,
    deletedAt,
    updateCounter,
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
    if (data.containsKey('custom_alias')) {
      context.handle(
        _customAliasMeta,
        customAlias.isAcceptableOrUnknown(
          data['custom_alias']!,
          _customAliasMeta,
        ),
      );
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
    if (data.containsKey('blocked_at')) {
      context.handle(
        _blockedAtMeta,
        blockedAt.isAcceptableOrUnknown(data['blocked_at']!, _blockedAtMeta),
      );
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    }
    if (data.containsKey('auth_key')) {
      context.handle(
        _authKeyMeta,
        authKey.isAcceptableOrUnknown(data['auth_key']!, _authKeyMeta),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('device_type')) {
      context.handle(
        _deviceTypeMeta,
        deviceType.isAcceptableOrUnknown(data['device_type']!, _deviceTypeMeta),
      );
    }
    if (data.containsKey('protocol_version')) {
      context.handle(
        _protocolVersionMeta,
        protocolVersion.isAcceptableOrUnknown(
          data['protocol_version']!,
          _protocolVersionMeta,
        ),
      );
    }
    if (data.containsKey('last_successful_sync_at')) {
      context.handle(
        _lastSuccessfulSyncAtMeta,
        lastSuccessfulSyncAt.isAcceptableOrUnknown(
          data['last_successful_sync_at']!,
          _lastSuccessfulSyncAtMeta,
        ),
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
    if (data.containsKey('update_counter')) {
      context.handle(
        _updateCounterMeta,
        updateCounter.isAcceptableOrUnknown(
          data['update_counter']!,
          _updateCounterMeta,
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
      customAlias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_alias'],
      ),
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
      blockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}blocked_at'],
      ),
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      ),
      authKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_key'],
      ),
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      deviceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_type'],
      ),
      protocolVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protocol_version'],
      ),
      lastSuccessfulSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_successful_sync_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      updateCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_counter'],
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
  final String? customAlias;
  final String? lastKnownIp;
  final int? lastKnownPort;
  final DateTime? lastSeenAsHostAt;
  final DateTime? lastSeenAsClientAt;
  final DateTime firstPairedAt;
  final DateTime? blockedAt;
  final String? publicKey;
  final String? authKey;
  final int schemaVersion;
  final String? deviceType;
  final int? protocolVersion;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int updateCounter;
  const SyncedDevice({
    required this.deviceUuid,
    required this.deviceName,
    this.customAlias,
    this.lastKnownIp,
    this.lastKnownPort,
    this.lastSeenAsHostAt,
    this.lastSeenAsClientAt,
    required this.firstPairedAt,
    this.blockedAt,
    this.publicKey,
    this.authKey,
    required this.schemaVersion,
    this.deviceType,
    this.protocolVersion,
    this.lastSuccessfulSyncAt,
    required this.updatedAt,
    this.deletedAt,
    required this.updateCounter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_uuid'] = Variable<String>(deviceUuid);
    map['device_name'] = Variable<String>(deviceName);
    if (!nullToAbsent || customAlias != null) {
      map['custom_alias'] = Variable<String>(customAlias);
    }
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
    if (!nullToAbsent || blockedAt != null) {
      map['blocked_at'] = Variable<DateTime>(blockedAt);
    }
    if (!nullToAbsent || publicKey != null) {
      map['public_key'] = Variable<String>(publicKey);
    }
    if (!nullToAbsent || authKey != null) {
      map['auth_key'] = Variable<String>(authKey);
    }
    map['schema_version'] = Variable<int>(schemaVersion);
    if (!nullToAbsent || deviceType != null) {
      map['device_type'] = Variable<String>(deviceType);
    }
    if (!nullToAbsent || protocolVersion != null) {
      map['protocol_version'] = Variable<int>(protocolVersion);
    }
    if (!nullToAbsent || lastSuccessfulSyncAt != null) {
      map['last_successful_sync_at'] = Variable<DateTime>(lastSuccessfulSyncAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['update_counter'] = Variable<int>(updateCounter);
    return map;
  }

  SyncedDevicesCompanion toCompanion(bool nullToAbsent) {
    return SyncedDevicesCompanion(
      deviceUuid: Value(deviceUuid),
      deviceName: Value(deviceName),
      customAlias: customAlias == null && nullToAbsent
          ? const Value.absent()
          : Value(customAlias),
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
      blockedAt: blockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(blockedAt),
      publicKey: publicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKey),
      authKey: authKey == null && nullToAbsent
          ? const Value.absent()
          : Value(authKey),
      schemaVersion: Value(schemaVersion),
      deviceType: deviceType == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceType),
      protocolVersion: protocolVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(protocolVersion),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessfulSyncAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      updateCounter: Value(updateCounter),
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
      customAlias: serializer.fromJson<String?>(json['customAlias']),
      lastKnownIp: serializer.fromJson<String?>(json['lastKnownIp']),
      lastKnownPort: serializer.fromJson<int?>(json['lastKnownPort']),
      lastSeenAsHostAt: serializer.fromJson<DateTime?>(
        json['lastSeenAsHostAt'],
      ),
      lastSeenAsClientAt: serializer.fromJson<DateTime?>(
        json['lastSeenAsClientAt'],
      ),
      firstPairedAt: serializer.fromJson<DateTime>(json['firstPairedAt']),
      blockedAt: serializer.fromJson<DateTime?>(json['blockedAt']),
      publicKey: serializer.fromJson<String?>(json['publicKey']),
      authKey: serializer.fromJson<String?>(json['authKey']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      deviceType: serializer.fromJson<String?>(json['deviceType']),
      protocolVersion: serializer.fromJson<int?>(json['protocolVersion']),
      lastSuccessfulSyncAt: serializer.fromJson<DateTime?>(
        json['lastSuccessfulSyncAt'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      updateCounter: serializer.fromJson<int>(json['updateCounter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceUuid': serializer.toJson<String>(deviceUuid),
      'deviceName': serializer.toJson<String>(deviceName),
      'customAlias': serializer.toJson<String?>(customAlias),
      'lastKnownIp': serializer.toJson<String?>(lastKnownIp),
      'lastKnownPort': serializer.toJson<int?>(lastKnownPort),
      'lastSeenAsHostAt': serializer.toJson<DateTime?>(lastSeenAsHostAt),
      'lastSeenAsClientAt': serializer.toJson<DateTime?>(lastSeenAsClientAt),
      'firstPairedAt': serializer.toJson<DateTime>(firstPairedAt),
      'blockedAt': serializer.toJson<DateTime?>(blockedAt),
      'publicKey': serializer.toJson<String?>(publicKey),
      'authKey': serializer.toJson<String?>(authKey),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'deviceType': serializer.toJson<String?>(deviceType),
      'protocolVersion': serializer.toJson<int?>(protocolVersion),
      'lastSuccessfulSyncAt': serializer.toJson<DateTime?>(
        lastSuccessfulSyncAt,
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'updateCounter': serializer.toJson<int>(updateCounter),
    };
  }

  SyncedDevice copyWith({
    String? deviceUuid,
    String? deviceName,
    Value<String?> customAlias = const Value.absent(),
    Value<String?> lastKnownIp = const Value.absent(),
    Value<int?> lastKnownPort = const Value.absent(),
    Value<DateTime?> lastSeenAsHostAt = const Value.absent(),
    Value<DateTime?> lastSeenAsClientAt = const Value.absent(),
    DateTime? firstPairedAt,
    Value<DateTime?> blockedAt = const Value.absent(),
    Value<String?> publicKey = const Value.absent(),
    Value<String?> authKey = const Value.absent(),
    int? schemaVersion,
    Value<String?> deviceType = const Value.absent(),
    Value<int?> protocolVersion = const Value.absent(),
    Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? updateCounter,
  }) => SyncedDevice(
    deviceUuid: deviceUuid ?? this.deviceUuid,
    deviceName: deviceName ?? this.deviceName,
    customAlias: customAlias.present ? customAlias.value : this.customAlias,
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
    blockedAt: blockedAt.present ? blockedAt.value : this.blockedAt,
    publicKey: publicKey.present ? publicKey.value : this.publicKey,
    authKey: authKey.present ? authKey.value : this.authKey,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    deviceType: deviceType.present ? deviceType.value : this.deviceType,
    protocolVersion: protocolVersion.present
        ? protocolVersion.value
        : this.protocolVersion,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt.present
        ? lastSuccessfulSyncAt.value
        : this.lastSuccessfulSyncAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    updateCounter: updateCounter ?? this.updateCounter,
  );
  SyncedDevice copyWithCompanion(SyncedDevicesCompanion data) {
    return SyncedDevice(
      deviceUuid: data.deviceUuid.present
          ? data.deviceUuid.value
          : this.deviceUuid,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      customAlias: data.customAlias.present
          ? data.customAlias.value
          : this.customAlias,
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
      blockedAt: data.blockedAt.present ? data.blockedAt.value : this.blockedAt,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      authKey: data.authKey.present ? data.authKey.value : this.authKey,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      deviceType: data.deviceType.present
          ? data.deviceType.value
          : this.deviceType,
      protocolVersion: data.protocolVersion.present
          ? data.protocolVersion.value
          : this.protocolVersion,
      lastSuccessfulSyncAt: data.lastSuccessfulSyncAt.present
          ? data.lastSuccessfulSyncAt.value
          : this.lastSuccessfulSyncAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      updateCounter: data.updateCounter.present
          ? data.updateCounter.value
          : this.updateCounter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedDevice(')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('deviceName: $deviceName, ')
          ..write('customAlias: $customAlias, ')
          ..write('lastKnownIp: $lastKnownIp, ')
          ..write('lastKnownPort: $lastKnownPort, ')
          ..write('lastSeenAsHostAt: $lastSeenAsHostAt, ')
          ..write('lastSeenAsClientAt: $lastSeenAsClientAt, ')
          ..write('firstPairedAt: $firstPairedAt, ')
          ..write('blockedAt: $blockedAt, ')
          ..write('publicKey: $publicKey, ')
          ..write('authKey: $authKey, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('deviceType: $deviceType, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updateCounter: $updateCounter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceUuid,
    deviceName,
    customAlias,
    lastKnownIp,
    lastKnownPort,
    lastSeenAsHostAt,
    lastSeenAsClientAt,
    firstPairedAt,
    blockedAt,
    publicKey,
    authKey,
    schemaVersion,
    deviceType,
    protocolVersion,
    lastSuccessfulSyncAt,
    updatedAt,
    deletedAt,
    updateCounter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedDevice &&
          other.deviceUuid == this.deviceUuid &&
          other.deviceName == this.deviceName &&
          other.customAlias == this.customAlias &&
          other.lastKnownIp == this.lastKnownIp &&
          other.lastKnownPort == this.lastKnownPort &&
          other.lastSeenAsHostAt == this.lastSeenAsHostAt &&
          other.lastSeenAsClientAt == this.lastSeenAsClientAt &&
          other.firstPairedAt == this.firstPairedAt &&
          other.blockedAt == this.blockedAt &&
          other.publicKey == this.publicKey &&
          other.authKey == this.authKey &&
          other.schemaVersion == this.schemaVersion &&
          other.deviceType == this.deviceType &&
          other.protocolVersion == this.protocolVersion &&
          other.lastSuccessfulSyncAt == this.lastSuccessfulSyncAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.updateCounter == this.updateCounter);
}

class SyncedDevicesCompanion extends UpdateCompanion<SyncedDevice> {
  final Value<String> deviceUuid;
  final Value<String> deviceName;
  final Value<String?> customAlias;
  final Value<String?> lastKnownIp;
  final Value<int?> lastKnownPort;
  final Value<DateTime?> lastSeenAsHostAt;
  final Value<DateTime?> lastSeenAsClientAt;
  final Value<DateTime> firstPairedAt;
  final Value<DateTime?> blockedAt;
  final Value<String?> publicKey;
  final Value<String?> authKey;
  final Value<int> schemaVersion;
  final Value<String?> deviceType;
  final Value<int?> protocolVersion;
  final Value<DateTime?> lastSuccessfulSyncAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> updateCounter;
  final Value<int> rowid;
  const SyncedDevicesCompanion({
    this.deviceUuid = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.customAlias = const Value.absent(),
    this.lastKnownIp = const Value.absent(),
    this.lastKnownPort = const Value.absent(),
    this.lastSeenAsHostAt = const Value.absent(),
    this.lastSeenAsClientAt = const Value.absent(),
    this.firstPairedAt = const Value.absent(),
    this.blockedAt = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.authKey = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.deviceType = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.updateCounter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedDevicesCompanion.insert({
    required String deviceUuid,
    required String deviceName,
    this.customAlias = const Value.absent(),
    this.lastKnownIp = const Value.absent(),
    this.lastKnownPort = const Value.absent(),
    this.lastSeenAsHostAt = const Value.absent(),
    this.lastSeenAsClientAt = const Value.absent(),
    this.firstPairedAt = const Value.absent(),
    this.blockedAt = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.authKey = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.deviceType = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.updateCounter = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceUuid = Value(deviceUuid),
       deviceName = Value(deviceName);
  static Insertable<SyncedDevice> custom({
    Expression<String>? deviceUuid,
    Expression<String>? deviceName,
    Expression<String>? customAlias,
    Expression<String>? lastKnownIp,
    Expression<int>? lastKnownPort,
    Expression<DateTime>? lastSeenAsHostAt,
    Expression<DateTime>? lastSeenAsClientAt,
    Expression<DateTime>? firstPairedAt,
    Expression<DateTime>? blockedAt,
    Expression<String>? publicKey,
    Expression<String>? authKey,
    Expression<int>? schemaVersion,
    Expression<String>? deviceType,
    Expression<int>? protocolVersion,
    Expression<DateTime>? lastSuccessfulSyncAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? updateCounter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceUuid != null) 'device_uuid': deviceUuid,
      if (deviceName != null) 'device_name': deviceName,
      if (customAlias != null) 'custom_alias': customAlias,
      if (lastKnownIp != null) 'last_known_ip': lastKnownIp,
      if (lastKnownPort != null) 'last_known_port': lastKnownPort,
      if (lastSeenAsHostAt != null) 'last_seen_as_host_at': lastSeenAsHostAt,
      if (lastSeenAsClientAt != null)
        'last_seen_as_client_at': lastSeenAsClientAt,
      if (firstPairedAt != null) 'first_paired_at': firstPairedAt,
      if (blockedAt != null) 'blocked_at': blockedAt,
      if (publicKey != null) 'public_key': publicKey,
      if (authKey != null) 'auth_key': authKey,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (deviceType != null) 'device_type': deviceType,
      if (protocolVersion != null) 'protocol_version': protocolVersion,
      if (lastSuccessfulSyncAt != null)
        'last_successful_sync_at': lastSuccessfulSyncAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (updateCounter != null) 'update_counter': updateCounter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedDevicesCompanion copyWith({
    Value<String>? deviceUuid,
    Value<String>? deviceName,
    Value<String?>? customAlias,
    Value<String?>? lastKnownIp,
    Value<int?>? lastKnownPort,
    Value<DateTime?>? lastSeenAsHostAt,
    Value<DateTime?>? lastSeenAsClientAt,
    Value<DateTime>? firstPairedAt,
    Value<DateTime?>? blockedAt,
    Value<String?>? publicKey,
    Value<String?>? authKey,
    Value<int>? schemaVersion,
    Value<String?>? deviceType,
    Value<int?>? protocolVersion,
    Value<DateTime?>? lastSuccessfulSyncAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? updateCounter,
    Value<int>? rowid,
  }) {
    return SyncedDevicesCompanion(
      deviceUuid: deviceUuid ?? this.deviceUuid,
      deviceName: deviceName ?? this.deviceName,
      customAlias: customAlias ?? this.customAlias,
      lastKnownIp: lastKnownIp ?? this.lastKnownIp,
      lastKnownPort: lastKnownPort ?? this.lastKnownPort,
      lastSeenAsHostAt: lastSeenAsHostAt ?? this.lastSeenAsHostAt,
      lastSeenAsClientAt: lastSeenAsClientAt ?? this.lastSeenAsClientAt,
      firstPairedAt: firstPairedAt ?? this.firstPairedAt,
      blockedAt: blockedAt ?? this.blockedAt,
      publicKey: publicKey ?? this.publicKey,
      authKey: authKey ?? this.authKey,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      deviceType: deviceType ?? this.deviceType,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      updateCounter: updateCounter ?? this.updateCounter,
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
    if (customAlias.present) {
      map['custom_alias'] = Variable<String>(customAlias.value);
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
    if (blockedAt.present) {
      map['blocked_at'] = Variable<DateTime>(blockedAt.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (authKey.present) {
      map['auth_key'] = Variable<String>(authKey.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (deviceType.present) {
      map['device_type'] = Variable<String>(deviceType.value);
    }
    if (protocolVersion.present) {
      map['protocol_version'] = Variable<int>(protocolVersion.value);
    }
    if (lastSuccessfulSyncAt.present) {
      map['last_successful_sync_at'] = Variable<DateTime>(
        lastSuccessfulSyncAt.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (updateCounter.present) {
      map['update_counter'] = Variable<int>(updateCounter.value);
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
          ..write('customAlias: $customAlias, ')
          ..write('lastKnownIp: $lastKnownIp, ')
          ..write('lastKnownPort: $lastKnownPort, ')
          ..write('lastSeenAsHostAt: $lastSeenAsHostAt, ')
          ..write('lastSeenAsClientAt: $lastSeenAsClientAt, ')
          ..write('firstPairedAt: $firstPairedAt, ')
          ..write('blockedAt: $blockedAt, ')
          ..write('publicKey: $publicKey, ')
          ..write('authKey: $authKey, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('deviceType: $deviceType, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updateCounter: $updateCounter, ')
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
  static const VerificationMeta _targetPlatformMeta = const VerificationMeta(
    'targetPlatform',
  );
  @override
  late final GeneratedColumn<String> targetPlatform = GeneratedColumn<String>(
    'target_platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('windows'),
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
  static const VerificationMeta _disabledAtMeta = const VerificationMeta(
    'disabledAt',
  );
  @override
  late final GeneratedColumn<DateTime> disabledAt = GeneratedColumn<DateTime>(
    'disabled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
  static const VerificationMeta _updateCounterMeta = const VerificationMeta(
    'updateCounter',
  );
  @override
  late final GeneratedColumn<int> updateCounter = GeneratedColumn<int>(
    'update_counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    actionName,
    targetPlatform,
    keyLabel,
    keyId,
    useCtrl,
    useAlt,
    useShift,
    useMeta,
    disabledAt,
    category,
    schemaVersion,
    updatedAt,
    deletedAt,
    updateCounter,
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
    if (data.containsKey('target_platform')) {
      context.handle(
        _targetPlatformMeta,
        targetPlatform.isAcceptableOrUnknown(
          data['target_platform']!,
          _targetPlatformMeta,
        ),
      );
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
    if (data.containsKey('disabled_at')) {
      context.handle(
        _disabledAtMeta,
        disabledAt.isAcceptableOrUnknown(data['disabled_at']!, _disabledAtMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
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
    if (data.containsKey('update_counter')) {
      context.handle(
        _updateCounterMeta,
        updateCounter.isAcceptableOrUnknown(
          data['update_counter']!,
          _updateCounterMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actionName, targetPlatform};
  @override
  AppKeybinding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppKeybinding(
      actionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_name'],
      )!,
      targetPlatform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_platform'],
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
      disabledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}disabled_at'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      updateCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_counter'],
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
  final String targetPlatform;
  final String keyLabel;
  final int keyId;
  final bool useCtrl;
  final bool useAlt;
  final bool useShift;
  final bool useMeta;
  final DateTime? disabledAt;
  final String category;
  final int schemaVersion;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int updateCounter;
  const AppKeybinding({
    required this.actionName,
    required this.targetPlatform,
    required this.keyLabel,
    required this.keyId,
    required this.useCtrl,
    required this.useAlt,
    required this.useShift,
    required this.useMeta,
    this.disabledAt,
    required this.category,
    required this.schemaVersion,
    required this.updatedAt,
    this.deletedAt,
    required this.updateCounter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['action_name'] = Variable<String>(actionName);
    map['target_platform'] = Variable<String>(targetPlatform);
    map['key_label'] = Variable<String>(keyLabel);
    map['key_id'] = Variable<int>(keyId);
    map['use_ctrl'] = Variable<bool>(useCtrl);
    map['use_alt'] = Variable<bool>(useAlt);
    map['use_shift'] = Variable<bool>(useShift);
    map['use_meta'] = Variable<bool>(useMeta);
    if (!nullToAbsent || disabledAt != null) {
      map['disabled_at'] = Variable<DateTime>(disabledAt);
    }
    map['category'] = Variable<String>(category);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['update_counter'] = Variable<int>(updateCounter);
    return map;
  }

  AppKeybindingsCompanion toCompanion(bool nullToAbsent) {
    return AppKeybindingsCompanion(
      actionName: Value(actionName),
      targetPlatform: Value(targetPlatform),
      keyLabel: Value(keyLabel),
      keyId: Value(keyId),
      useCtrl: Value(useCtrl),
      useAlt: Value(useAlt),
      useShift: Value(useShift),
      useMeta: Value(useMeta),
      disabledAt: disabledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(disabledAt),
      category: Value(category),
      schemaVersion: Value(schemaVersion),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      updateCounter: Value(updateCounter),
    );
  }

  factory AppKeybinding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppKeybinding(
      actionName: serializer.fromJson<String>(json['actionName']),
      targetPlatform: serializer.fromJson<String>(json['targetPlatform']),
      keyLabel: serializer.fromJson<String>(json['keyLabel']),
      keyId: serializer.fromJson<int>(json['keyId']),
      useCtrl: serializer.fromJson<bool>(json['useCtrl']),
      useAlt: serializer.fromJson<bool>(json['useAlt']),
      useShift: serializer.fromJson<bool>(json['useShift']),
      useMeta: serializer.fromJson<bool>(json['useMeta']),
      disabledAt: serializer.fromJson<DateTime?>(json['disabledAt']),
      category: serializer.fromJson<String>(json['category']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      updateCounter: serializer.fromJson<int>(json['updateCounter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actionName': serializer.toJson<String>(actionName),
      'targetPlatform': serializer.toJson<String>(targetPlatform),
      'keyLabel': serializer.toJson<String>(keyLabel),
      'keyId': serializer.toJson<int>(keyId),
      'useCtrl': serializer.toJson<bool>(useCtrl),
      'useAlt': serializer.toJson<bool>(useAlt),
      'useShift': serializer.toJson<bool>(useShift),
      'useMeta': serializer.toJson<bool>(useMeta),
      'disabledAt': serializer.toJson<DateTime?>(disabledAt),
      'category': serializer.toJson<String>(category),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'updateCounter': serializer.toJson<int>(updateCounter),
    };
  }

  AppKeybinding copyWith({
    String? actionName,
    String? targetPlatform,
    String? keyLabel,
    int? keyId,
    bool? useCtrl,
    bool? useAlt,
    bool? useShift,
    bool? useMeta,
    Value<DateTime?> disabledAt = const Value.absent(),
    String? category,
    int? schemaVersion,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? updateCounter,
  }) => AppKeybinding(
    actionName: actionName ?? this.actionName,
    targetPlatform: targetPlatform ?? this.targetPlatform,
    keyLabel: keyLabel ?? this.keyLabel,
    keyId: keyId ?? this.keyId,
    useCtrl: useCtrl ?? this.useCtrl,
    useAlt: useAlt ?? this.useAlt,
    useShift: useShift ?? this.useShift,
    useMeta: useMeta ?? this.useMeta,
    disabledAt: disabledAt.present ? disabledAt.value : this.disabledAt,
    category: category ?? this.category,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    updateCounter: updateCounter ?? this.updateCounter,
  );
  AppKeybinding copyWithCompanion(AppKeybindingsCompanion data) {
    return AppKeybinding(
      actionName: data.actionName.present
          ? data.actionName.value
          : this.actionName,
      targetPlatform: data.targetPlatform.present
          ? data.targetPlatform.value
          : this.targetPlatform,
      keyLabel: data.keyLabel.present ? data.keyLabel.value : this.keyLabel,
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      useCtrl: data.useCtrl.present ? data.useCtrl.value : this.useCtrl,
      useAlt: data.useAlt.present ? data.useAlt.value : this.useAlt,
      useShift: data.useShift.present ? data.useShift.value : this.useShift,
      useMeta: data.useMeta.present ? data.useMeta.value : this.useMeta,
      disabledAt: data.disabledAt.present
          ? data.disabledAt.value
          : this.disabledAt,
      category: data.category.present ? data.category.value : this.category,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      updateCounter: data.updateCounter.present
          ? data.updateCounter.value
          : this.updateCounter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppKeybinding(')
          ..write('actionName: $actionName, ')
          ..write('targetPlatform: $targetPlatform, ')
          ..write('keyLabel: $keyLabel, ')
          ..write('keyId: $keyId, ')
          ..write('useCtrl: $useCtrl, ')
          ..write('useAlt: $useAlt, ')
          ..write('useShift: $useShift, ')
          ..write('useMeta: $useMeta, ')
          ..write('disabledAt: $disabledAt, ')
          ..write('category: $category, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updateCounter: $updateCounter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    actionName,
    targetPlatform,
    keyLabel,
    keyId,
    useCtrl,
    useAlt,
    useShift,
    useMeta,
    disabledAt,
    category,
    schemaVersion,
    updatedAt,
    deletedAt,
    updateCounter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppKeybinding &&
          other.actionName == this.actionName &&
          other.targetPlatform == this.targetPlatform &&
          other.keyLabel == this.keyLabel &&
          other.keyId == this.keyId &&
          other.useCtrl == this.useCtrl &&
          other.useAlt == this.useAlt &&
          other.useShift == this.useShift &&
          other.useMeta == this.useMeta &&
          other.disabledAt == this.disabledAt &&
          other.category == this.category &&
          other.schemaVersion == this.schemaVersion &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.updateCounter == this.updateCounter);
}

class AppKeybindingsCompanion extends UpdateCompanion<AppKeybinding> {
  final Value<String> actionName;
  final Value<String> targetPlatform;
  final Value<String> keyLabel;
  final Value<int> keyId;
  final Value<bool> useCtrl;
  final Value<bool> useAlt;
  final Value<bool> useShift;
  final Value<bool> useMeta;
  final Value<DateTime?> disabledAt;
  final Value<String> category;
  final Value<int> schemaVersion;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> updateCounter;
  final Value<int> rowid;
  const AppKeybindingsCompanion({
    this.actionName = const Value.absent(),
    this.targetPlatform = const Value.absent(),
    this.keyLabel = const Value.absent(),
    this.keyId = const Value.absent(),
    this.useCtrl = const Value.absent(),
    this.useAlt = const Value.absent(),
    this.useShift = const Value.absent(),
    this.useMeta = const Value.absent(),
    this.disabledAt = const Value.absent(),
    this.category = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.updateCounter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppKeybindingsCompanion.insert({
    required String actionName,
    this.targetPlatform = const Value.absent(),
    required String keyLabel,
    required int keyId,
    this.useCtrl = const Value.absent(),
    this.useAlt = const Value.absent(),
    this.useShift = const Value.absent(),
    this.useMeta = const Value.absent(),
    this.disabledAt = const Value.absent(),
    this.category = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.updateCounter = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : actionName = Value(actionName),
       keyLabel = Value(keyLabel),
       keyId = Value(keyId);
  static Insertable<AppKeybinding> custom({
    Expression<String>? actionName,
    Expression<String>? targetPlatform,
    Expression<String>? keyLabel,
    Expression<int>? keyId,
    Expression<bool>? useCtrl,
    Expression<bool>? useAlt,
    Expression<bool>? useShift,
    Expression<bool>? useMeta,
    Expression<DateTime>? disabledAt,
    Expression<String>? category,
    Expression<int>? schemaVersion,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? updateCounter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actionName != null) 'action_name': actionName,
      if (targetPlatform != null) 'target_platform': targetPlatform,
      if (keyLabel != null) 'key_label': keyLabel,
      if (keyId != null) 'key_id': keyId,
      if (useCtrl != null) 'use_ctrl': useCtrl,
      if (useAlt != null) 'use_alt': useAlt,
      if (useShift != null) 'use_shift': useShift,
      if (useMeta != null) 'use_meta': useMeta,
      if (disabledAt != null) 'disabled_at': disabledAt,
      if (category != null) 'category': category,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (updateCounter != null) 'update_counter': updateCounter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppKeybindingsCompanion copyWith({
    Value<String>? actionName,
    Value<String>? targetPlatform,
    Value<String>? keyLabel,
    Value<int>? keyId,
    Value<bool>? useCtrl,
    Value<bool>? useAlt,
    Value<bool>? useShift,
    Value<bool>? useMeta,
    Value<DateTime?>? disabledAt,
    Value<String>? category,
    Value<int>? schemaVersion,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? updateCounter,
    Value<int>? rowid,
  }) {
    return AppKeybindingsCompanion(
      actionName: actionName ?? this.actionName,
      targetPlatform: targetPlatform ?? this.targetPlatform,
      keyLabel: keyLabel ?? this.keyLabel,
      keyId: keyId ?? this.keyId,
      useCtrl: useCtrl ?? this.useCtrl,
      useAlt: useAlt ?? this.useAlt,
      useShift: useShift ?? this.useShift,
      useMeta: useMeta ?? this.useMeta,
      disabledAt: disabledAt ?? this.disabledAt,
      category: category ?? this.category,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      updateCounter: updateCounter ?? this.updateCounter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actionName.present) {
      map['action_name'] = Variable<String>(actionName.value);
    }
    if (targetPlatform.present) {
      map['target_platform'] = Variable<String>(targetPlatform.value);
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
    if (disabledAt.present) {
      map['disabled_at'] = Variable<DateTime>(disabledAt.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (updateCounter.present) {
      map['update_counter'] = Variable<int>(updateCounter.value);
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
          ..write('targetPlatform: $targetPlatform, ')
          ..write('keyLabel: $keyLabel, ')
          ..write('keyId: $keyId, ')
          ..write('useCtrl: $useCtrl, ')
          ..write('useAlt: $useAlt, ')
          ..write('useShift: $useShift, ')
          ..write('useMeta: $useMeta, ')
          ..write('disabledAt: $disabledAt, ')
          ..write('category: $category, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updateCounter: $updateCounter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $SyncedDevicesTable syncedDevices = $SyncedDevicesTable(this);
  late final $AppKeybindingsTable appKeybindings = $AppKeybindingsTable(this);
  late final Index idxNotesUpdatedAt = Index(
    'idx_notes_updated_at',
    'CREATE INDEX idx_notes_updated_at ON notes (updated_at)',
  );
  late final Index idxNotesActive = Index(
    'idx_notes_active',
    'CREATE INDEX idx_notes_active ON notes (deleted_at, archived_at)',
  );
  late final Index idxNotesFolder = Index(
    'idx_notes_folder',
    'CREATE INDEX idx_notes_folder ON notes (folder_id)',
  );
  late final Index idxFoldersUpdatedAt = Index(
    'idx_folders_updated_at',
    'CREATE INDEX idx_folders_updated_at ON folders (updated_at)',
  );
  late final Index idxFoldersActive = Index(
    'idx_folders_active',
    'CREATE INDEX idx_folders_active ON folders (deleted_at)',
  );
  late final Index idxSyncedDevicesUpdatedAt = Index(
    'idx_synced_devices_updated_at',
    'CREATE INDEX idx_synced_devices_updated_at ON synced_devices (updated_at)',
  );
  late final Index idxSyncedDevicesDeletedAt = Index(
    'idx_synced_devices_deleted_at',
    'CREATE INDEX idx_synced_devices_deleted_at ON synced_devices (deleted_at)',
  );
  late final Index idxKeybindingsUpdatedAt = Index(
    'idx_keybindings_updated_at',
    'CREATE INDEX idx_keybindings_updated_at ON app_keybindings (updated_at)',
  );
  late final Index idxKeybindingsDeletedAt = Index(
    'idx_keybindings_deleted_at',
    'CREATE INDEX idx_keybindings_deleted_at ON app_keybindings (deleted_at)',
  );
  late final NotesDao notesDao = NotesDao(this as LocalDatabase);
  late final FoldersDao foldersDao = FoldersDao(this as LocalDatabase);
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
    folders,
    syncedDevices,
    appKeybindings,
    idxNotesUpdatedAt,
    idxNotesActive,
    idxNotesFolder,
    idxFoldersUpdatedAt,
    idxFoldersActive,
    idxSyncedDevicesUpdatedAt,
    idxSyncedDevicesDeletedAt,
    idxKeybindingsUpdatedAt,
    idxKeybindingsDeletedAt,
  ];
}

typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<String> uuid,
      required String title,
      required String content,
      Value<int> color,
      Value<int> schemaVersion,
      Value<int> contentVersion,
      Value<DateTime?> pinnedAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> lockedAt,
      Value<String?> localAttachmentPath,
      Value<String?> cloudAttachmentUrl,
      Value<String?> folderId,
      Value<String?> tags,
      Value<DateTime?> reminderAt,
      Value<String?> ownerUid,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> updateCounter,
      Value<int> cloudSyncStatus,
      Value<int> localSyncStatus,
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
      Value<int> schemaVersion,
      Value<int> contentVersion,
      Value<DateTime?> pinnedAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> lockedAt,
      Value<String?> localAttachmentPath,
      Value<String?> cloudAttachmentUrl,
      Value<String?> folderId,
      Value<String?> tags,
      Value<DateTime?> reminderAt,
      Value<String?> ownerUid,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> updateCounter,
      Value<int> cloudSyncStatus,
      Value<int> localSyncStatus,
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

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localAttachmentPath => $composableBuilder(
    column: $table.localAttachmentPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudAttachmentUrl => $composableBuilder(
    column: $table.cloudAttachmentUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
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

  ColumnFilters<String> get ownerUid => $composableBuilder(
    column: $table.ownerUid,
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

  ColumnFilters<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
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

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localAttachmentPath => $composableBuilder(
    column: $table.localAttachmentPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudAttachmentUrl => $composableBuilder(
    column: $table.cloudAttachmentUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
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

  ColumnOrderings<String> get ownerUid => $composableBuilder(
    column: $table.ownerUid,
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

  ColumnOrderings<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
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

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pinnedAt =>
      $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lockedAt =>
      $composableBuilder(column: $table.lockedAt, builder: (column) => column);

  GeneratedColumn<String> get localAttachmentPath => $composableBuilder(
    column: $table.localAttachmentPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudAttachmentUrl => $composableBuilder(
    column: $table.cloudAttachmentUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerUid =>
      $composableBuilder(column: $table.ownerUid, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cloudSyncStatus => $composableBuilder(
    column: $table.cloudSyncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localSyncStatus => $composableBuilder(
    column: $table.localSyncStatus,
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
                Value<int> schemaVersion = const Value.absent(),
                Value<int> contentVersion = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> lockedAt = const Value.absent(),
                Value<String?> localAttachmentPath = const Value.absent(),
                Value<String?> cloudAttachmentUrl = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<String?> ownerUid = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> updateCounter = const Value.absent(),
                Value<int> cloudSyncStatus = const Value.absent(),
                Value<int> localSyncStatus = const Value.absent(),
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
                schemaVersion: schemaVersion,
                contentVersion: contentVersion,
                pinnedAt: pinnedAt,
                archivedAt: archivedAt,
                lockedAt: lockedAt,
                localAttachmentPath: localAttachmentPath,
                cloudAttachmentUrl: cloudAttachmentUrl,
                folderId: folderId,
                tags: tags,
                reminderAt: reminderAt,
                ownerUid: ownerUid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                updateCounter: updateCounter,
                cloudSyncStatus: cloudSyncStatus,
                localSyncStatus: localSyncStatus,
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
                Value<int> schemaVersion = const Value.absent(),
                Value<int> contentVersion = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> lockedAt = const Value.absent(),
                Value<String?> localAttachmentPath = const Value.absent(),
                Value<String?> cloudAttachmentUrl = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<String?> ownerUid = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> updateCounter = const Value.absent(),
                Value<int> cloudSyncStatus = const Value.absent(),
                Value<int> localSyncStatus = const Value.absent(),
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
                schemaVersion: schemaVersion,
                contentVersion: contentVersion,
                pinnedAt: pinnedAt,
                archivedAt: archivedAt,
                lockedAt: lockedAt,
                localAttachmentPath: localAttachmentPath,
                cloudAttachmentUrl: cloudAttachmentUrl,
                folderId: folderId,
                tags: tags,
                reminderAt: reminderAt,
                ownerUid: ownerUid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                updateCounter: updateCounter,
                cloudSyncStatus: cloudSyncStatus,
                localSyncStatus: localSyncStatus,
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
typedef $$FoldersTableCreateCompanionBuilder =
    FoldersCompanion Function({
      Value<String> uuid,
      required String name,
      Value<int> colorIndex,
      Value<String?> ownerUid,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> pinnedAt,
      Value<int> updateCounter,
      Value<int> cloudSyncStatus,
      Value<int> localSyncStatus,
      Value<String?> creationPlatform,
      Value<String?> creationDevice,
      Value<String?> lastEditedPlatform,
      Value<String?> lastEditedDevice,
      Value<String?> deletedPlatform,
      Value<String?> deletedDevice,
      Value<int> rowid,
    });
typedef $$FoldersTableUpdateCompanionBuilder =
    FoldersCompanion Function({
      Value<String> uuid,
      Value<String> name,
      Value<int> colorIndex,
      Value<String?> ownerUid,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> pinnedAt,
      Value<int> updateCounter,
      Value<int> cloudSyncStatus,
      Value<int> localSyncStatus,
      Value<String?> creationPlatform,
      Value<String?> creationDevice,
      Value<String?> lastEditedPlatform,
      Value<String?> lastEditedDevice,
      Value<String?> deletedPlatform,
      Value<String?> deletedDevice,
      Value<int> rowid,
    });

class $$FoldersTableFilterComposer
    extends Composer<_$LocalDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUid => $composableBuilder(
    column: $table.ownerUid,
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

  ColumnFilters<DateTime> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
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

class $$FoldersTableOrderingComposer
    extends Composer<_$LocalDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUid => $composableBuilder(
    column: $table.ownerUid,
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

  ColumnOrderings<DateTime> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
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

class $$FoldersTableAnnotationComposer
    extends Composer<_$LocalDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerUid =>
      $composableBuilder(column: $table.ownerUid, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get pinnedAt =>
      $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cloudSyncStatus => $composableBuilder(
    column: $table.cloudSyncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localSyncStatus => $composableBuilder(
    column: $table.localSyncStatus,
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

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, BaseReferences<_$LocalDatabase, $FoldersTable, Folder>),
          Folder,
          PrefetchHooks Function()
        > {
  $$FoldersTableTableManager(_$LocalDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<String?> ownerUid = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<int> updateCounter = const Value.absent(),
                Value<int> cloudSyncStatus = const Value.absent(),
                Value<int> localSyncStatus = const Value.absent(),
                Value<String?> creationPlatform = const Value.absent(),
                Value<String?> creationDevice = const Value.absent(),
                Value<String?> lastEditedPlatform = const Value.absent(),
                Value<String?> lastEditedDevice = const Value.absent(),
                Value<String?> deletedPlatform = const Value.absent(),
                Value<String?> deletedDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion(
                uuid: uuid,
                name: name,
                colorIndex: colorIndex,
                ownerUid: ownerUid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pinnedAt: pinnedAt,
                updateCounter: updateCounter,
                cloudSyncStatus: cloudSyncStatus,
                localSyncStatus: localSyncStatus,
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
                required String name,
                Value<int> colorIndex = const Value.absent(),
                Value<String?> ownerUid = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<int> updateCounter = const Value.absent(),
                Value<int> cloudSyncStatus = const Value.absent(),
                Value<int> localSyncStatus = const Value.absent(),
                Value<String?> creationPlatform = const Value.absent(),
                Value<String?> creationDevice = const Value.absent(),
                Value<String?> lastEditedPlatform = const Value.absent(),
                Value<String?> lastEditedDevice = const Value.absent(),
                Value<String?> deletedPlatform = const Value.absent(),
                Value<String?> deletedDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion.insert(
                uuid: uuid,
                name: name,
                colorIndex: colorIndex,
                ownerUid: ownerUid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pinnedAt: pinnedAt,
                updateCounter: updateCounter,
                cloudSyncStatus: cloudSyncStatus,
                localSyncStatus: localSyncStatus,
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

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, BaseReferences<_$LocalDatabase, $FoldersTable, Folder>),
      Folder,
      PrefetchHooks Function()
    >;
typedef $$SyncedDevicesTableCreateCompanionBuilder =
    SyncedDevicesCompanion Function({
      required String deviceUuid,
      required String deviceName,
      Value<String?> customAlias,
      Value<String?> lastKnownIp,
      Value<int?> lastKnownPort,
      Value<DateTime?> lastSeenAsHostAt,
      Value<DateTime?> lastSeenAsClientAt,
      Value<DateTime> firstPairedAt,
      Value<DateTime?> blockedAt,
      Value<String?> publicKey,
      Value<String?> authKey,
      Value<int> schemaVersion,
      Value<String?> deviceType,
      Value<int?> protocolVersion,
      Value<DateTime?> lastSuccessfulSyncAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> updateCounter,
      Value<int> rowid,
    });
typedef $$SyncedDevicesTableUpdateCompanionBuilder =
    SyncedDevicesCompanion Function({
      Value<String> deviceUuid,
      Value<String> deviceName,
      Value<String?> customAlias,
      Value<String?> lastKnownIp,
      Value<int?> lastKnownPort,
      Value<DateTime?> lastSeenAsHostAt,
      Value<DateTime?> lastSeenAsClientAt,
      Value<DateTime> firstPairedAt,
      Value<DateTime?> blockedAt,
      Value<String?> publicKey,
      Value<String?> authKey,
      Value<int> schemaVersion,
      Value<String?> deviceType,
      Value<int?> protocolVersion,
      Value<DateTime?> lastSuccessfulSyncAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> updateCounter,
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

  ColumnFilters<String> get customAlias => $composableBuilder(
    column: $table.customAlias,
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

  ColumnFilters<DateTime> get blockedAt => $composableBuilder(
    column: $table.blockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authKey => $composableBuilder(
    column: $table.authKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
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

  ColumnFilters<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
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

  ColumnOrderings<String> get customAlias => $composableBuilder(
    column: $table.customAlias,
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

  ColumnOrderings<DateTime> get blockedAt => $composableBuilder(
    column: $table.blockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authKey => $composableBuilder(
    column: $table.authKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
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

  ColumnOrderings<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
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

  GeneratedColumn<String> get customAlias => $composableBuilder(
    column: $table.customAlias,
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

  GeneratedColumn<DateTime> get blockedAt =>
      $composableBuilder(column: $table.blockedAt, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get authKey =>
      $composableBuilder(column: $table.authKey, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
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
                Value<String?> customAlias = const Value.absent(),
                Value<String?> lastKnownIp = const Value.absent(),
                Value<int?> lastKnownPort = const Value.absent(),
                Value<DateTime?> lastSeenAsHostAt = const Value.absent(),
                Value<DateTime?> lastSeenAsClientAt = const Value.absent(),
                Value<DateTime> firstPairedAt = const Value.absent(),
                Value<DateTime?> blockedAt = const Value.absent(),
                Value<String?> publicKey = const Value.absent(),
                Value<String?> authKey = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String?> deviceType = const Value.absent(),
                Value<int?> protocolVersion = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> updateCounter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedDevicesCompanion(
                deviceUuid: deviceUuid,
                deviceName: deviceName,
                customAlias: customAlias,
                lastKnownIp: lastKnownIp,
                lastKnownPort: lastKnownPort,
                lastSeenAsHostAt: lastSeenAsHostAt,
                lastSeenAsClientAt: lastSeenAsClientAt,
                firstPairedAt: firstPairedAt,
                blockedAt: blockedAt,
                publicKey: publicKey,
                authKey: authKey,
                schemaVersion: schemaVersion,
                deviceType: deviceType,
                protocolVersion: protocolVersion,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                updateCounter: updateCounter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceUuid,
                required String deviceName,
                Value<String?> customAlias = const Value.absent(),
                Value<String?> lastKnownIp = const Value.absent(),
                Value<int?> lastKnownPort = const Value.absent(),
                Value<DateTime?> lastSeenAsHostAt = const Value.absent(),
                Value<DateTime?> lastSeenAsClientAt = const Value.absent(),
                Value<DateTime> firstPairedAt = const Value.absent(),
                Value<DateTime?> blockedAt = const Value.absent(),
                Value<String?> publicKey = const Value.absent(),
                Value<String?> authKey = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String?> deviceType = const Value.absent(),
                Value<int?> protocolVersion = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> updateCounter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedDevicesCompanion.insert(
                deviceUuid: deviceUuid,
                deviceName: deviceName,
                customAlias: customAlias,
                lastKnownIp: lastKnownIp,
                lastKnownPort: lastKnownPort,
                lastSeenAsHostAt: lastSeenAsHostAt,
                lastSeenAsClientAt: lastSeenAsClientAt,
                firstPairedAt: firstPairedAt,
                blockedAt: blockedAt,
                publicKey: publicKey,
                authKey: authKey,
                schemaVersion: schemaVersion,
                deviceType: deviceType,
                protocolVersion: protocolVersion,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                updateCounter: updateCounter,
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
      Value<String> targetPlatform,
      required String keyLabel,
      required int keyId,
      Value<bool> useCtrl,
      Value<bool> useAlt,
      Value<bool> useShift,
      Value<bool> useMeta,
      Value<DateTime?> disabledAt,
      Value<String> category,
      Value<int> schemaVersion,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> updateCounter,
      Value<int> rowid,
    });
typedef $$AppKeybindingsTableUpdateCompanionBuilder =
    AppKeybindingsCompanion Function({
      Value<String> actionName,
      Value<String> targetPlatform,
      Value<String> keyLabel,
      Value<int> keyId,
      Value<bool> useCtrl,
      Value<bool> useAlt,
      Value<bool> useShift,
      Value<bool> useMeta,
      Value<DateTime?> disabledAt,
      Value<String> category,
      Value<int> schemaVersion,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> updateCounter,
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

  ColumnFilters<String> get targetPlatform => $composableBuilder(
    column: $table.targetPlatform,
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

  ColumnFilters<DateTime> get disabledAt => $composableBuilder(
    column: $table.disabledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
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

  ColumnFilters<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
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

  ColumnOrderings<String> get targetPlatform => $composableBuilder(
    column: $table.targetPlatform,
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

  ColumnOrderings<DateTime> get disabledAt => $composableBuilder(
    column: $table.disabledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
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

  ColumnOrderings<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
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

  GeneratedColumn<String> get targetPlatform => $composableBuilder(
    column: $table.targetPlatform,
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

  GeneratedColumn<DateTime> get disabledAt => $composableBuilder(
    column: $table.disabledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get updateCounter => $composableBuilder(
    column: $table.updateCounter,
    builder: (column) => column,
  );
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
                Value<String> targetPlatform = const Value.absent(),
                Value<String> keyLabel = const Value.absent(),
                Value<int> keyId = const Value.absent(),
                Value<bool> useCtrl = const Value.absent(),
                Value<bool> useAlt = const Value.absent(),
                Value<bool> useShift = const Value.absent(),
                Value<bool> useMeta = const Value.absent(),
                Value<DateTime?> disabledAt = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> updateCounter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppKeybindingsCompanion(
                actionName: actionName,
                targetPlatform: targetPlatform,
                keyLabel: keyLabel,
                keyId: keyId,
                useCtrl: useCtrl,
                useAlt: useAlt,
                useShift: useShift,
                useMeta: useMeta,
                disabledAt: disabledAt,
                category: category,
                schemaVersion: schemaVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                updateCounter: updateCounter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String actionName,
                Value<String> targetPlatform = const Value.absent(),
                required String keyLabel,
                required int keyId,
                Value<bool> useCtrl = const Value.absent(),
                Value<bool> useAlt = const Value.absent(),
                Value<bool> useShift = const Value.absent(),
                Value<bool> useMeta = const Value.absent(),
                Value<DateTime?> disabledAt = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> updateCounter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppKeybindingsCompanion.insert(
                actionName: actionName,
                targetPlatform: targetPlatform,
                keyLabel: keyLabel,
                keyId: keyId,
                useCtrl: useCtrl,
                useAlt: useAlt,
                useShift: useShift,
                useMeta: useMeta,
                disabledAt: disabledAt,
                category: category,
                schemaVersion: schemaVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                updateCounter: updateCounter,
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
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$SyncedDevicesTableTableManager get syncedDevices =>
      $$SyncedDevicesTableTableManager(_db, _db.syncedDevices);
  $$AppKeybindingsTableTableManager get appKeybindings =>
      $$AppKeybindingsTableTableManager(_db, _db.appKeybindings);
}
