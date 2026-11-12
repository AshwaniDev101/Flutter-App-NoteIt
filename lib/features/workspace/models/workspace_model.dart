import 'package:flutter/foundation.dart';

/// Data model representing a distinct user workspace in NoteIt.
@immutable
class Workspace {
  /// Unique workspace identifier (e.g. 'profile_default', 'workspace_1718000000').
  final String id;

  /// Primary workspace name (e.g. 'Personal Notes', 'Work Projects').
  final String name;

  /// SQLite database filename on disk (e.g. 'note_it_db.sqlite', 'workspace_work_1718.sqlite').
  final String dbFileName;

  /// Creation timestamp (UTC).
  final DateTime createdAt;

  /// Last active timestamp (UTC), used for sorting recently used workspaces.
  final DateTime lastUsedAt;

  /// Soft-delete timestamp (UTC) for workspace trash recovery (null if active).
  final DateTime? deletedAt;

  /// Conflict resolution update counter.
  final int updateCounter;

  /// Hybrid Logical Clock (HLC) string checkpoint.
  final String? hlc;

  /// True if this workspace metadata has been synced to Firebase cloud.
  final bool isCloudSynced;

  const Workspace({
    required this.id,
    required this.name,
    required this.dbFileName,
    required this.createdAt,
    required this.lastUsedAt,
    this.deletedAt,
    this.updateCounter = 1,
    this.hlc,
    this.isCloudSynced = false,
  });

  /// Serializes [Workspace] to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dbFileName': dbFileName,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'lastUsedAt': lastUsedAt.toUtc().toIso8601String(),
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
      'updateCounter': updateCounter,
      'hlc': hlc,
      'isCloudSynced': isCloudSynced,
    };
  }

  /// Deserializes a JSON Map into a [Workspace] instance.
  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      dbFileName: json['dbFileName'] as String? ?? 'note_it_db.sqlite',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toUtc()
          : DateTime.now().toUtc(),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String).toUtc()
          : DateTime.now().toUtc(),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String).toUtc()
          : null,
      updateCounter: json['updateCounter'] as int? ?? 1,
      hlc: json['hlc'] as String?,
      isCloudSynced: json['isCloudSynced'] as bool? ?? false,
    );
  }

  /// Creates a copy of this [Workspace] with updated fields.
  Workspace copyWith({
    String? id,
    String? name,
    String? dbFileName,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    Object? deletedAt = _undefined,
    int? updateCounter,
    Object? hlc = _undefined,
    bool? isCloudSynced,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      dbFileName: dbFileName ?? this.dbFileName,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      deletedAt: deletedAt == _undefined ? this.deletedAt : deletedAt as DateTime?,
      updateCounter: updateCounter ?? this.updateCounter,
      hlc: hlc == _undefined ? this.hlc : hlc as String?,
      isCloudSynced: isCloudSynced ?? this.isCloudSynced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workspace &&
        other.id == id &&
        other.name == name &&
        other.dbFileName == dbFileName &&
        other.createdAt == createdAt &&
        other.lastUsedAt == lastUsedAt &&
        other.deletedAt == deletedAt &&
        other.updateCounter == updateCounter &&
        other.hlc == hlc &&
        other.isCloudSynced == isCloudSynced;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        dbFileName,
        createdAt,
        lastUsedAt,
        deletedAt,
        updateCounter,
        hlc,
        isCloudSynced,
      );
}

const Object _undefined = Object();
