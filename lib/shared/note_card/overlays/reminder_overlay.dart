import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/features/reminder/reminder_manager.dart';

import '../../../../features/lock/lock_manger/lock_manager.dart';

class ReminderOverlayWidget extends ConsumerWidget {
  final NoteWithFolder noteWithFolder;

  const ReminderOverlayWidget({super.key, required this.noteWithFolder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = noteWithFolder.note;
    final reminderAt = note.reminderAt;

    // If no reminder is set, render nothing
    if (reminderAt == null) return const SizedBox.shrink();

    final repeatMode = note.reminderRepeatMode;
    final isRepeating = repeatMode == 'daily' || repeatMode == 'customDays';
    final isPast = reminderAt.isBefore(DateTime.now());

    // Hide one-time reminders that have already passed
    if (isPast && !isRepeating) return const SizedBox.shrink();

    // If note is locked and session is NOT unlocked, hide reminder overlay
    if (note.lockedAt != null) {
      final isSessionUnlocked = ref.watch(
        lockManagerProvider.select((state) => state.sessionUnlockedNoteIds.contains(note.uuid)),
      );
      if (!isSessionUnlocked) return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String formattedDate = ReminderManager.formatReminderLabel(
      reminderAt,
      repeatMode,
      note.reminderCustomDays,
    );

    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isPast
              ? colorScheme.errorContainer.withValues(alpha: 0.9)
              : colorScheme.secondaryContainer.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPast
                ? colorScheme.error.withValues(alpha: 0.5)
                : colorScheme.secondary.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRepeating
                  ? Icons.repeat_rounded
                  : (isPast ? Icons.notification_important_rounded : Icons.notifications_active_rounded),
              size: 11,
              color: isPast
                  ? colorScheme.onErrorContainer
                  : colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              formattedDate,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isPast
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
