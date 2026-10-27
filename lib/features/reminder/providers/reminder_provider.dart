import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../reminder_manager.dart';

class ReminderFormState {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final ReminderRepeatMode repeatMode;
  final Set<int> selectedWeeklyDays;
  final int selectedMonthlyDay;
  final String messageText;
  final bool isSaving;

  const ReminderFormState({
    required this.selectedDate,
    required this.selectedTime,
    required this.repeatMode,
    required this.selectedWeeklyDays,
    required this.selectedMonthlyDay,
    required this.messageText,
    this.isSaving = false,
  });

  ReminderFormState copyWith({
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    ReminderRepeatMode? repeatMode,
    Set<int>? selectedWeeklyDays,
    int? selectedMonthlyDay,
    String? messageText,
    bool? isSaving,
  }) {
    return ReminderFormState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      repeatMode: repeatMode ?? this.repeatMode,
      selectedWeeklyDays: selectedWeeklyDays ?? this.selectedWeeklyDays,
      selectedMonthlyDay: selectedMonthlyDay ?? this.selectedMonthlyDay,
      messageText: messageText ?? this.messageText,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class ReminderFormNotifier extends Notifier<ReminderFormState> {
  final ReminderFormInitArgs args;

  ReminderFormNotifier(this.args);

  @override
  ReminderFormState build() {
    final now = DateTime.now();
    DateTime selectedDate;
    TimeOfDay selectedTime;

    final existing = args.existingReminderAt;
    if (existing != null && existing.isAfter(now)) {
      selectedDate = existing;
      selectedTime = TimeOfDay(hour: existing.hour, minute: existing.minute);
    } else {
      selectedDate = now;
      selectedTime = TimeOfDay.fromDateTime(now);
    }

    ReminderRepeatMode repeatMode = ReminderRepeatMode.once;
    final Set<int> selectedWeeklyDays = {};
    int selectedMonthlyDay = selectedDate.day;

    final existingMode = args.existingRepeatMode;
    if (existingMode != null && existingMode.isNotEmpty) {
      if (existingMode == 'daily') {
        repeatMode = ReminderRepeatMode.daily;
      } else if (existingMode == 'weekly' || existingMode == 'customDays' || existingMode == 'custom') {
        repeatMode = ReminderRepeatMode.weekly;
      } else if (existingMode == 'monthly') {
        repeatMode = ReminderRepeatMode.monthly;
      } else if (existingMode == 'yearly') {
        repeatMode = ReminderRepeatMode.yearly;
      } else {
        repeatMode = ReminderRepeatMode.once;
      }
    } else {
      final savedRepeatStr = SharedPreferenceManager.instance.defaultRepeatMode;
      if (savedRepeatStr == 'daily') {
        repeatMode = ReminderRepeatMode.daily;
      } else if (savedRepeatStr == 'custom' || savedRepeatStr == 'weekly') {
        repeatMode = ReminderRepeatMode.weekly;
      } else {
        repeatMode = ReminderRepeatMode.once;
      }
    }

    final existingCustomDays = args.existingCustomDays;
    if (existingCustomDays != null && existingCustomDays.isNotEmpty) {
      if (existingMode == 'weekly' || existingMode == 'customDays' || existingMode == 'custom') {
        final days = existingCustomDays.split(',').map((e) => int.tryParse(e.trim())).whereType<int>();
        selectedWeeklyDays.addAll(days);
      } else if (existingMode == 'monthly') {
        final dayNum = int.tryParse(existingCustomDays.trim());
        if (dayNum != null && dayNum >= 1 && dayNum <= 31) {
          selectedMonthlyDay = dayNum;
        }
      }
    }

    final displayTitle = args.noteTitle.trim().isNotEmpty ? args.noteTitle.trim() : 'Note';

    return ReminderFormState(
      selectedDate: selectedDate,
      selectedTime: selectedTime,
      repeatMode: repeatMode,
      selectedWeeklyDays: selectedWeeklyDays,
      selectedMonthlyDay: selectedMonthlyDay,
      messageText: displayTitle,
    );
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setTime(TimeOfDay time) {
    state = state.copyWith(selectedTime: time);
  }

  void setRepeatMode(ReminderRepeatMode mode) {
    state = state.copyWith(repeatMode: mode);
  }

  void toggleWeeklyDay(int day) {
    final updated = Set<int>.from(state.selectedWeeklyDays);
    if (updated.contains(day)) {
      updated.remove(day);
    } else {
      updated.add(day);
    }
    state = state.copyWith(selectedWeeklyDays: updated);
  }

  void setMonthlyDay(int day) {
    state = state.copyWith(selectedMonthlyDay: day);
  }

  void setMessage(String message) {
    state = state.copyWith(messageText: message);
  }

  void setSaving(bool saving) {
    state = state.copyWith(isSaving: saving);
  }
}

final reminderFormProvider = NotifierProvider.family<
    ReminderFormNotifier, ReminderFormState, ReminderFormInitArgs>(
  (args) => ReminderFormNotifier(args),
);

class ReminderFormInitArgs {
  final DateTime? existingReminderAt;
  final String? existingRepeatMode;
  final String? existingCustomDays;
  final String noteTitle;

  const ReminderFormInitArgs({
    this.existingReminderAt,
    this.existingRepeatMode,
    this.existingCustomDays,
    required this.noteTitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderFormInitArgs &&
          runtimeType == other.runtimeType &&
          existingReminderAt == other.existingReminderAt &&
          existingRepeatMode == other.existingRepeatMode &&
          existingCustomDays == other.existingCustomDays &&
          noteTitle == other.noteTitle;

  @override
  int get hashCode =>
      existingReminderAt.hashCode ^
      existingRepeatMode.hashCode ^
      existingCustomDays.hashCode ^
      noteTitle.hashCode;
}
