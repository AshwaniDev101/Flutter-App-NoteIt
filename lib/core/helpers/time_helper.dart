import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import '../../features/settings/time_format/time_preferences_provider.dart';

/// Riverpod provider supplying a date-time formatting function reflecting active user preferences.
///
/// Watching this provider causes widgets to automatically rebuild when user changes date/time format preferences.
final timeFormatterProvider = Provider<String Function(DateTime?)>((ref) {
  final state = ref.watch(timePreferencesProvider);

  return (DateTime? dt) {
    final date = dt ?? DateTime.now();
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
  };
});

class TimeHelper {
  TimeHelper._();

  /// Cache for [DateFormat] instances to prevent expensive repeated pattern parsing.
  static final Map<String, DateFormat> _formatterCache = {};

  /// Formats a [DateTime] according to preferences saved in [SharedPreferenceManager].
  /// Uses `DateTime.now()` if [dt] is null.
  static String formatDate(DateTime? dt) {
    final date = dt ?? DateTime.now();
    try {
      final prefs = SharedPreferenceManager.instance;
      return formatCustomDateTime(
        date,
        useSystemFormat: prefs.timeUseSystemFormat,
        is24Hour: prefs.timeIs24Hour,
        dayFormat: prefs.timeDayFormat,
        monthFormat: prefs.timeMonthFormat,
        yearFormat: prefs.timeYearFormat,
        separator: prefs.timeSeparator,
        order: prefs.timeOrder,
      );
    } catch (_) {
      return DateFormat.yMMMd().add_jm().format(date);
    }
  }

  /// Formats a [DateTime] into a precise relative "time ago" string.
  /// Accounts for leap years and exact calendar month lengths.
  static String formatTimeAgo(
      DateTime updatedAt, {
        DateTime? referenceTime,
        bool shortSuffixes = true,
        bool addAgo = false,
      }) {
    final now = referenceTime ?? DateTime.now();

    // Safety check in case the time is slightly in the future (e.g., clock drift)
    if (updatedAt.isAfter(now)) {
      return 'Just now';
    }

    // Calculate raw calendar differences
    int years = now.year - updatedAt.year;
    int months = now.month - updatedAt.month;

    if (months < 0) {
      years--;
      months += 12;
    }

    // Create a calendar baseline by stepping forward exact years and months
    int clampedDay = _clampDay(updatedAt.year + years, updatedAt.month + months, updatedAt.day);
    DateTime baseline = DateTime(
      updatedAt.year + years,
      updatedAt.month + months,
      clampedDay,
      updatedAt.hour,
      updatedAt.minute,
      updatedAt.second,
    );

    // If our exact calendar step overshot "now" (due to hours/minutes being later),
    // we back up exactly one month.
    if (baseline.isAfter(now)) {
      months--;
      if (months < 0) {
        years--;
        months = 11;
      }
      clampedDay = _clampDay(updatedAt.year + years, updatedAt.month + months, updatedAt.day);
      baseline = DateTime(
        updatedAt.year + years,
        updatedAt.month + months,
        clampedDay,
        updatedAt.hour,
        updatedAt.minute,
        updatedAt.second,
      );
    }

    // Calculate exact remaining time after our calendar baseline
    final Duration remaining = now.difference(baseline);
    final int days = remaining.inDays;
    final int hours = remaining.inHours % 24;
    final int minutes = remaining.inMinutes % 60;

    // Seconds are no longer needed for the UI logic, but can remain if you
    // ever need to use them for debugging.

    String result = '';

    // -- FORMATTING RULES --

    // 1 Year or more
    if (years > 0) {
      final ySuffix = shortSuffixes ? 'y' : (years == 1 ? ' year' : ' years');
      result = '$years$ySuffix';
    }
    // Less than a year: Months
    else if (months > 0) {
      final moSuffix = shortSuffixes ? 'mo' : (months == 1 ? ' month' : ' months');
      result = '$months$moSuffix';
    }
    // Less than a month: Days
    else if (days > 0) {
      final dSuffix = shortSuffixes ? 'd' : (days == 1 ? ' day' : ' days');
      result = '$days$dSuffix';
    }
    // Less than a day: Hours
    else if (hours > 0) {
      final hSuffix = shortSuffixes ? 'h' : (hours == 1 ? ' hour' : ' hours');
      result = '$hours$hSuffix';
    }
    // Less than an hour: Minutes
    else if (minutes > 0) {
      final mSuffix = shortSuffixes ? 'm' : (minutes == 1 ? ' minute' : ' minutes');
      result = '$minutes$mSuffix';
    }
    // Less than a minute
    else {
      return 'Just now';
    }

    if (addAgo) {
      result += ' ago';
    }

    return result;
  }

  /// Formats a [DateTime] for note editor header/status bar using active user preferences.
  static String formatEditorDate(DateTime dt, {bool isNewNote = false}) {
    return formatDate(dt);
  }

  /// Formats a [DateTime] into user's preferred format string, fallback to [fallback] if null.
  static String formatFullDateTime(DateTime? dt, {String fallback = 'Never'}) {
    if (dt == null) return fallback;
    return formatDate(dt);
  }

  /// Formats a [DateTime] into a compact 'YYYYMMDD' string for file naming.
  static String formatCompactDate([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Returns the ordinal suffix for a day of the month (e.g. 1st, 2nd, 3rd, 4th).
  static String getDaySuffix(int day) {
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

  /// Formats time in 12-hour format with AM/PM (e.g. '5:30 PM').
  static String format12HourTime(DateTime dt) {
    return _formatterCache.putIfAbsent('h:mm a', () => DateFormat('h:mm a')).format(dt);
  }

  /// Formats date in short month and day format (e.g. 'Oct 24').
  static String formatShortMonthDay(DateTime dt) {
    return _formatterCache.putIfAbsent('MMM d', () => DateFormat('MMM d')).format(dt);
  }

  /// Formats date in full month, day, and year format (e.g. 'Oct 24, 2023').
  static String formatMonthDayYear(DateTime dt) {
    return _formatterCache.putIfAbsent('MMM d, yyyy', () => DateFormat('MMM d, yyyy')).format(dt);
  }

  /// Formats date and time in month, day, and 12-hour time format (e.g. 'Oct 24, 5:30 PM').
  static String formatMonthDayTime(DateTime dt) {
    return _formatterCache.putIfAbsent('MMM d, h:mm a', () => DateFormat('MMM d, h:mm a')).format(dt);
  }

  /// Safely converts various date/timestamp formats (int epoch ms, double, String ISO, DateTime) into UTC DateTime
  static DateTime? parseToUtcDateTime(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) return input.toUtc();
    if (input is int) {
      return DateTime.fromMillisecondsSinceEpoch(input, isUtc: true);
    }
    if (input is double) {
      return DateTime.fromMillisecondsSinceEpoch(input.toInt(), isUtc: true);
    }

    final str = input.toString().trim();
    if (str.isEmpty || str == 'null') return null;

    final intVal = int.tryParse(str);
    if (intVal != null && intVal > 100000000) {
      return DateTime.fromMillisecondsSinceEpoch(intVal, isUtc: true);
    }

    try {
      return DateTime.parse(str).toUtc();
    } catch (_) {
      return null;
    }
  }

  /// Safely converts various date/timestamp formats into ISO 8601 String
  static String? parseToIso8601String(dynamic input) {
    final dt = parseToUtcDateTime(input);
    return dt?.toIso8601String();
  }

  /// Formats a [DateTime] according to custom date/time preferences or system format settings.
  ///
  /// Uses cached [DateFormat] instances for optimal performance.
  static String formatCustomDateTime(
    DateTime date, {
    bool useSystemFormat = false,
    bool is24Hour = false,
    String dayFormat = 'dd',
    String monthFormat = 'MMM',
    String yearFormat = 'yyyy',
    String separator = '-',
    List<String> order = const ['day', 'month', 'year', 'time'],
  }) {
    if (useSystemFormat) {
      return _formatterCache.putIfAbsent(
        '__system_default__',
        () => DateFormat.yMMMd().add_jm(),
      ).format(date);
    }

    final sep = separator == ' ' ? ' ' : "'$separator'";
    String pattern = '';

    for (int i = 0; i < order.length; i++) {
      final part = order[i];

      switch (part) {
        case 'day':
          pattern += dayFormat;
          break;
        case 'month':
          pattern += monthFormat;
          break;
        case 'year':
          pattern += yearFormat;
          break;
        case 'time':
          pattern += is24Hour ? 'HH:mm' : 'hh:mm a';
          break;
      }

      if (i < order.length - 1) {
        final nextPart = order[i + 1];
        final isCurrentDatePart = part != 'time';
        final isNextDatePart = nextPart != 'time';

        if (isCurrentDatePart && isNextDatePart) {
          pattern += sep;
        } else {
          pattern += ' '; // Always space between date components and time
        }
      }
    }

    return _formatterCache.putIfAbsent(
      pattern,
      () => DateFormat(pattern),
    ).format(date);
  }

  /// Prevents Dart from rolling over dates (e.g. Jan 31 + 1 month -> Mar 2).
  /// Instead, clamps to the last valid day of the target month (e.g., Feb 28 or 29).
  static int _clampDay(int year, int month, int targetDay) {
    final int maxDaysInMonth = DateTime(year, month + 1, 0).day;
    return targetDay > maxDaysInMonth ? maxDaysInMonth : targetDay;
  }
}
