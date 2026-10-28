import 'package:intl/intl.dart';

class TimeHelper {
  TimeHelper._();

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
    final int seconds = remaining.inSeconds % 60;

    String result = '';

    // -- FORMATTING RULES --

    // 1 Year or more: Years + Months
    if (years > 0) {
      final ySuffix = shortSuffixes ? 'y' : (years == 1 ? ' year' : ' years');
      final moSuffix = shortSuffixes ? 'mo' : (months == 1 ? ' month' : ' months');

      result = '$years$ySuffix';
      if (months > 0) result += ' $months$moSuffix';
    }

    // Less than a year: Months + Days
    else if (months > 0) {
      final moSuffix = shortSuffixes ? 'mo' : (months == 1 ? ' month' : ' months');
      final dSuffix = shortSuffixes ? 'd' : (days == 1 ? ' day' : ' days');

      result = '$months$moSuffix';
      if (days > 0) result += ' $days$dSuffix';
    }

    // Less than a month: Days + Hours
    else if (days > 0) {
      final dSuffix = shortSuffixes ? 'd' : (days == 1 ? ' day' : ' days');
      final hSuffix = shortSuffixes ? 'h' : (hours == 1 ? ' hour' : ' hours');

      result = '$days$dSuffix';
      if (hours > 0) result += ' $hours$hSuffix';
    }

    // Less than a day: Hours + Minutes
    else if (hours > 0) {
      final hSuffix = shortSuffixes ? 'h' : (hours == 1 ? ' hour' : ' hours');
      final mSuffix = shortSuffixes ? 'm' : (minutes == 1 ? ' minute' : ' minutes');

      result = '$hours$hSuffix';
      if (minutes > 0) result += ' $minutes$mSuffix';
    }

    // Less than an hour: Minutes only (drops seconds)
    else if (minutes > 0) {
      final mSuffix = shortSuffixes ? 'm' : (minutes == 1 ? ' minute' : ' minutes');
      result = '$minutes$mSuffix';
    }

    // Less than a minute: Seconds only
    else if (seconds > 0) {
      final sSuffix = shortSuffixes ? 's' : (seconds == 1 ? ' second' : ' seconds');
      result = '$seconds$sSuffix';
    }

    // Exact same timestamp
    else {
      return 'Just now';
    }

    if (addAgo) {
      result += ' ago';
    }

    return result;
  }

  /// Formats a [DateTime] for note editor header/status bar.
  /// Returns 'M/d/yyyy' if [isNewNote] is true, otherwise 'M/d/yyyy H:mm'.
  static String formatEditorDate(DateTime dt, {bool isNewNote = false}) {
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    if (isNewNote) {
      return '${dt.month}/${dt.day}/${dt.year}';
    }
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:$minuteStr';
  }

  /// Formats a [DateTime] into a standard 'YYYY-MM-DD HH:mm' string.
  /// Returns [fallback] (default 'Never') if [dt] is null.
  static String formatFullDateTime(DateTime? dt, {String fallback = 'Never'}) {
    if (dt == null) return fallback;
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
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
    return DateFormat('h:mm a').format(dt);
  }

  /// Formats date in short month and day format (e.g. 'Oct 24').
  static String formatShortMonthDay(DateTime dt) {
    return DateFormat('MMM d').format(dt);
  }

  /// Formats date in full month, day, and year format (e.g. 'Oct 24, 2023').
  static String formatMonthDayYear(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt);
  }

  /// Formats date and time in month, day, and 12-hour time format (e.g. 'Oct 24, 5:30 PM').
  static String formatMonthDayTime(DateTime dt) {
    return DateFormat('MMM d, h:mm a').format(dt);
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

  /// Prevents Dart from rolling over dates (e.g. Jan 31 + 1 month -> Mar 2).
  /// Instead, clamps to the last valid day of the target month (e.g., Feb 28 or 29).
  static int _clampDay(int year, int month, int targetDay) {
    // The "0" day of the next month gives us the last valid day of the current month.
    final int maxDaysInMonth = DateTime(year, month + 1, 0).day;
    return targetDay > maxDaysInMonth ? maxDaysInMonth : targetDay;
  }
}