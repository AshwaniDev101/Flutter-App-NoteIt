class NoteModel {

  static const String keyId = 'id';
  static const String keyTitle = 'title';
  static const String keyContent = 'content';
  static const String keyColor = 'color';
  static const String keyIsPinned = 'isPinned';
  static const String keyIsArchived = 'isArchived';
  static const String keyIsDeleted = 'isDeleted';
  static const String keyIsLocked = 'isLocked';
  static const String keyPosition = 'position';
  static const String keyTags = 'tags';
  static const String keyReminderAt = 'reminderAt';
  static const String keyCreatedAt = 'createdAt';
  static const String keyUpdatedAt = 'updatedAt';

  final String id;
  final String title;
  final String content;
  final int color;
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted;
  final bool isLocked;
  final int position;
  final String? tags;
  final DateTime? reminderAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.color = 0xFFFFFFFF,
    this.isPinned = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.isLocked = false,
    this.position = 0,
    this.tags,
    this.reminderAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory NoteModel.empty() {
    final now = DateTime.now();

    return NoteModel(
      id: now.millisecondsSinceEpoch.toString(),
      title: '',
      content: '',
      createdAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      keyId: id,
      keyTitle: title,
      keyContent: content,
      keyColor: color,
      keyIsPinned: isPinned,
      keyIsArchived: isArchived,
      keyIsDeleted: isDeleted,
      keyIsLocked: isLocked,
      keyPosition: position,
      keyTags: tags,
      keyReminderAt: reminderAt?.toIso8601String(),
      keyCreatedAt: createdAt.toIso8601String(),
      keyUpdatedAt: updatedAt?.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map[keyId],
      title: map[keyTitle] ?? '',
      content: map[keyContent] ?? '',
      color: map[keyColor] ?? 0xFFFFFFFF,
      isPinned: map[keyIsPinned] ?? false,
      isArchived: map[keyIsArchived] ?? false,
      isDeleted: map[keyIsDeleted] ?? false,
      isLocked: map[keyIsLocked] ?? false,
      position: map[keyPosition] ?? 0,
      tags: map[keyTags],
      reminderAt: map[keyReminderAt] != null
          ? DateTime.parse(map[keyReminderAt])
          : null,
      createdAt: DateTime.parse(map[keyCreatedAt]),
      updatedAt: map[keyUpdatedAt] != null
          ? DateTime.parse(map[keyUpdatedAt])
          : null,
    );
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    int? color,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    bool? isLocked,
    int? position,
    String? tags,
    DateTime? reminderAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      isLocked: isLocked ?? this.isLocked,
      position: position ?? this.position,
      tags: tags ?? this.tags,
      reminderAt: reminderAt ?? this.reminderAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}