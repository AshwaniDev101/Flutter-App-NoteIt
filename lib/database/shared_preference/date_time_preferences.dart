import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences_utility.dart';

final dateTimePreferencesProvider = Provider<DateTimePreferences>((ref) {
  return DateTimePreferences(ref.watch(sharedPreferencesProvider));
});

class DateTimePreferences {
  final SharedPreferences _prefs;
  DateTimePreferences(this._prefs);

  static const String _keyTimeUseSystemFormat = 'time_use_system_format';
  static const String _keyTimeIs24Hour = 'time_is_24_hour';
  static const String _keyTimeDayFormat = 'time_day_format';
  static const String _keyTimeMonthFormat = 'time_month_format';
  static const String _keyTimeYearFormat = 'time_year_format';
  static const String _keyTimeSeparator = 'time_separator';
  static const String _keyTimeOrder = 'time_order';

  bool get timeUseSystemFormat => _prefs.getBool(_keyTimeUseSystemFormat) ?? false;

  Future<bool> setTimeUseSystemFormat(bool value) async => await _prefs.setBool(_keyTimeUseSystemFormat, value);

  bool get timeIs24Hour => _prefs.getBool(_keyTimeIs24Hour) ?? false;

  Future<bool> setTimeIs24Hour(bool value) async => await _prefs.setBool(_keyTimeIs24Hour, value);

  String get timeDayFormat => _prefs.getString(_keyTimeDayFormat) ?? 'dd';

  Future<bool> setTimeDayFormat(String value) async => await _prefs.setString(_keyTimeDayFormat, value);

  String get timeMonthFormat => _prefs.getString(_keyTimeMonthFormat) ?? 'MMM';

  Future<bool> setTimeMonthFormat(String value) async => await _prefs.setString(_keyTimeMonthFormat, value);

  String get timeYearFormat => _prefs.getString(_keyTimeYearFormat) ?? 'yyyy';

  Future<bool> setTimeYearFormat(String value) async => await _prefs.setString(_keyTimeYearFormat, value);

  String get timeSeparator => _prefs.getString(_keyTimeSeparator) ?? '-';

  Future<bool> setTimeSeparator(String value) async => await _prefs.setString(_keyTimeSeparator, value);

  List<String> get timeOrder => _prefs.getStringList(_keyTimeOrder) ?? const ['day', 'month', 'year', 'time'];

  Future<bool> setTimeOrder(List<String> order) async => await _prefs.setStringList(_keyTimeOrder, order);
}
