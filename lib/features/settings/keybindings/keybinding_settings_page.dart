import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helpers/platform_helper.dart';
import '../../../database/drift/keybindings/keybindings_dao.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../../home/view/desktop/content_panel/core/navigator.dart';
import '../../keybinding/shortcut_config.dart';
import '../common/settings_widgets.dart';
import 'widgets/keybinding_recorder_dialog.dart';

/// Predefined list of keybinding action metadata.
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

/// Settings page for viewing, searching, recording, and resetting keyboard shortcuts.
class KeybindingSettingsPage extends ConsumerStatefulWidget {
  const KeybindingSettingsPage({super.key});

  @override
  ConsumerState<KeybindingSettingsPage> createState() =>
      _KeybindingSettingsPageState();
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

    return SettingsPageLayout(
      option: RightPanelPageOptions.keybindingSettings,
      maxWidth: 700.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          SettingsPageHeader(
            title: 'Keyboard Shortcuts',
            actions: [
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Reset All'),
                onPressed: () => _confirmResetAll(context, dao, platform),
              ),
            ],
          ),

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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => Center(
              child: Text('Error loading keybindings: $err'),
            ),
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
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
                  return _buildCategorySection(
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
    );
  }

  Widget _buildCategorySection({
    required BuildContext context,
    required String categoryTitle,
    required List<KeybindingActionMeta> actions,
    required Map<String, ShortcutConfig> shortcuts,
    required KeybindingsDao dao,
    required String platform,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionHeader(title: categoryTitle),
          SettingsCard(
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
      leading: Icon(
        meta.icon,
        color: isEnabled ? colorScheme.primary : colorScheme.outline,
      ),
      title: Row(
        children: [
          Text(
            meta.title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          _buildScopeBadge(context, meta.scope),
        ],
      ),
      subtitle: Text(
        meta.description,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
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
                color: isEnabled
                    ? colorScheme.secondaryContainer.withValues(alpha: 0.5)
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isEnabled
                      ? colorScheme.secondary.withValues(alpha: 0.3)
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                config != null ? config.formattedLabel : '(Disabled)',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isEnabled
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.outline,
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
        style: textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Future<void> _confirmResetAll(
    BuildContext context,
    KeybindingsDao dao,
    String platform,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Shortcuts?'),
        content: const Text(
          'This will restore all keyboard shortcuts across all panels to system defaults.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
          allActionsMeta: _allActionsMeta,
        );
      },
    );
  }
}
