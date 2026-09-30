import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/shared_preference/shared_preference_manager.dart';

class ShortcutPreferences {
  final bool showDynamicKeyHints;
  final bool appendShortcutToTooltips;

  const ShortcutPreferences({
    this.showDynamicKeyHints = true,
    this.appendShortcutToTooltips = true,
  });

  ShortcutPreferences copyWith({
    bool? showDynamicKeyHints,
    bool? appendShortcutToTooltips,
  }) {
    return ShortcutPreferences(
      showDynamicKeyHints: showDynamicKeyHints ?? this.showDynamicKeyHints,
      appendShortcutToTooltips: appendShortcutToTooltips ?? this.appendShortcutToTooltips,
    );
  }
}

class ShortcutPreferencesNotifier extends Notifier<ShortcutPreferences> {
  late final SharedPreferenceManager _prefs;

  @override
  ShortcutPreferences build() {
    // Grab the existing SharedPreferenceManager provider
    _prefs = ref.watch(sharedPreferenceProvider);

    // Load the initial state straight from disk
    return ShortcutPreferences(
      showDynamicKeyHints: _prefs.showDynamicKeyHints,
      appendShortcutToTooltips: _prefs.appendShortcutToTooltips,
    );
  }

  void toggleHints(bool value) {
    _prefs.setShowDynamicKeyHints(value); // Save to disk
    state = state.copyWith(showDynamicKeyHints: value); // Update UI instantly
  }

  void toggleTooltips(bool value) {
    _prefs.setAppendShortcutToTooltips(value); // Save to disk
    state = state.copyWith(appendShortcutToTooltips: value); // Update UI instantly
  }
}

final shortcutPreferencesProvider = NotifierProvider<ShortcutPreferencesNotifier, ShortcutPreferences>(
      () => ShortcutPreferencesNotifier(),
);