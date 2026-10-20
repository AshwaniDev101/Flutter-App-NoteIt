import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/util/platform_helper.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../shared/app_scaffold.dart';
import '../../../shared/snack_bar_manager.dart';
import '../../../shared/view_menu_button.dart';
import '../../home/core/db_sorting_filtering.dart';
import 'package:noteit/features/home/core/providers.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import '../../others/archive_page.dart';
import '../../others/trash_page.dart';

class DefaultSettingsPage extends ConsumerStatefulWidget {
  const DefaultSettingsPage({super.key});

  @override
  ConsumerState<DefaultSettingsPage> createState() => _DefaultSettingsPageState();
}

class _DefaultSettingsPageState extends ConsumerState<DefaultSettingsPage> {
  late NoteViewType _homeDefaultView;
  late NoteSortPreference _homeDefaultSort;

  late NoteViewType _archiveDefaultView;
  late NoteSortPreference _archiveDefaultSort;

  late NoteViewType _trashDefaultView;
  late NoteSortPreference _trashDefaultSort;

  late double _defaultWindowWidth;
  late double _defaultWindowHeight;
  late double _defaultListPanelWidth;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  void _loadDefaults() {
    final prefs = SharedPreferenceManager.instance;
    _homeDefaultView = prefs.getDefaultPageViewType('home');
    _homeDefaultSort = prefs.getDefaultPageSortOption('home');

    _archiveDefaultView = prefs.getDefaultPageViewType('archive');
    _archiveDefaultSort = prefs.getDefaultPageSortOption('archive');

    _trashDefaultView = prefs.getDefaultPageViewType('trash');
    _trashDefaultSort = prefs.getDefaultPageSortOption('trash');

    _defaultWindowWidth = prefs.getDefaultWindowWidth();
    _defaultWindowHeight = prefs.getDefaultWindowHeight();
    _defaultListPanelWidth = prefs.getDefaultListPanelWidth();
  }

  void _refreshProviders() {
    ref.invalidate(homeNoteViewTypeProvider);
    ref.invalidate(homeNoteSortPreferenceProvider);
    ref.invalidate(archiveNoteViewTypeProvider);
    ref.invalidate(archiveNoteSortPreferenceProvider);
    ref.invalidate(trashNoteViewTypeProvider);
    ref.invalidate(trashNoteSortPreferenceProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.defaultSettings,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
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
                        'Default Views & Layout',
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // PAGE DEFAULTS SECTION
                  _buildSectionHeader('Default Page Views & Sorting', colorScheme, textTheme),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildPageDefaultConfigTile(
                            pageTitle: 'Home Page',
                            currentView: _homeDefaultView,
                            currentSort: _homeDefaultSort,
                            onViewChanged: (view) async {
                              await SharedPreferenceManager.instance.setDefaultPageViewType('home', view);
                              setState(() => _homeDefaultView = view);
                              _refreshProviders();
                            },
                            onSortChanged: (sort) async {
                              await SharedPreferenceManager.instance.setDefaultPageSortOption('home', sort);
                              setState(() => _homeDefaultSort = sort);
                              _refreshProviders();
                            },
                          ),
                          const Divider(height: 24),
                          _buildPageDefaultConfigTile(
                            pageTitle: 'Archive Page',
                            currentView: _archiveDefaultView,
                            currentSort: _archiveDefaultSort,
                            onViewChanged: (view) async {
                              await SharedPreferenceManager.instance.setDefaultPageViewType('archive', view);
                              setState(() => _archiveDefaultView = view);
                              _refreshProviders();
                            },
                            onSortChanged: (sort) async {
                              await SharedPreferenceManager.instance.setDefaultPageSortOption('archive', sort);
                              setState(() => _archiveDefaultSort = sort);
                              _refreshProviders();
                            },
                          ),
                          const Divider(height: 24),
                          _buildPageDefaultConfigTile(
                            pageTitle: 'Trash Page',
                            currentView: _trashDefaultView,
                            currentSort: _trashDefaultSort,
                            onViewChanged: (view) async {
                              await SharedPreferenceManager.instance.setDefaultPageViewType('trash', view);
                              setState(() => _trashDefaultView = view);
                              _refreshProviders();
                            },
                            onSortChanged: (sort) async {
                              await SharedPreferenceManager.instance.setDefaultPageSortOption('trash', sort);
                              setState(() => _trashDefaultSort = sort);
                              _refreshProviders();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // DESKTOP LAYOUT SECTION
                  if (PlatformHelper.isNativeDesktop) ...[
                    _buildSectionHeader('Desktop Layout Defaults', colorScheme, textTheme),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Middle Panel Width
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Default Middle Panel Width',
                                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${_defaultListPanelWidth.round()} px',
                                  style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Slider(
                              value: _defaultListPanelWidth,
                              min: 250,
                              max: 600,
                              divisions: 35,
                              label: '${_defaultListPanelWidth.round()} px',
                              onChanged: (value) async {
                                setState(() => _defaultListPanelWidth = value);
                                await SharedPreferenceManager.instance.setDefaultListPanelWidth(value);
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.straighten, size: 16),
                                label: const Text('Use Current Middle Panel Width'),
                                onPressed: () async {
                                  final currentWidth = SharedPreferenceManager.instance.listPanelWidth;
                                  setState(() => _defaultListPanelWidth = currentWidth);
                                  await SharedPreferenceManager.instance.setDefaultListPanelWidth(currentWidth);
                                  if (context.mounted) {
                                    SnackBarManager.show(msg: 'Set default panel width to ${currentWidth.round()}px');
                                  }
                                },
                              ),
                            ),

                            const Divider(height: 24),

                            // Window Size
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Default Window Size',
                                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${_defaultWindowWidth.round()} x ${_defaultWindowHeight.round()} px',
                                  style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.aspect_ratio),
                                    label: const Text('Set to Current Window Size'),
                                    onPressed: () async {
                                      final size = await windowManager.getSize();
                                      _applyWindowSizePreset(size.width, size.height, '${size.width.round()}x${size.height.round()}');
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            Text(
                              'Preset Window Sizes',
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildWindowSizePresetChip(
                                  label: 'Fullscreen',
                                  subtitle: 'Screen Max',
                                  icon: Icons.fullscreen_rounded,
                                  onSelected: () async {
                                    final screenSize = MediaQuery.of(context).size;
                                    final width = screenSize.width > 0 ? screenSize.width : 1920.0;
                                    final height = screenSize.height > 0 ? screenSize.height : 1080.0;
                                    _applyWindowSizePreset(width, height, 'Fullscreen (${width.round()}x${height.round()})');
                                  },
                                ),
                                _buildWindowSizePresetChip(
                                  label: 'Large Size',
                                  subtitle: '1600 x 1000',
                                  icon: Icons.desktop_windows_outlined,
                                  onSelected: () {
                                    _applyWindowSizePreset(1600, 1000, 'Large Size (1600x1000)');
                                  },
                                ),
                                _buildWindowSizePresetChip(
                                  label: 'Medium Size',
                                  subtitle: '1400 x 900',
                                  icon: Icons.laptop_outlined,
                                  onSelected: () {
                                    _applyWindowSizePreset(1400, 900, 'Medium Size (1400x900)');
                                  },
                                ),
                                _buildWindowSizePresetChip(
                                  label: 'Compact Size',
                                  subtitle: '1024 x 700',
                                  icon: Icons.stay_current_portrait_outlined,
                                  onSelected: () {
                                    _applyWindowSizePreset(1024, 700, 'Compact Size (1024x700)');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // RESET ACTIONS SECTION
                  _buildSectionHeader('Reset & Maintenance', colorScheme, textTheme),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.restart_alt, color: Colors.orange),
                          title: const Text('Reset Page Views to Defaults'),
                          subtitle: const Text('Clears page-specific view/sort overrides and uses configured defaults'),
                          onTap: () async {
                            await SharedPreferenceManager.instance.resetPageViewsAndSortsToDefaults();
                            _refreshProviders();
                            if (context.mounted) {
                              SnackBarManager.show(msg: 'Page views and sorts reset to defaults');
                            }
                          },
                        ),
                        Divider(height: 1, indent: 64, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ListTile(
                          leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                          title: const Text('Clear All Preferences'),
                          subtitle: const Text('Resets all app settings, views, and cached preferences to factory defaults'),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Clear All Preferences?'),
                                content: const Text('This will reset all app settings, themes, and views to default values.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await SharedPreferenceManager.instance.clearAll();
                              setState(() {
                                _loadDefaults();
                              });
                              _refreshProviders();
                              if (context.mounted) {
                                SnackBarManager.show(msg: 'All preferences cleared successfully');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _applyWindowSizePreset(double width, double height, String label) async {
    setState(() {
      _defaultWindowWidth = width;
      _defaultWindowHeight = height;
    });
    await SharedPreferenceManager.instance.setDefaultWindowWidth(width);
    await SharedPreferenceManager.instance.setDefaultWindowHeight(height);
    if (mounted) {
      SnackBarManager.show(msg: 'Set default window size to $label');
    }
  }

  Widget _buildWindowSizePresetChip({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ActionChip(
      avatar: Icon(icon, size: 16, color: colorScheme.primary),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          Text(subtitle, style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: onSelected,
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPageDefaultConfigTile({
    required String pageTitle,
    required NoteViewType currentView,
    required NoteSortPreference currentSort,
    required ValueChanged<NoteViewType> onViewChanged,
    required ValueChanged<NoteSortPreference> onSortChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pageTitle, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Default View', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  InputDecorator(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<NoteViewType>(
                        value: currentView,
                        isExpanded: true,
                        items: NoteViewType.values.map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Row(
                              children: [
                                Icon(v.icon, size: 18),
                                const SizedBox(width: 8),
                                Text(v.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onViewChanged(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Default Sort', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  InputDecorator(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<NoteSortPreference>(
                        value: currentSort,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: NoteSortPreference.createdAt,
                            child: Text('Created Date'),
                          ),
                          DropdownMenuItem(
                            value: NoteSortPreference.name,
                            child: Text('Alphabetically'),
                          ),
                          DropdownMenuItem(
                            value: NoteSortPreference.updatedAt,
                            child: Text('Modified Date'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) onSortChanged(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
