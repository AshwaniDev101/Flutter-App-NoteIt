import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'keybindings_provider.dart';
import 'shortcut_config.dart';

class SmartActionWidget extends ConsumerWidget {
  final String action;
  final String baseTooltip;
  final Widget child;

  const SmartActionWidget({
    super.key,
    required this.action,
    required this.baseTooltip,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(shortcutPreferencesProvider);
    final showModifierHints = ref.watch(modifierHeldProvider);

    // Fallback to empty map if still loading from drift
    final shortcuts = ref.watch(keybindingsProvider).value ?? {};
    final config = shortcuts[action];

    // Calculate Tooltip Text
    String finalTooltip = baseTooltip;
    if (prefs.appendShortcutToTooltips && config != null) {
      finalTooltip = '$baseTooltip ${config.formattedLabel}';
    }

    // Build the base content with the Tooltip
    // If baseTooltip is empty, we don't wrap it in a tooltip to avoid blank hovers
    Widget content = finalTooltip.isEmpty
        ? child
        : Tooltip(
      message: finalTooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: child,
    );

    // Add Dynamic Key Hint Overlay if enabled, shortcut exists, and Ctrl is held
    if (prefs.showDynamicKeyHints && showModifierHints && config != null) {
      final colorScheme = Theme.of(context).colorScheme;

      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: -6,
            right: -6,
            child: IgnorePointer( // Prevents the badge from stealing mouse clicks
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  border: Border.all(color: colorScheme.onSurface, width: 1),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
                child: Text(
                  config.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return content;
  }
}