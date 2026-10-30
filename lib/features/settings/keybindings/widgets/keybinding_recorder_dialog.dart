import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../database/drift/keybindings/keybindings_dao.dart';
import '../../../../shared/overlays/snack_bar_manager.dart';
import '../../../keybinding/shortcut_config.dart';

/// Metadata model describing a configurable keybinding action.
class KeybindingActionMeta {
  /// Internal system name of the action (from [AppActions]).
  final String actionName;

  /// User-friendly display title.
  final String title;

  /// Detailed description explaining what the shortcut triggers.
  final String description;

  /// Contextual scope where the shortcut is active ([ShortcutScope]).
  final ShortcutScope scope;

  /// Category section title for grouping actions in UI.
  final String category;

  /// Visual icon associated with the action.
  final IconData icon;

  const KeybindingActionMeta({
    required this.actionName,
    required this.title,
    required this.description,
    required this.scope,
    required this.category,
    required this.icon,
  });
}

/// Interactive modal dialog allowing users to record and bind a custom key combination.
class KeybindingRecorderDialog extends StatefulWidget {
  final KeybindingActionMeta meta;
  final ShortcutConfig? initialConfig;
  final KeybindingsDao dao;
  final String platform;
  final Map<String, ShortcutConfig> allShortcuts;
  final List<KeybindingActionMeta> allActionsMeta;

  const KeybindingRecorderDialog({
    super.key,
    required this.meta,
    required this.initialConfig,
    required this.dao,
    required this.platform,
    required this.allShortcuts,
    required this.allActionsMeta,
  });

  @override
  State<KeybindingRecorderDialog> createState() => _KeybindingRecorderDialogState();
}

class _KeybindingRecorderDialogState extends State<KeybindingRecorderDialog> {
  bool _ctrlPressed = false;
  bool _altPressed = false;
  bool _shiftPressed = false;
  bool _metaPressed = false;

  LogicalKeyboardKey? _primaryKey;
  String? _primaryKeyLabel;

  String? _conflictMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      final act = widget.initialConfig!.activator;
      _ctrlPressed = act.control;
      _altPressed = act.alt;
      _shiftPressed = act.shift;
      _metaPressed = act.meta;
      _primaryKey = act.trigger;
      _primaryKeyLabel = widget.initialConfig!.label;
    }
    _checkConflicts();
  }

  void _checkConflicts() {
    if (_primaryKey == null) {
      setState(() => _conflictMessage = null);
      return;
    }

    for (final entry in widget.allShortcuts.entries) {
      if (entry.key == widget.meta.actionName) continue;

      final metaOther = widget.allActionsMeta.firstWhere(
        (m) => m.actionName == entry.key,
        orElse: () => KeybindingActionMeta(
          actionName: entry.key,
          title: entry.key,
          description: '',
          scope: ShortcutScope.global,
          category: 'Other',
          icon: Icons.keyboard,
        ),
      );

      // Check if both shortcuts reside in the SAME scope or if one is global
      final isSameScope = widget.meta.scope == metaOther.scope ||
          widget.meta.scope == ShortcutScope.global ||
          metaOther.scope == ShortcutScope.global;

      if (!isSameScope) continue;

      final act = entry.value.activator;
      final sameKey = act.trigger.keyId == _primaryKey!.keyId;
      final sameCtrl = act.control == _ctrlPressed;
      final sameAlt = act.alt == _altPressed;
      final sameShift = act.shift == _shiftPressed;
      final sameMeta = act.meta == _metaPressed;

      if (sameKey && sameCtrl && sameAlt && sameShift && sameMeta) {
        setState(() {
          _conflictMessage =
              'Conflict: Already assigned to "${metaOther.title}" in ${metaOther.category}';
        });
        return;
      }
    }

    setState(() => _conflictMessage = null);
  }

  String _formatLiveCombo() {
    final parts = <String>[];
    if (_ctrlPressed) parts.add('Ctrl');
    if (_metaPressed) parts.add('Cmd');
    if (_altPressed) parts.add('Alt');
    if (_shiftPressed) parts.add('Shift');

    if (_primaryKeyLabel != null && _primaryKeyLabel!.isNotEmpty) {
      parts.add(_primaryKeyLabel!);
    }

    if (parts.isEmpty) return 'Press keys...';
    return parts.join(' + ');
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // Check if modifier key
    if (key == LogicalKeyboardKey.controlLeft || key == LogicalKeyboardKey.controlRight) {
      setState(() => _ctrlPressed = !_ctrlPressed);
      _checkConflicts();
      return;
    }
    if (key == LogicalKeyboardKey.altLeft || key == LogicalKeyboardKey.altRight) {
      setState(() => _altPressed = !_altPressed);
      _checkConflicts();
      return;
    }
    if (key == LogicalKeyboardKey.shiftLeft || key == LogicalKeyboardKey.shiftRight) {
      setState(() => _shiftPressed = !_shiftPressed);
      _checkConflicts();
      return;
    }
    if (key == LogicalKeyboardKey.metaLeft || key == LogicalKeyboardKey.metaRight) {
      setState(() => _metaPressed = !_metaPressed);
      _checkConflicts();
      return;
    }

    // Cancel on single Escape key press without modifiers
    if (key == LogicalKeyboardKey.escape &&
        !_ctrlPressed &&
        !_altPressed &&
        !_shiftPressed &&
        !_metaPressed) {
      Navigator.pop(context);
      return;
    }

    String label = key.keyLabel;
    if (label.isEmpty || label.trim().isEmpty) {
      label = key.debugName ?? 'Key';
    } else {
      label = label.toUpperCase();
    }

    setState(() {
      _primaryKey = key;
      _primaryKeyLabel = label;
    });

    _checkConflicts();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final canSave = _primaryKey != null && _conflictMessage == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: _handleKeyEvent,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Record Shortcut',
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Action: ${widget.meta.title}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // Recorded Key Combination Display
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _conflictMessage != null ? colorScheme.error : colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _formatLiveCombo(),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _conflictMessage != null ? colorScheme.error : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Manual Modifier Checkboxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Ctrl'),
                      selected: _ctrlPressed,
                      onSelected: (val) {
                        setState(() => _ctrlPressed = val);
                        _checkConflicts();
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Alt'),
                      selected: _altPressed,
                      onSelected: (val) {
                        setState(() => _altPressed = val);
                        _checkConflicts();
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Shift'),
                      selected: _shiftPressed,
                      onSelected: (val) {
                        setState(() => _shiftPressed = val);
                        _checkConflicts();
                      },
                    ),
                  ],
                ),

                if (_conflictMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _conflictMessage!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: canSave
                          ? () async {
                              await widget.dao.updateKeybinding(
                                widget.meta.actionName,
                                targetPlatform: widget.platform,
                                keyLabel: _primaryKeyLabel!,
                                keyId: _primaryKey!.keyId,
                                useCtrl: _ctrlPressed,
                                useAlt: _altPressed,
                                useShift: _shiftPressed,
                                useMeta: _metaPressed,
                                isEnabled: true,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                SnackBarManager.show(msg: 'Shortcut saved!');
                              }
                            }
                          : null,
                      child: const Text('Save Shortcut'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
