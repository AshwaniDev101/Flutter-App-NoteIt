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
final modifierHeldProvider = NotifierProvider<ModifierHeldNotifier, bool>(
      () => ModifierHeldNotifier(),
);



// Tracks if the user is currently holding the modifier key (Ctrl/Cmd)
class ModifierHeldNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void updateState(bool isHeld) {
    if (state != isHeld) state = isHeld;
  }
}




final keybindingsProvider = StreamProvider<Map<String, ShortcutConfig>>((ref) {
  final dao = ref.watch(keybindingsDaoProvider);

  // Seed defaults immediately if the table is empty
  dao.seedDefaultKeybindings();

  return dao.watchAllKeybindings().map((rows) {
    final map = <String, ShortcutConfig>{};

    for (final row in rows) {
      if (!row.isEnabled) continue; // Skip if user disabled it in settings

      map[row.actionName] = ShortcutConfig(
        label: row.keyLabel,
        activator: SingleActivator(
          LogicalKeyboardKey(row.keyId),
          control: row.useCtrl,
          alt: row.useAlt,
          shift: row.useShift,
          meta: row.useMeta,
        ),
      );
    }
    return map;
  });
});