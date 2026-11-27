import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences_utility.dart';

final editorPreferencesProvider = Provider<EditorPreferences>((ref) {
  return EditorPreferences(ref.watch(sharedPreferencesProvider));
});

class EditorPreferences {
  final SharedPreferences _prefs;
  EditorPreferences(this._prefs);

  static const String _keyPutCursorOnContent = 'editor_put_cursor_on_content';
  static const String _keyTitleFontSize = 'editor_title_font_size';
  static const String _keyContentFontSize = 'editor_content_font_size';
  static const String _keyLineSpacing = 'editor_line_spacing';

  bool get putCursorOnContent => _prefs.getBool(_keyPutCursorOnContent) ?? false;

  Future<bool> setPutCursorOnContent(bool value) async => await _prefs.setBool(_keyPutCursorOnContent, value);

  double get titleFontSize => _prefs.getDouble(_keyTitleFontSize) ?? 22.0;

  Future<bool> setTitleFontSize(double value) async => await _prefs.setDouble(_keyTitleFontSize, value);

  double get contentFontSize => _prefs.getDouble(_keyContentFontSize) ?? 16.0;

  Future<bool> setContentFontSize(double value) async => await _prefs.setDouble(_keyContentFontSize, value);

  double get lineSpacing => _prefs.getDouble(_keyLineSpacing) ?? 1.5;

  Future<bool> setLineSpacing(double value) async => await _prefs.setDouble(_keyLineSpacing, value);
}
