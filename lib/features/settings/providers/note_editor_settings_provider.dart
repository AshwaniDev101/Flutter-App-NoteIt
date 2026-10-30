import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/shared_preference/shared_preference_manager.dart';

class NoteEditorSettings {
  final bool putCursorOnContent;
  final double titleFontSize;
  final double contentFontSize;
  final double lineSpacing;

  const NoteEditorSettings({
    this.putCursorOnContent = true,
    this.titleFontSize = 22.0,
    this.contentFontSize = 16.0,
    this.lineSpacing = 1.5,
  });

  NoteEditorSettings copyWith({
    bool? putCursorOnContent,
    double? titleFontSize,
    double? contentFontSize,
    double? lineSpacing,
  }) {
    return NoteEditorSettings(
      putCursorOnContent: putCursorOnContent ?? this.putCursorOnContent,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      contentFontSize: contentFontSize ?? this.contentFontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
    );
  }
}

class NoteEditorSettingsNotifier extends Notifier<NoteEditorSettings> {
  late final SharedPreferenceManager _prefs;

  @override
  NoteEditorSettings build() {
    _prefs = ref.watch(sharedPreferenceProvider);

    return NoteEditorSettings(
      putCursorOnContent: _prefs.putCursorOnContent,
      titleFontSize: _prefs.titleFontSize,
      contentFontSize: _prefs.contentFontSize,
      lineSpacing: _prefs.lineSpacing,
    );
  }

  Future<void> setPutCursorOnContent(bool value) async {
    await _prefs.setPutCursorOnContent(value);
    state = state.copyWith(putCursorOnContent: value);
  }

  Future<void> setTitleFontSize(double value) async {
    await _prefs.setTitleFontSize(value);
    state = state.copyWith(titleFontSize: value);
  }

  Future<void> setContentFontSize(double value) async {
    await _prefs.setContentFontSize(value);
    state = state.copyWith(contentFontSize: value);
  }

  Future<void> setLineSpacing(double value) async {
    await _prefs.setLineSpacing(value);
    state = state.copyWith(lineSpacing: value);
  }

  Future<void> resetToDefaults() async {
    await _prefs.setPutCursorOnContent(true);
    await _prefs.setTitleFontSize(22.0);
    await _prefs.setContentFontSize(16.0);
    await _prefs.setLineSpacing(1.5);
    state = const NoteEditorSettings();
  }
}

final noteEditorSettingsProvider =
    NotifierProvider<NoteEditorSettingsNotifier, NoteEditorSettings>(
  NoteEditorSettingsNotifier.new,
);
