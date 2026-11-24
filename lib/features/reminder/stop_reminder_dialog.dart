import 'package:flutter/material.dart';
import '../../core/helpers/time_helper.dart';
import '../../shared/overlays/snack_bar_manager.dart';
import 'reminder_manager.dart';

class StopReminderDialog extends StatefulWidget {
  final ActiveReminderInfo reminderInfo;

  const StopReminderDialog({
    super.key,
    required this.reminderInfo,
  });

  static Future<void> show(BuildContext context, ActiveReminderInfo reminderInfo) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StopReminderDialog(reminderInfo: reminderInfo);
      },
    );
  }

  @override
  State<StopReminderDialog> createState() => _StopReminderDialogState();
}

class _StopReminderDialogState extends State<StopReminderDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  late Animation<double> _bellAnimation;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _bellAnimation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  void _onStopPressed() {
    ReminderManager().stopAlarmSound();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _onOpenNotePressed() {
    final uuid = widget.reminderInfo.noteUuid;
    ReminderManager().stopAlarmSound();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    ReminderManager().openNoteFromReminder(uuid);
  }

  Future<void> _onSnoozePressed(Duration duration, String label) async {
    final uuid = widget.reminderInfo.noteUuid;
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    await ReminderManager().snoozeReminder(uuid, duration);
    SnackBarManager.show(
      msg: 'Reminder snoozed for $label',
      type: SnackBarMessageType.acknowledgment,
    );
  }

  Future<void> _onClearPressed() async {
    final uuid = widget.reminderInfo.noteUuid;
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    await ReminderManager().clearReminderForNote(uuid);
    SnackBarManager.show(
      msg: 'Reminder cleared',
      type: SnackBarMessageType.acknowledgment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final noteTitle = widget.reminderInfo.title.isNotEmpty
        ? widget.reminderInfo.title
        : 'Untitled Note';
    final contentPreview = widget.reminderInfo.contentSnippet.trim();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 12,
      backgroundColor: colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flashing / Ringing Bell Header Icon
              AnimatedBuilder(
                animation: _bellAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _bellAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 38,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Note Title
              Text(
                noteTitle,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Triggered at ${TimeHelper.format12HourTime(widget.reminderInfo.triggerTime)}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Note Content Preview Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: widget.reminderInfo.isLocked
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'This note is locked',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        contentPreview.isNotEmpty
                            ? contentPreview
                            : 'No preview content available',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: contentPreview.isEmpty ? FontStyle.italic : FontStyle.normal,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(height: 20),

              // Snooze Row Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Snooze Options',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Snooze Option Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _SnoozeChip(
                    label: '5m',
                    onTap: () => _onSnoozePressed(const Duration(minutes: 5), '5 minutes'),
                  ),
                  _SnoozeChip(
                    label: '15m',
                    onTap: () => _onSnoozePressed(const Duration(minutes: 15), '15 minutes'),
                  ),
                  _SnoozeChip(
                    label: '30m',
                    onTap: () => _onSnoozePressed(const Duration(minutes: 30), '30 minutes'),
                  ),
                  _SnoozeChip(
                    label: '1h',
                    onTap: () => _onSnoozePressed(const Duration(hours: 1), '1 hour'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons Row: Clear (if repeating), Stop Reminder & Open Note
              if (widget.reminderInfo.isRepeating) ...[
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _onClearPressed,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _onStopPressed,
                        icon: const Icon(Icons.alarm_off_rounded, size: 20),
                        label: const Text('Stop Reminder'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _onOpenNotePressed,
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text('Open Note'),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _onStopPressed,
                        icon: const Icon(Icons.alarm_off_rounded, size: 20),
                        label: const Text('Stop Reminder'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _onOpenNotePressed,
                        icon: const Icon(Icons.edit_note_rounded, size: 20),
                        label: const Text('Open Note'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SnoozeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SnoozeChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(
        Icons.snooze_rounded,
        size: 16,
        color: colorScheme.primary,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: colorScheme.surfaceContainerLow,
      onPressed: onTap,
    );
  }
}
