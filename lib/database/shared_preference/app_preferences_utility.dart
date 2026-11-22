import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider that holds the initialized SharedPreferences instance.
/// This must be overridden in the main() function during app startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

final appPreferencesUtilityProvider = Provider<AppPreferencesUtility>((ref) {
  return AppPreferencesUtility(ref.watch(sharedPreferencesProvider));
});

class AppPreferencesUtility {
  final SharedPreferences _prefs;
  AppPreferencesUtility(this._prefs);

  /// Clears all keys stored in [SharedPreferences].
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
