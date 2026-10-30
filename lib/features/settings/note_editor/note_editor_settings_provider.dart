import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/shared_preference/shared_preference_manager.dart';

/// Configuration state holding user preferences for the note editor typography and focus.
class NoteEditorSettings {
  /// Whether the editor should automatically place cursor focus on note content body.
  final bool putCursorOnContent;

  /// Font size applied to note title text field in pixels. Defaults to `22.0`.
  final double titleFontSize;

  /// Font size applied to note content body text field in pixels. Defaults to `16.0`.
  final double contentFontSize;

  /// Line spacing height multiplier applied to note content text field. Defaults to `1.5`.
  final double lineSpacing;

  const NoteEditorSettings({
    this.putCursorOnContent = true,
    this.titleFontSize = 22.0,
    this.contentFontSize = 16.0,
    this.lineSpacing = 1.5,
  });

  /// Creates a copy of [NoteEditorSettings] with updated attributes.
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteEditorSettings &&
        other.putCursorOnContent == putCursorOnContent &&
        other.titleFontSize == titleFontSize &&
        other.contentFontSize == contentFontSize &&
        other.lineSpacing == lineSpacing;
  }

  @override
  int get hashCode => Object.hash(
        putCursorOnContent,
        titleFontSize,
        contentFontSize,
        lineSpacing,
      );
}

/// Riverpod [Notifier] managing note editor preferences state and local storage persistence.
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

  /// Sets whether the cursor automatically focuses content on editor open.
  Future<void> setPutCursorOnContent(bool value) async {
    await _prefs.setPutCursorOnContent(value);
    state = state.copyWith(putCursorOnContent: value);
  }

  /// Sets note title font size in pixels.
  Future<void> setTitleFontSize(double value) async {
    await _prefs.setTitleFontSize(value);
    state = state.copyWith(titleFontSize: value);
  }

  /// Sets note content body font size in pixels.
  Future<void> setContentFontSize(double value) async {
    await _prefs.setContentFontSize(value);
    state = state.copyWith(contentFontSize: value);
  }

  /// Sets note content line spacing height multiplier.
  Future<void> setLineSpacing(double value) async {
    await _prefs.setLineSpacing(value);
    state = state.copyWith(lineSpacing: value);
  }

  /// Restores all note editor settings to factory default values.
  Future<void> resetToDefaults() async {
    await _prefs.setPutCursorOnContent(true);
    await _prefs.setTitleFontSize(22.0);
    await _prefs.setContentFontSize(16.0);
    await _prefs.setLineSpacing(1.5);
    state = const NoteEditorSettings();
  }
}

/// Global Riverpod provider for note editor preferences state.
final noteEditorSettingsProvider =
    NotifierProvider<NoteEditorSettingsNotifier, NoteEditorSettings>(
  NoteEditorSettingsNotifier.new,
);
