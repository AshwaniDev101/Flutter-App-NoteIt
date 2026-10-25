import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import '../../shared/overlays/snack_bar_manager.dart';
import 'reminder_manager.dart';

class ReminderPage extends ConsumerStatefulWidget {
  final String noteUuid;
  final String noteTitle;
  final DateTime? existingReminderAt;

  const ReminderPage({
    super.key,
    required this.noteUuid,
    required this.noteTitle,
    this.existingReminderAt,
  });

  @override
  ConsumerState<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends ConsumerState<ReminderPage> {
  final TextEditingController _msgController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  ReminderRepeatMode _repeatMode = ReminderRepeatMode.once;
  final Set<int> _selectedDays = {}; // 1 = Mon, 7 = Sun
  bool _isSaving = false;

  final Map<int, String> _weekDays = {
    1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'
  };

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReminderAt;
    final now = DateTime.now();

    if (existing != null && existing.isAfter(now)) {
      _selectedDate = existing;
      _selectedTime = TimeOfDay(hour: existing.hour, minute: existing.minute);
    } else {
      _selectedDate = now;
      final futureTime = now.add(const Duration(minutes: 15));
      _selectedTime = TimeOfDay(hour: futureTime.hour, minute: futureTime.minute);
    }

    final displayTitle = widget.noteTitle.trim().isNotEmpty ? widget.noteTitle.trim() : 'Note';
    _msgController.text = "Time to review: $displayTitle";
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveReminder() async {
    if (_isSaving) return;

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (finalDateTime.isBefore(DateTime.now()) && _repeatMode == ReminderRepeatMode.once) {
      SnackBarManager.show(
        msg: 'Please select a future time for the reminder.',
        type: SnackBarMessageType.error,
      );
      return;
    }

    if (_repeatMode == ReminderRepeatMode.customDays && _selectedDays.isEmpty) {
      SnackBarManager.show(
        msg: 'Please select at least one day for repeat.',
        type: SnackBarMessageType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final messageText = _msgController.text.trim().isNotEmpty
          ? _msgController.text.trim()
          : 'Note Reminder';

      // 1. Schedule with Notification Manager
      await ReminderManager().scheduleForNote(
        noteUuid: widget.noteUuid,
        title: 'Note Reminder',
        message: messageText,
        date: finalDateTime,
        repeatMode: _repeatMode,
        selectedDays: _selectedDays.toList(),
      );

      // 2. Persist in Database
      await ref.read(notesDaoProvider).updateNoteReminder(widget.noteUuid, finalDateTime);

      final formattedDate = DateFormat('MMM d, h:mm a').format(finalDateTime);
      SnackBarManager.show(
        msg: 'Reminder set for $formattedDate',
        type: SnackBarMessageType.acknowledgment,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      SnackBarManager.show(
        msg: 'Failed to set reminder: $e',
        type: SnackBarMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearReminder() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 1. Cancel active local notifications
      await ReminderManager().cancelForNote(widget.noteUuid);

      // 2. Clear database timestamp
      await ref.read(notesDaoProvider).updateNoteReminder(widget.noteUuid, null);

      SnackBarManager.show(
        msg: 'Reminder cleared',
        type: SnackBarMessageType.acknowledgment,
      );

      if (mounted) Navigator.of(context).pop(false);
    } catch (e) {
      SnackBarManager.show(
        msg: 'Failed to clear reminder: $e',
        type: SnackBarMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasExisting = widget.existingReminderAt != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: colorScheme.primary, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Set Reminder',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Message Input ---
              TextField(
                controller: _msgController,
                decoration: InputDecoration(
                  labelText: 'Reminder Message',
                  hintText: 'Enter reminder text...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.edit_note),
                ),
              ),
              const SizedBox(height: 20),

              // --- Date & Time Selection ---
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 20),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.access_time_rounded, color: colorScheme.primary, size: 20),
                            const SizedBox(height: 6),
                            Text(
                              _selectedTime.format(context),
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Repeat Options ---
              Text('Repeat', style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ReminderRepeatMode>(
                  segments: const [
                    ButtonSegment(value: ReminderRepeatMode.once, label: Text('Once')),
                    ButtonSegment(value: ReminderRepeatMode.daily, label: Text('Daily')),
                    ButtonSegment(value: ReminderRepeatMode.customDays, label: Text('Custom')),
                  ],
                  selected: {_repeatMode},
                  onSelectionChanged: (Set<ReminderRepeatMode> newSelection) {
                    setState(() => _repeatMode = newSelection.first);
                  },
                ),
              ),

              // --- Custom Days Picker ---
              if (_repeatMode == ReminderRepeatMode.customDays) ...[
                const SizedBox(height: 16),
                Text('Select Days', style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekDays.entries.map((entry) {
                    final isSelected = _selectedDays.contains(entry.key);
                    return FilterChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      showCheckmark: false,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(6),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(entry.key);
                          } else {
                            _selectedDays.remove(entry.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),

              // --- Action Buttons ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasExisting)
                    TextButton.icon(
                      onPressed: _isSaving ? null : _clearReminder,
                      icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error, size: 18),
                      label: Text('Clear', style: TextStyle(color: colorScheme.error)),
                    ),
                  if (hasExisting) const Spacer(),
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveReminder,
                    child: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save Reminder'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
