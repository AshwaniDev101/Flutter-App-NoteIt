class NoteModel {
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
      'id': id,
      'title': title,
      'content': content,
      'color': color,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'isLocked': isLocked,
      'position': position,
      'tags': tags,
      'reminderAt': reminderAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],

      title: map['title'] ?? '',

      content: map['content'] ?? '',

      color: map['color'] ?? 0xFFFFFFFF,

      isPinned: map['isPinned'] ?? false,

      isArchived: map['isArchived'] ?? false,

      isDeleted: map['isDeleted'] ?? false,

      isLocked: map['isLocked'] ?? false,

      position: map['position'] ?? 0,

      tags: map['tags'],

      reminderAt: map['reminderAt'] != null
          ? DateTime.parse(map['reminderAt'])
          : null,

      createdAt: DateTime.parse(map['createdAt']),

      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
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