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

    // 1. Calculate raw calendar differences
    int years = now.year - updatedAt.year;
    int months = now.month - updatedAt.month;

    if (months < 0) {
      years--;
      months += 12;
    }

    // 2. Create a calendar baseline by stepping forward exact years and months
    int clampedDay = _clampDay(updatedAt.year + years, updatedAt.month + months, updatedAt.day);
    DateTime baseline = DateTime(
      updatedAt.year + years,
      updatedAt.month + months,
      clampedDay,
      updatedAt.hour,
      updatedAt.minute,
      updatedAt.second,
    );

    // 3. If our exact calendar step overshot "now" (due to hours/minutes being later),
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

    // 4. Calculate exact remaining time after our calendar baseline
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

  /// Prevents Dart from rolling over dates (e.g. Jan 31 + 1 month -> Mar 2).
  /// Instead, clamps to the last valid day of the target month (e.g., Feb 28 or 29).
  static int _clampDay(int year, int month, int targetDay) {
    // The "0" day of the next month gives us the last valid day of the current month.
    final int maxDaysInMonth = DateTime(year, month + 1, 0).day;
    return targetDay > maxDaysInMonth ? maxDaysInMonth : targetDay;
  }
}