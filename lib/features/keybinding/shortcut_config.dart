import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/drift/keybindings/keybindings_dao.dart';

class ShortcutConfig {
  final SingleActivator activator;
  final String label;

  ShortcutConfig({required this.activator, required this.label});

  // Automatically builds strings like "(Ctrl + Shift + N)" or "(Alt + M)"
  String get formattedLabel {
    final parts = <String>[];
    if (activator.control) parts.add('Ctrl');
    if (activator.meta) parts.add('Cmd');
    if (activator.alt) parts.add('Alt');
    if (activator.shift) parts.add('Shift');
    parts.add(label);

    return '(${parts.join('+')})';
  }
}

final modifierHeldProvider = NotifierProvider<ModifierHeldNotifier, bool>(() => ModifierHeldNotifier());

// Tracks if the user is currently holding the modifier key (Ctrl/Cmd)
class ModifierHeldNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void updateState(bool isHeld) {
    // Keyboards send hundreds of signals a second when a key is held down. This check ensures we only rebuild the UI when the key first goes down or first comes up,
    // Only update the state (which triggers UI rebuilds) if the value actually changed.
    // If the user is holding the key down, it stays 'true' without spamming updates.
    if (state != isHeld) state = isHeld;
  }
}

// THE DATABASE TRANSLATOR
// This provides a live, continuously updating stream of our shortcuts.
// It outputs a Map (a dictionary) where:
// Key = The action name (, 'new_note')
// Value = The ShortcutConfig (contains the UI label and the Flutter keyboard listener)
final keybindingsProvider = StreamProvider<Map<String, ShortcutConfig>>((ref) {
  // Connect to our Drift database
  final dao = ref.watch(keybindingsDaoProvider);

  // If the user just installed the app and the table is empty,
  // insert the default shortcuts (Ctrl+N, Ctrl+M, etc.) so it isn't blank.
  dao.seedDefaultKeybindings();

  // Listen to the database table for ANY changes (like if the user edits settings).
  return dao.watchAllKeybindings().map((rows) {
    // Create an empty dictionary to hold the translated results
    final map = <String, ShortcutConfig>{};

    // Loop through every row currently in the database
    for (final row in rows) {
      // If the user turned this shortcut off in settings, skip it entirely.
      if (!row.isEnabled) continue;

      // Translate the raw database row into our custom ShortcutConfig object
      map[row.actionName] = ShortcutConfig(
        label: row.keyLabel, // The visual text for the yellow badge ("N")
        // SingleActivator is the official Flutter class that actually catches keystrokes.
        // We build it using the raw booleans and IDs saved in Drift.
        activator: SingleActivator(
          LogicalKeyboardKey(row.keyId), // The specific key ('N' or 'S')
          control: row.useCtrl, // Should they hold Ctrl?
          alt: row.useAlt, // Should they hold Alt?
          shift: row.useShift, // Should they hold Shift?
          meta: row.useMeta, // Should they hold Cmd (Mac)?
        ),
      );
    }

    // Return the final dictionary to the app!
    return map;
  });
});
