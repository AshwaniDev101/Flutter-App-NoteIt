import 'package:flutter/foundation.dart';

/// Data model representing a distinct user profile workspace in NoteIt.
@immutable
class Profile {
  /// Unique profile identifier (e.g. 'profile_default', 'profile_1718000000').
  final String id;

  /// Primary display name (e.g. 'Personal Notes', 'Work Projects').
  final String name;

  /// Optional subtitle or custom alias (e.g. 'Daily Journal', 'Company X').
  final String? customAlias;

  /// ARGB integer color used for avatar badges and UI accent tint (e.g. 0xFF2196F3).
  final int colorValue;

  /// Icon identifier string (e.g. 'person', 'work', 'code', 'book', 'folder').
  final String iconName;

  /// SQLite database filename on disk (e.g. 'note_it_db.sqlite', 'profile_work_1718.sqlite').
  final String dbFileName;

  /// Optional linked Google Account email string for Cloud Sync authentication.
  final String? linkedEmail;

  /// Default sync mode for this profile ('offline', 'cloud', 'localHost', 'localClient').
  final String syncMode;

  /// Whether this is the primary default profile created on first launch.
  final bool isDefault;

  /// Creation timestamp (UTC).
  final DateTime createdAt;

  /// Last active timestamp (UTC), used for sorting recently used profiles.
  final DateTime lastUsedAt;

  const Profile({
    required this.id,
    required this.name,
    this.customAlias,
    required this.colorValue,
    required this.iconName,
    required this.dbFileName,
    this.linkedEmail,
    this.syncMode = 'offline',
    this.isDefault = false,
    required this.createdAt,
    required this.lastUsedAt,
  });

  /// Serializes [Profile] to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'customAlias': customAlias,
      'colorValue': colorValue,
      'iconName': iconName,
      'dbFileName': dbFileName,
      'linkedEmail': linkedEmail,
      'syncMode': syncMode,
      'isDefault': isDefault,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'lastUsedAt': lastUsedAt.toUtc().toIso8601String(),
    };
  }

  /// Deserializes a JSON Map into a [Profile] instance.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      customAlias: json['customAlias'] as String?,
      colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
      iconName: json['iconName'] as String? ?? 'person',
      dbFileName: json['dbFileName'] as String? ?? 'note_it_db.sqlite',
      linkedEmail: json['linkedEmail'] as String?,
      syncMode: json['syncMode'] as String? ?? 'offline',
      isDefault: json['isDefault'] as bool? ?? false,
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
    String? customAlias,
    int? colorValue,
    String? iconName,
    String? dbFileName,
    String? linkedEmail,
    String? syncMode,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      customAlias: customAlias ?? this.customAlias,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      dbFileName: dbFileName ?? this.dbFileName,
      linkedEmail: linkedEmail ?? this.linkedEmail,
      syncMode: syncMode ?? this.syncMode,
      isDefault: isDefault ?? this.isDefault,
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
        other.customAlias == customAlias &&
        other.colorValue == colorValue &&
        other.iconName == iconName &&
        other.dbFileName == dbFileName &&
        other.linkedEmail == linkedEmail &&
        other.syncMode == syncMode &&
        other.isDefault == isDefault &&
        other.createdAt == createdAt &&
        other.lastUsedAt == lastUsedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        customAlias,
        colorValue,
        iconName,
        dbFileName,
        linkedEmail,
        syncMode,
        isDefault,
        createdAt,
        lastUsedAt,
      );
}
