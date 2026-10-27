import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import '../../shared/overlays/snack_bar_manager.dart';
import 'providers/reminder_provider.dart';
import 'reminder_manager.dart';
import 'widgets/conversational_chip.dart';

class ReminderPage extends ConsumerStatefulWidget {
  final String noteUuid;
  final String noteTitle;
  final DateTime? existingReminderAt;
  final String? existingRepeatMode;
  final String? existingCustomDays;

  const ReminderPage({
    super.key,
    required this.noteUuid,
    required this.noteTitle,
    this.existingReminderAt,
    this.existingRepeatMode,
    this.existingCustomDays,
  });

  @override
  ConsumerState<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends ConsumerState<ReminderPage> {
  late final TextEditingController _msgController;
  late final ReminderFormInitArgs _args;

  static const Map<int, String> _weekDays = {
    1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'
  };

  @override
  void initState() {
    super.initState();
    _msgController = TextEditingController(
      text: widget.noteTitle.trim().isNotEmpty ? widget.noteTitle.trim() : 'Note',
    );
    _args = ReminderFormInitArgs(
      existingReminderAt: widget.existingReminderAt,
      existingRepeatMode: widget.existingRepeatMode,
      existingCustomDays: widget.existingCustomDays,
      noteTitle: widget.noteTitle,
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  ReminderFormInitArgs get _initArgs => _args;

  Future<void> _pickDate(ReminderFormNotifier notifier, DateTime currentDate) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 365 * 5));

    // Clamp both bottom and top bounds
    var safeInitial = currentDate.isBefore(firstDate) ? firstDate : currentDate;
    if (safeInitial.isAfter(lastDate)) safeInitial = lastDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) notifier.setDate(picked);
  }

  Future<void> _pickTime(ReminderFormNotifier notifier, TimeOfDay currentTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    if (picked != null) notifier.setTime(picked);
  }

  Future<void> _pickRepeatMode(
    BuildContext context,
    TapDownDetails details,
    ReminderFormNotifier notifier,
  ) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        details.globalPosition,
        details.globalPosition,
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<ReminderRepeatMode>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: const [
        PopupMenuItem(
          value: ReminderRepeatMode.once,
          child: Row(
            children: [
              Icon(Icons.looks_one_rounded, size: 18),
              SizedBox(width: 8),
              Text('Once'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ReminderRepeatMode.daily,
          child: Row(
            children: [
              Icon(Icons.today_rounded, size: 18),
              SizedBox(width: 8),
              Text('Daily'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ReminderRepeatMode.weekly,
          child: Row(
            children: [
              Icon(Icons.date_range_rounded, size: 18),
              SizedBox(width: 8),
              Text('Weekly'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ReminderRepeatMode.monthly,
          child: Row(
            children: [
              Icon(Icons.calendar_view_month_rounded, size: 18),
              SizedBox(width: 8),
              Text('Monthly'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ReminderRepeatMode.yearly,
          child: Row(
            children: [
              Icon(Icons.event_repeat_rounded, size: 18),
              SizedBox(width: 8),
              Text('Yearly'),
            ],
          ),
        ),
      ],
    );

    if (selected != null) {
      notifier.setRepeatMode(selected);
    }
  }

  Future<void> _pickMonthlyDay(ReminderFormNotifier notifier, int currentDay) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Day of Month',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 31,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (ctx, index) {
                      final dayNum = index + 1;
                      final isSel = dayNum == currentDay;
                      return InkWell(
                        onTap: () => Navigator.of(ctx).pop(dayNum),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$dayNum',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? colorScheme.onPrimary : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected != null) {
      notifier.setMonthlyDay(selected);
    }
  }

  Future<void> _saveReminder(
    ReminderFormState formState,
    ReminderFormNotifier notifier,
  ) async {
    if (formState.isSaving) return;

    var finalDateTime = DateTime(
      formState.selectedDate.year,
      formState.selectedDate.month,
      formState.selectedDate.day,
      formState.selectedTime.hour,
      formState.selectedTime.minute,
    );

    final now = DateTime.now();
    if (formState.repeatMode == ReminderRepeatMode.once) {
      if (finalDateTime.isBefore(now)) {
        if (now.difference(finalDateTime).inMinutes < 1) {
          finalDateTime = now.add(const Duration(seconds: 5));
        } else {
          SnackBarManager.show(
            msg: 'Please select a future time for the reminder.',
            type: SnackBarMessageType.error,
          );
          return;
        }
      }
    }

    if (formState.repeatMode == ReminderRepeatMode.weekly && formState.selectedWeeklyDays.isEmpty) {
      SnackBarManager.show(
        msg: 'Please select at least one day for weekly repeat.',
        type: SnackBarMessageType.error,
      );
      return;
    }

    notifier.setSaving(true);

    try {
      final messageText = _msgController.text.trim().isNotEmpty
          ? _msgController.text.trim()
          : (widget.noteTitle.trim().isNotEmpty ? widget.noteTitle.trim() : 'Note');

      String? saveRepeatModeStr;
      String? saveCustomDaysStr;
      List<int>? selectedDaysList;

      switch (formState.repeatMode) {
        case ReminderRepeatMode.once:
          saveRepeatModeStr = 'none';
          saveCustomDaysStr = null;
          break;
        case ReminderRepeatMode.daily:
          saveRepeatModeStr = 'daily';
          saveCustomDaysStr = null;
          break;
        case ReminderRepeatMode.weekly:
          saveRepeatModeStr = 'weekly';
          selectedDaysList = formState.selectedWeeklyDays.toList()..sort();
          saveCustomDaysStr = selectedDaysList.join(',');
          break;
        case ReminderRepeatMode.monthly:
          saveRepeatModeStr = 'monthly';
          selectedDaysList = [formState.selectedMonthlyDay];
          saveCustomDaysStr = formState.selectedMonthlyDay.toString();
          break;
        case ReminderRepeatMode.yearly:
          saveRepeatModeStr = 'yearly';
          saveCustomDaysStr = null;
          break;
      }

      // 1. Schedule with Notification Manager
      final calculatedNextDate = await ReminderManager().scheduleForNote(
        noteUuid: widget.noteUuid,
        title: 'Note-It Reminder',
        message: messageText,
        date: finalDateTime,
        repeatMode: formState.repeatMode,
        selectedDays: selectedDaysList,
      );

      final saveDate = calculatedNextDate ?? finalDateTime;

      // 2. Persist in Database
      await ref.read(notesDaoProvider).updateNoteReminder(
        widget.noteUuid,
        saveDate,
        repeatMode: saveRepeatModeStr,
        customDays: saveCustomDaysStr,
      );

      final formattedLabel = ReminderManager.formatReminderLabel(
        saveDate,
        saveRepeatModeStr,
        saveCustomDaysStr,
      );
      SnackBarManager.show(
        msg: 'Reminder set for $formattedLabel',
        type: SnackBarMessageType.acknowledgment,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      SnackBarManager.show(
        msg: 'Failed to set reminder: $e',
        type: SnackBarMessageType.error,
      );
    } finally {
      if (mounted) notifier.setSaving(false);
    }
  }

  Future<void> _clearReminder(ReminderFormNotifier notifier) async {
    notifier.setSaving(true);

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
      if (mounted) notifier.setSaving(false);
    }
  }

  String _getRepeatModeLabel(ReminderRepeatMode mode) {
    switch (mode) {
      case ReminderRepeatMode.once:
        return 'Once';
      case ReminderRepeatMode.daily:
        return 'Daily';
      case ReminderRepeatMode.weekly:
        return 'Weekly';
      case ReminderRepeatMode.monthly:
        return 'Monthly';
      case ReminderRepeatMode.yearly:
        return 'Yearly';
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(reminderFormProvider(_initArgs));
    final notifier = ref.read(reminderFormProvider(_initArgs).notifier);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasExisting = widget.existingReminderAt != null;
    final screenHeight = MediaQuery.of(context).size.height;

    final sentenceStyle = theme.textTheme.titleMedium?.copyWith(
      height: 1.8,
      fontWeight: FontWeight.w500,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: screenHeight * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Set Reminder',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Scrollable Form Body ---
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Message Input ---
                      TextField(
                        controller: _msgController,
                        decoration: InputDecoration(
                          labelText: 'Reminder Message',
                          hintText: 'Enter reminder text...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: const Icon(Icons.edit_note_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Conversational "Mad Libs" Sentence UI ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 10,
                          spacing: 6,
                          children: [
                            Text('Remind me ', style: sentenceStyle),
                            Builder(
                              builder: (chipContext) => ConversationalChip(
                                label: _getRepeatModeLabel(formState.repeatMode),
                                icon: Icons.repeat_rounded,
                                onTapDown: (details) => _pickRepeatMode(chipContext, details, notifier),
                              ),
                            ),
                            if (formState.repeatMode == ReminderRepeatMode.once) ...[
                              Text(' on ', style: sentenceStyle),
                              ConversationalChip(
                                label: DateFormat('MMM d, yyyy').format(formState.selectedDate),
                                icon: Icons.calendar_today_rounded,
                                onTap: () => _pickDate(notifier, formState.selectedDate),
                              ),
                              Text(' at ', style: sentenceStyle),
                              ConversationalChip(
                                label: formState.selectedTime.format(context),
                                icon: Icons.access_time_rounded,
                                onTap: () => _pickTime(notifier, formState.selectedTime),
                              ),
                              Text('.', style: sentenceStyle),
                            ] else if (formState.repeatMode == ReminderRepeatMode.daily) ...[
                              Text(' starting ', style: sentenceStyle),
                              ConversationalChip(
                                label: DateFormat('MMM d, yyyy').format(formState.selectedDate),
                                icon: Icons.calendar_today_rounded,
                                onTap: () => _pickDate(notifier, formState.selectedDate),
                              ),
                              Text(' at ', style: sentenceStyle),
                              ConversationalChip(
                                label: formState.selectedTime.format(context),
                                icon: Icons.access_time_rounded,
                                onTap: () => _pickTime(notifier, formState.selectedTime),
                              ),
                              Text('.', style: sentenceStyle),
                            ] else if (formState.repeatMode == ReminderRepeatMode.weekly) ...[
                              Text(' on the selected days at ', style: sentenceStyle),
                              ConversationalChip(
                                label: formState.selectedTime.format(context),
                                icon: Icons.access_time_rounded,
                                onTap: () => _pickTime(notifier, formState.selectedTime),
                              ),
                              Text('.', style: sentenceStyle),
                            ] else if (formState.repeatMode == ReminderRepeatMode.monthly) ...[
                              Text(' on the ', style: sentenceStyle),
                              ConversationalChip(
                                label: '${formState.selectedMonthlyDay}${_getDaySuffix(formState.selectedMonthlyDay)}',
                                icon: Icons.calendar_view_month_rounded,
                                onTap: () => _pickMonthlyDay(notifier, formState.selectedMonthlyDay),
                              ),
                              Text(' of every month at ', style: sentenceStyle),
                              ConversationalChip(
                                label: formState.selectedTime.format(context),
                                icon: Icons.access_time_rounded,
                                onTap: () => _pickTime(notifier, formState.selectedTime),
                              ),
                              Text('.', style: sentenceStyle),
                            ] else if (formState.repeatMode == ReminderRepeatMode.yearly) ...[
                              Text(' every year on ', style: sentenceStyle),
                              ConversationalChip(
                                label: DateFormat('MMM d').format(formState.selectedDate),
                                icon: Icons.event_repeat_rounded,
                                onTap: () => _pickDate(notifier, formState.selectedDate),
                              ),
                              Text(' at ', style: sentenceStyle),
                              ConversationalChip(
                                label: formState.selectedTime.format(context),
                                icon: Icons.access_time_rounded,
                                onTap: () => _pickTime(notifier, formState.selectedTime),
                              ),
                              Text('.', style: sentenceStyle),
                            ],
                          ],
                        ),
                      ),

                      // --- Weekly Day Selector ---
                      if (formState.repeatMode == ReminderRepeatMode.weekly) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Repeat Days:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (int day = 1; day <= 7; day++)
                              FilterChip(
                                label: Text(_weekDays[day]!),
                                selected: formState.selectedWeeklyDays.contains(day),
                                onSelected: (_) => notifier.toggleWeeklyDay(day),
                                visualDensity: VisualDensity.compact,
                                showCheckmark: false,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Actions ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasExisting) ...[
                    OutlinedButton.icon(
                      onPressed: formState.isSaving ? null : () => _clearReminder(notifier),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const Spacer(),
                  ],
                  TextButton(
                    onPressed: formState.isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: formState.isSaving ? null : () => _saveReminder(formState, notifier),
                    icon: formState.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(formState.isSaving ? 'Saving...' : 'Set Reminder'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
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
