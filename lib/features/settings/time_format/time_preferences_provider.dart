import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteit/core/helpers/time_helper.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';

/// Represents the individual components of date and time that can be arranged.
enum FormatPart {
  day('Day'),
  month('Month'),
  year('Year'),
  time('Time');

  final String label;
  const FormatPart(this.label);
}

/// Immutable state holding user preferences for date and time formatting.
class TimePreferencesState {
  /// Whether to follow the device system default format instead of custom options.
  final bool useSystemFormat;

  /// Whether 24-hour time display (e.g., 14:30) is enabled.
  final bool is24Hour;

  /// Day representation pattern ('d' or 'dd').
  final String dayFormat;

  /// Month representation pattern ('M', 'MM', 'MMM', 'MMMM').
  final String monthFormat;

  /// Year representation pattern ('yy' or 'yyyy').
  final String yearFormat;

  /// Separator symbol inserted between date parts ('-', '/', '.', ' ').
  final String separator;

  /// Ordered list specifying the sequence of day, month, year, and time components.
  final List<FormatPart> order;

  const TimePreferencesState({
    this.useSystemFormat = false,
    this.is24Hour = false,
    this.dayFormat = 'dd',
    this.monthFormat = 'MMM',
    this.yearFormat = 'yyyy',
    this.separator = '-',
    this.order = const [
      FormatPart.day,
      FormatPart.month,
      FormatPart.year,
      FormatPart.time
    ],
  });

  TimePreferencesState copyWith({
    bool? useSystemFormat,
    bool? is24Hour,
    String? dayFormat,
    String? monthFormat,
    String? yearFormat,
    String? separator,
    List<FormatPart>? order,
  }) {
    return TimePreferencesState(
      useSystemFormat: useSystemFormat ?? this.useSystemFormat,
      is24Hour: is24Hour ?? this.is24Hour,
      dayFormat: dayFormat ?? this.dayFormat,
      monthFormat: monthFormat ?? this.monthFormat,
      yearFormat: yearFormat ?? this.yearFormat,
      separator: separator ?? this.separator,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimePreferencesState &&
        other.useSystemFormat == useSystemFormat &&
        other.is24Hour == is24Hour &&
        other.dayFormat == dayFormat &&
        other.monthFormat == monthFormat &&
        other.yearFormat == yearFormat &&
        other.separator == separator &&
        listEquals(other.order, order);
  }

  @override
  int get hashCode {
    return Object.hash(
      useSystemFormat,
      is24Hour,
      dayFormat,
      monthFormat,
      yearFormat,
      separator,
      Object.hashAll(order),
    );
  }
}

/// Riverpod [Notifier] that manages date/time preferences and persists changes
/// to local storage via [SharedPreferenceManager].
class TimePreferencesNotifier extends Notifier<TimePreferencesState> {
  late final SharedPreferenceManager _prefs;

  @override
  TimePreferencesState build() {
    _prefs = ref.watch(sharedPreferenceProvider);

    final orderStrings = _prefs.timeOrder;
    final parsedOrder = orderStrings.map((s) {
      switch (s) {
        case 'day':
          return FormatPart.day;
        case 'month':
          return FormatPart.month;
        case 'year':
          return FormatPart.year;
        case 'time':
          return FormatPart.time;
        default:
          return FormatPart.day;
      }
    }).toList();

    return TimePreferencesState(
      useSystemFormat: _prefs.timeUseSystemFormat,
      is24Hour: _prefs.timeIs24Hour,
      dayFormat: _prefs.timeDayFormat,
      monthFormat: _prefs.timeMonthFormat,
      yearFormat: _prefs.timeYearFormat,
      separator: _prefs.timeSeparator,
      order: parsedOrder.isEmpty
          ? const [
              FormatPart.day,
              FormatPart.month,
              FormatPart.year,
              FormatPart.time
            ]
          : parsedOrder,
    );
  }

  /// Toggles whether system default formatting should be copied.
  void toggleSystemFormat(bool value) {
    if (state.useSystemFormat == value) return;
    state = state.copyWith(useSystemFormat: value);
    _prefs.setTimeUseSystemFormat(value);
  }

  /// Updates 12-hour vs 24-hour clock preference.
  void set24Hour(bool value) {
    if (state.is24Hour == value) return;
    state = state.copyWith(is24Hour: value);
    _prefs.setTimeIs24Hour(value);
  }

  /// Updates day format (e.g. 'd' or 'dd').
  void setDayFormat(String value) {
    if (state.dayFormat == value) return;
    state = state.copyWith(dayFormat: value);
    _prefs.setTimeDayFormat(value);
  }

  /// Updates month format (e.g. 'M', 'MM', 'MMM', or 'MMMM').
  void setMonthFormat(String value) {
    if (state.monthFormat == value) return;
    state = state.copyWith(monthFormat: value);
    _prefs.setTimeMonthFormat(value);
  }

  /// Updates year format (e.g. 'yy' or 'yyyy').
  void setYearFormat(String value) {
    if (state.yearFormat == value) return;
    state = state.copyWith(yearFormat: value);
    _prefs.setTimeYearFormat(value);
  }

  /// Updates date separator symbol (e.g. '-', '/', '.', or ' ').
  void setSeparator(String value) {
    if (state.separator == value) return;
    state = state.copyWith(separator: value);
    _prefs.setTimeSeparator(value);
  }

  /// Reorders layout chips when dragged by user via [onReorderItem] and saves the new order.
  void reorderPartsDirect(int oldIndex, int newIndex) {
    final newOrder = List<FormatPart>.from(state.order);
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    state = state.copyWith(order: newOrder);

    final orderNames = newOrder.map((e) => e.name).toList();
    _prefs.setTimeOrder(orderNames);
  }

  /// Resets all time preferences to standard defaults.
  void resetToDefaults() {
    state = const TimePreferencesState();
    _prefs.setTimeUseSystemFormat(false);
    _prefs.setTimeIs24Hour(false);
    _prefs.setTimeDayFormat('dd');
    _prefs.setTimeMonthFormat('MMM');
    _prefs.setTimeYearFormat('yyyy');
    _prefs.setTimeSeparator('-');
    _prefs.setTimeOrder(['day', 'month', 'year', 'time']);
  }

  /// Formats a [DateTime] instance using [TimeHelper] according to current preferences.
  String formatDateTime(DateTime date) {
    return TimeHelper.formatCustomDateTime(
      date,
      useSystemFormat: state.useSystemFormat,
      is24Hour: state.is24Hour,
      dayFormat: state.dayFormat,
      monthFormat: state.monthFormat,
      yearFormat: state.yearFormat,
      separator: state.separator,
      order: state.order.map((e) => e.name).toList(),
    );
  }
}

/// Global provider for managing and observing date/time preferences.
final timePreferencesProvider =
    NotifierProvider<TimePreferencesNotifier, TimePreferencesState>(() {
  return TimePreferencesNotifier();
});
