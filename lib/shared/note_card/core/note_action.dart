import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Represents any action that can be performed on or within a note
/// across list context menus and the note editor.
enum NoteAction {
  // Common
  select('Select', Icons.check_circle_outline),
  pin('Pin', Icons.push_pin_outlined),
  unpin('Unpin', CupertinoIcons.pin_slash),
  lock('Lock', Icons.lock_outline),
  unlock('Unlock', Icons.lock_open_outlined),
  reminder('Remind me', Icons.notifications_none_outlined),
  moveTo('Move to...', Icons.drive_file_move_outlined),
  duplicate('Duplicate', Icons.copy_outlined),

  // Filing
  archive('Archive', Icons.archive_outlined),
  unarchive('Unarchive', Icons.unarchive_outlined),

  // Destructive
  restore('Restore', Icons.restore),
  delete('Delete', Icons.delete_outline, isDestructive: true),
  deleteForever('Delete Forever', Icons.delete_forever, isDestructive: true),

  // Editor-specific
  info('Details', Icons.info_outline),
  checklist('Checklist', Icons.check_box_outlined),
  find('Find', Icons.search_outlined);

  final String label;
  final IconData icon;
  final bool isDestructive;

  const NoteAction(this.label, this.icon, {this.isDestructive = false});
}

/// Dynamic UI appearance record for editor grid buttons and context menu options.
typedef OptionAppearance = ({String label, IconData icon, String tooltip, bool isActive});

/// Extension providing contextual label, icon, and active status based on note state.
extension NoteActionUI on NoteAction {
  OptionAppearance getAppearance({
    bool isLocked = false,
    bool isPinned = false,
    bool isChecklist = false,
    bool hasReminder = false,
  }) {
    switch (this) {
      case NoteAction.lock:
        return (
          label: isLocked ? 'Unlock' : 'Lock',
          icon: isLocked ? Icons.lock_open_outlined : Icons.lock_outline,
          tooltip: isLocked ? 'Remove Lock' : 'Lock Note',
          isActive: isLocked,
        );
      case NoteAction.pin:
        return (
          label: isPinned ? 'Unpin' : 'Pin',
          icon: isPinned ? CupertinoIcons.pin_slash : Icons.push_pin_outlined,
          tooltip: isPinned ? 'Unpin Note' : 'Pin Note',
          isActive: isPinned,
        );
      case NoteAction.checklist:
        return (
          label: isChecklist ? 'Plain-text' : 'Checklist',
          icon: isChecklist ? Icons.notes : Icons.check_box_outlined,
          tooltip: isChecklist ? 'Convert to Plain-text' : 'Turn to Checklist',
          isActive: isChecklist,
        );
      case NoteAction.reminder:
        return (
          label: hasReminder ? 'Clean Reminder' : 'Set Reminder',
          icon: hasReminder ? Icons.notifications_off_outlined : Icons.notifications_none_outlined,
          tooltip: hasReminder ? 'Clean Reminder' : 'Set Reminder',
          isActive: hasReminder,
        );
      case NoteAction.delete:
        return (label: 'Delete', icon: Icons.delete_outline, tooltip: 'Delete Note', isActive: false);
      case NoteAction.archive:
        return (label: 'Archive', icon: Icons.archive_outlined, tooltip: 'Archive Note', isActive: false);
      case NoteAction.info:
        return (label: 'Details', icon: Icons.info_outline, tooltip: 'Note Meta Data', isActive: false);
      case NoteAction.find:
        return (label: 'Find', icon: Icons.search_outlined, tooltip: 'Find in Note', isActive: false);
      default:
        return (label: label, icon: icon, tooltip: label, isActive: false);
    }
  }
}
