import 'package:flutter/foundation.dart';

/// Data model representing a distinct user profile workspace in NoteIt.
@immutable
class Profile {
  /// Unique profile identifier (e.g. 'profile_default', 'profile_1718000000').
  final String id;

  /// Primary profile workspace name (e.g. 'Personal Notes', 'Work Projects').
  final String name;

  /// SQLite database filename on disk (e.g. 'note_it_db.sqlite', 'profile_work_1718.sqlite').
  final String dbFileName;

  /// Default sync mode for this profile ('offline', 'cloud', 'localHost', 'localClient').
  final String syncMode;

  /// Creation timestamp (UTC).
  final DateTime createdAt;

  /// Last active timestamp (UTC), used for sorting recently used profiles.
  final DateTime lastUsedAt;

  /// Soft-delete timestamp (UTC) for profile trash recovery (null if active).
  final DateTime? deletedAt;

  /// Conflict resolution update counter.
  final int updateCounter;

  /// Hybrid Logical Clock (HLC) string checkpoint.
  final String? hlc;

  const Profile({
    required this.id,
    required this.name,
    required this.dbFileName,
    this.syncMode = 'offline',
    required this.createdAt,
    required this.lastUsedAt,
    this.deletedAt,
    this.updateCounter = 1,
    this.hlc,
  });

  /// Serializes [Profile] to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dbFileName': dbFileName,
      'syncMode': syncMode,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'lastUsedAt': lastUsedAt.toUtc().toIso8601String(),
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
      'updateCounter': updateCounter,
      'hlc': hlc,
    };
  }

  /// Deserializes a JSON Map into a [Profile] instance.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      dbFileName: json['dbFileName'] as String? ?? 'note_it_db.sqlite',
      syncMode: json['syncMode'] as String? ?? 'offline',
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
    );
  }

  /// Creates a copy of this [Profile] with updated fields.
  Profile copyWith({
    String? id,
    String? name,
    String? dbFileName,
    String? syncMode,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    Object? deletedAt = _undefined,
    int? updateCounter,
    Object? hlc = _undefined,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      dbFileName: dbFileName ?? this.dbFileName,
      syncMode: syncMode ?? this.syncMode,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      deletedAt: deletedAt == _undefined ? this.deletedAt : deletedAt as DateTime?,
      updateCounter: updateCounter ?? this.updateCounter,
      hlc: hlc == _undefined ? this.hlc : hlc as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile &&
        other.id == id &&
        other.name == name &&
        other.dbFileName == dbFileName &&
        other.syncMode == syncMode &&
        other.createdAt == createdAt &&
        other.lastUsedAt == lastUsedAt &&
        other.deletedAt == deletedAt &&
        other.updateCounter == updateCounter &&
        other.hlc == hlc;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        dbFileName,
        syncMode,
        createdAt,
        lastUsedAt,
        deletedAt,
        updateCounter,
        hlc,
      );
}

const Object _undefined = Object();
