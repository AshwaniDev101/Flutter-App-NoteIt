import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/view/desktop/content_panel/core/navigator.dart';
import '../common/settings_widgets.dart';
import 'time_preferences_provider.dart';

/// Main settings page allowing users to configure date and time display preferences.
///
/// Features a modern card-based Material 3 layout with a live preview, system format toggle,
/// component format dropdowns, interactive drag-to-reorder chips, and separator selection.
class TimeSettingsPage extends ConsumerWidget {
  const TimeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final prefs = ref.watch(timePreferencesProvider);
    final notifier = ref.read(timePreferencesProvider.notifier);

    return SettingsPageLayout(
      option: RightPanelPageOptions.timeSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          SettingsPageHeader(
            title: 'Time & Date Format',
            subtitle: 'Customize how dates and timestamps appear across NoteIt',
            actions: [
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: 'Reset to Defaults',
                onPressed: () => notifier.resetToDefaults(),
              ),
            ],
          ),

          // --- 1. LIVE PREVIEW CARD ---
          SettingsCard(
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE PREVIEW',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Current Time',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  notifier.formatDateTime(DateTime.now()),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- 2. GENERAL OPTIONS CARD ---
          const SettingsSectionHeader(title: 'General Settings'),
          SettingsCard(
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.tune_rounded,
                  title: 'Copy System Format',
                  subtitle:
                      'Follow system locale settings and disable custom layout overrides',
                  value: prefs.useSystemFormat,
                  onChanged: (val) => notifier.toggleSystemFormat(val),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SettingsSwitchTile(
                  icon: Icons.access_time_rounded,
                  title: '24-Hour Clock',
                  subtitle: 'Display time as 14:30 instead of 2:30 PM',
                  value: prefs.is24Hour,
                  onChanged: prefs.useSystemFormat
                      ? null
                      : (val) => notifier.set24Hour(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- 3. CUSTOM FORMAT BUILDER ---
          AnimatedOpacity(
            opacity: prefs.useSystemFormat ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: prefs.useSystemFormat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. FORMAT COMPONENTS
                  const SettingsSectionHeader(title: 'Individual Component Formats'),
                  SettingsCard(
                    padding: const EdgeInsets.all(16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = (constraints.maxWidth - 16) / 2;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: itemWidth > 200
                                  ? itemWidth
                                  : constraints.maxWidth,
                              child: _buildDropdownTile(
                                context: context,
                                icon: Icons.calendar_today_rounded,
                                label: 'Day Format',
                                value: prefs.dayFormat,
                                items: const {
                                  'd': 'Numeric (1)',
                                  'dd': 'Two-digit (01)',
                                },
                                onChanged: (val) => notifier.setDayFormat(val!),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth > 200
                                  ? itemWidth
                                  : constraints.maxWidth,
                              child: _buildDropdownTile(
                                context: context,
                                icon: Icons.calendar_month_rounded,
                                label: 'Month Format',
                                value: prefs.monthFormat,
                                items: const {
                                  'M': 'Numeric (4)',
                                  'MM': 'Two-digit (04)',
                                  'MMM': 'Short Name (Apr)',
                                  'MMMM': 'Full Name (April)',
                                },
                                onChanged: (val) =>
                                    notifier.setMonthFormat(val!),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth > 200
                                  ? itemWidth
                                  : constraints.maxWidth,
                              child: _buildDropdownTile(
                                context: context,
                                icon: Icons.event_repeat_rounded,
                                label: 'Year Format',
                                value: prefs.yearFormat,
                                items: const {
                                  'yy': 'Two-digit (26)',
                                  'yyyy': 'Four-digit (2026)',
                                },
                                onChanged: (val) =>
                                    notifier.setYearFormat(val!),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth > 200
                                  ? itemWidth
                                  : constraints.maxWidth,
                              child: _buildDropdownTile(
                                context: context,
                                icon: Icons.schedule_rounded,
                                label: 'Time Display',
                                value: prefs.is24Hour ? '24' : '12',
                                items: const {
                                  '12': '12-Hour (5:30 PM)',
                                  '24': '24-Hour (17:30)',
                                },
                                onChanged: (val) =>
                                    notifier.set24Hour(val == '24'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // B. REORDERABLE SEQUENCE
                  const SettingsSectionHeader(title: 'Layout Sequence'),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'Drag chips horizontally to reorder how date and time parts appear',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SettingsCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: SizedBox(
                      height: 48,
                      child: ReorderableListView(
                        scrollDirection: Axis.horizontal,
                        buildDefaultDragHandles: false,
                        onReorderItem: (oldIndex, newIndex) =>
                            notifier.reorderPartsDirect(oldIndex, newIndex),
                        children: prefs.order.asMap().entries.map((entry) {
                          return _buildOrderChip(
                            index: entry.key,
                            part: entry.value,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // C. DATE SEPARATOR
                  const SettingsSectionHeader(title: 'Date Separator'),
                  SettingsCard(
                    padding: const EdgeInsets.all(16.0),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: '-', label: Text('Dash (-)')),
                        ButtonSegment(value: '/', label: Text('Slash (/)')),
                        ButtonSegment(value: '.', label: Text('Dot (.)')),
                        ButtonSegment(value: ' ', label: Text('Space')),
                      ],
                      selected: {prefs.separator},
                      onSelectionChanged: (set) =>
                          notifier.setSeparator(set.first),
                      style: SegmentedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget for rendering a labeled dropdown tile with thematic input decoration.
  Widget _buildDropdownTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              dropdownColor: colorScheme.surfaceContainerHigh,
              isExpanded: true,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              items: items.entries.map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// Helper widget for rendering a drag-to-reorder layout chip with sequence badge and styling.
  Widget _buildOrderChip({
    required int index,
    required FormatPart part,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return ReorderableDragStartListener(
      key: ValueKey(part),
      index: index,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.only(left: 10, right: 14, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 9,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                '${index + 1}',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              part.label,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
