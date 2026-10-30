import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helpers/platform_helper.dart';
import '../../../database/drift/keybindings/keybindings_dao.dart';
import '../../../shared/overlays/app_scaffold.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../../home/view/desktop/content_panel/core/navigator.dart';
import '../../keybinding/keybindings_provider.dart';
import '../../keybinding/shortcut_config.dart';

class KeybindingActionMeta {
  final String actionName;
  final String title;
  final String description;
  final ShortcutScope scope;
  final String category;
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

const List<KeybindingActionMeta> _allActionsMeta = [
  KeybindingActionMeta(
    actionName: AppActions.newNote,
    title: 'New Note',
    description: 'Creates a new blank note in the active folder',
    scope: ShortcutScope.global,
    category: 'Global Actions',
    icon: Icons.add_circle_outline_rounded,
  ),
  KeybindingActionMeta(
    actionName: AppActions.toggleMenu,
    title: 'Toggle Navigation Drawer',
    description: 'Opens or closes the left navigation drawer',
    scope: ShortcutScope.global,
    category: 'Global Actions',
    icon: Icons.menu_open_rounded,
  ),
  KeybindingActionMeta(
    actionName: AppActions.search,
    title: 'Left Panel Search',
    description: 'Focuses the search bar in the left panel list',
    scope: ShortcutScope.listPanel,
    category: 'Left Panel Search',
    icon: Icons.search_rounded,
  ),
  KeybindingActionMeta(
    actionName: AppActions.saveNote,
    title: 'Save Note',
    description: 'Saves current note manually and triggers cloud/local sync',
    scope: ShortcutScope.editor,
    category: 'Note Editor Actions',
    icon: Icons.save_outlined,
  ),
  KeybindingActionMeta(
    actionName: AppActions.findInNote,
    title: 'Find in Note',
    description: 'Opens the in-editor Find & Replace overlay',
    scope: ShortcutScope.editor,
    category: 'Note Editor Actions',
    icon: Icons.find_in_page_outlined,
  ),
];

class KeybindingSettingsPage extends ConsumerStatefulWidget {
  const KeybindingSettingsPage({super.key});

  @override
  ConsumerState<KeybindingSettingsPage> createState() => _KeybindingSettingsPageState();
}

class _KeybindingSettingsPageState extends ConsumerState<KeybindingSettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dao = ref.watch(keybindingsDaoProvider);
    final platform = PlatformHelper.name.toLowerCase();

    final shortcutsAsync = ref.watch(keybindingsProvider);

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.keybindingSettings,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.settings);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Keyboard Shortcuts',
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: const Text('Reset All'),
                        onPressed: () => _confirmResetAll(context, dao, platform),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Filter Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Filter shortcuts by name or action...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim().toLowerCase());
                    },
                  ),

                  const SizedBox(height: 24),

                  shortcutsAsync.when(
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                    error: (err, stack) => Center(child: Text('Error loading keybindings: $err')),
                    data: (shortcuts) {
                      final filteredActions = _allActionsMeta.where((meta) {
                        if (_searchQuery.isEmpty) return true;
                        return meta.title.toLowerCase().contains(_searchQuery) ||
                            meta.description.toLowerCase().contains(_searchQuery) ||
                            meta.category.toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (filteredActions.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No matching shortcuts found',
                              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        );
                      }

                      // Group actions by Category
                      final Map<String, List<KeybindingActionMeta>> categories = {};
                      for (final action in filteredActions) {
                        categories.putIfAbsent(action.category, () => []).add(action);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: categories.entries.map((entry) {
                          return _buildCategoryCard(
                            context: context,
                            categoryTitle: entry.key,
                            actions: entry.value,
                            shortcuts: shortcuts,
                            dao: dao,
                            platform: platform,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String categoryTitle,
    required List<KeybindingActionMeta> actions,
    required Map<String, ShortcutConfig> shortcuts,
    required KeybindingsDao dao,
    required String platform,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              categoryTitle,
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 56,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              itemBuilder: (context, index) {
                final meta = actions[index];
                final config = shortcuts[meta.actionName];
                final isEnabled = config != null;

                return _buildShortcutRow(
                  context: context,
                  meta: meta,
                  config: config,
                  isEnabled: isEnabled,
                  dao: dao,
                  platform: platform,
                  allShortcuts: shortcuts,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow({
    required BuildContext context,
    required KeybindingActionMeta meta,
    required ShortcutConfig? config,
    required bool isEnabled,
    required KeybindingsDao dao,
    required String platform,
    required Map<String, ShortcutConfig> allShortcuts,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(meta.icon, color: isEnabled ? colorScheme.primary : colorScheme.outline),
      title: Row(
        children: [
          Text(meta.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          _buildScopeBadge(context, meta.scope),
        ],
      ),
      subtitle: Text(
        meta.description,
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Key Combination Chips Button
          InkWell(
            onTap: () => _openRecordDialog(
              context: context,
              meta: meta,
              config: config,
              dao: dao,
              platform: platform,
              allShortcuts: allShortcuts,
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isEnabled ? colorScheme.secondaryContainer.withValues(alpha: 0.5) : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isEnabled ? colorScheme.secondary.withValues(alpha: 0.3) : colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                config != null ? config.formattedLabel : '(Disabled)',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? colorScheme.onSecondaryContainer : colorScheme.outline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Revert Button
          IconButton(
            icon: const Icon(Icons.restore_rounded, size: 18),
            tooltip: 'Reset shortcut to default',
            onPressed: () async {
              await dao.resetKeybinding(meta.actionName, platform);
              if (context.mounted) {
                SnackBarManager.show(msg: '${meta.title} shortcut reset');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScopeBadge(BuildContext context, ShortcutScope scope) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    String label;
    Color bg;
    Color fg;

    switch (scope) {
      case ShortcutScope.global:
        label = 'Global';
        bg = colorScheme.surfaceContainerHighest;
        fg = colorScheme.onSurfaceVariant;
        break;
      case ShortcutScope.listPanel:
        label = 'Left Panel';
        bg = colorScheme.tertiaryContainer;
        fg = colorScheme.onTertiaryContainer;
        break;
      case ShortcutScope.editor:
        label = 'Editor';
        bg = colorScheme.primaryContainer;
        fg = colorScheme.onPrimaryContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Future<void> _confirmResetAll(BuildContext context, KeybindingsDao dao, String platform) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Shortcuts?'),
        content: const Text('This will restore all keyboard shortcuts across all panels to system defaults.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await dao.resetAllKeybindings(platform);
      if (context.mounted) {
        SnackBarManager.show(msg: 'All shortcuts reset to defaults');
      }
    }
  }

  void _openRecordDialog({
    required BuildContext context,
    required KeybindingActionMeta meta,
    required ShortcutConfig? config,
    required KeybindingsDao dao,
    required String platform,
    required Map<String, ShortcutConfig> allShortcuts,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return KeybindingRecorderDialog(
          meta: meta,
          initialConfig: config,
          dao: dao,
          platform: platform,
          allShortcuts: allShortcuts,
        );
      },
    );
  }
}

class KeybindingRecorderDialog extends StatefulWidget {
  final KeybindingActionMeta meta;
  final ShortcutConfig? initialConfig;
  final KeybindingsDao dao;
  final String platform;
  final Map<String, ShortcutConfig> allShortcuts;

  const KeybindingRecorderDialog({
    super.key,
    required this.meta,
    required this.initialConfig,
    required this.dao,
    required this.platform,
    required this.allShortcuts,
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

    final isMac = widget.platform == 'macos';

    for (final entry in widget.allShortcuts.entries) {
      if (entry.key == widget.meta.actionName) continue;

      final metaOther = _allActionsMeta.firstWhere(
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
          _conflictMessage = 'Conflict: Already assigned to "${metaOther.title}" in ${metaOther.category}';
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
    if (key == LogicalKeyboardKey.escape && !_ctrlPressed && !_altPressed && !_shiftPressed && !_metaPressed) {
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
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
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

                // Manual Modifier Checkboxes for Convenience
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
                        Icon(Icons.warning_amber_rounded, size: 20, color: colorScheme.onErrorContainer),
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
