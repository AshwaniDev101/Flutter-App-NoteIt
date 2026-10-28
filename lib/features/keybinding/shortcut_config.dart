import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/helpers/platform_helper.dart';
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
    if (state != isHeld) state = isHeld;
  }
}

// THE DATABASE TRANSLATOR
final keybindingsProvider = StreamProvider<Map<String, ShortcutConfig>>((ref) {
  final dao = ref.watch(keybindingsDaoProvider);

  // Detect the current operating system ('windows', 'macos', 'android', etc.)
  final currentPlatform = PlatformHelper.name.toLowerCase();

  // Pass the platform so we only seed defaults for this specific OS
  dao.seedDefaultKeybindings(currentPlatform);

  // Watch only the shortcuts for this specific platform
  return dao.watchKeybindingsForPlatform(currentPlatform).map((rows) {
    final map = <String, ShortcutConfig>{};

    for (final row in rows) {
      // If disabledAt has a timestamp, the user turned it off.
      if (row.disabledAt != null) continue;

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