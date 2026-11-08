import 'package:flutter/foundation.dart';

/// Data model representing a distinct user profile workspace in NoteIt.
@immutable
class Profile {
  /// Unique profile identifier (e.g. 'profile_default', 'profile_1718000000').
  final String id;

  /// Primary profile workspace name (e.g. 'Personal Notes', 'Work Projects').
  final String name;

  /// Optional Google account display name (e.g. 'John Doe').
  final String? displayName;

  /// Optional Google account profile photo URL.
  final String? photoUrl;

  /// SQLite database filename on disk (e.g. 'note_it_db.sqlite', 'profile_work_1718.sqlite').
  final String dbFileName;

  /// Optional linked Google Account email string for Cloud Sync authentication.
  final String? linkedEmail;

  /// Default sync mode for this profile ('offline', 'cloud', 'localHost', 'localClient').
  final String syncMode;

  /// Creation timestamp (UTC).
  final DateTime createdAt;

  /// Last active timestamp (UTC), used for sorting recently used profiles.
  final DateTime lastUsedAt;

  const Profile({
    required this.id,
    required this.name,
    this.displayName,
    this.photoUrl,
    required this.dbFileName,
    this.linkedEmail,
    this.syncMode = 'offline',
    required this.createdAt,
    required this.lastUsedAt,
  });

  /// Serializes [Profile] to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'dbFileName': dbFileName,
      'linkedEmail': linkedEmail,
      'syncMode': syncMode,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'lastUsedAt': lastUsedAt.toUtc().toIso8601String(),
    };
  }

  /// Deserializes a JSON Map into a [Profile] instance.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      dbFileName: json['dbFileName'] as String? ?? 'note_it_db.sqlite',
      linkedEmail: json['linkedEmail'] as String?,
      syncMode: json['syncMode'] as String? ?? 'offline',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toUtc()
          : DateTime.now().toUtc(),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String).toUtc()
          : DateTime.now().toUtc(),
    );
  }

  /// Creates a copy of this [Profile] with updated fields.
  Profile copyWith({
    String? id,
    String? name,
    Object? displayName = _undefined,
    Object? photoUrl = _undefined,
    String? dbFileName,
    Object? linkedEmail = _undefined,
    String? syncMode,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName == _undefined ? this.displayName : displayName as String?,
      photoUrl: photoUrl == _undefined ? this.photoUrl : photoUrl as String?,
      dbFileName: dbFileName ?? this.dbFileName,
      linkedEmail: linkedEmail == _undefined ? this.linkedEmail : linkedEmail as String?,
      syncMode: syncMode ?? this.syncMode,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile &&
        other.id == id &&
        other.name == name &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.dbFileName == dbFileName &&
        other.linkedEmail == linkedEmail &&
        other.syncMode == syncMode &&
        other.createdAt == createdAt &&
        other.lastUsedAt == lastUsedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        displayName,
        photoUrl,
        dbFileName,
        linkedEmail,
        syncMode,
        createdAt,
        lastUsedAt,
      );
}

const Object _undefined = Object();
