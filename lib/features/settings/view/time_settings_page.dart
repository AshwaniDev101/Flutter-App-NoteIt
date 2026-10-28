import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteit/core/helpers/time_helper.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import '../../../shared/overlays/app_scaffold.dart';

// ============================================================================
// 1. STATE & LOGIC
// ============================================================================

/// Represents the individual components of date and time that can be arranged.
enum FormatPart {
  day('Day'),
  month('Month'),
  year('Year'),
  time('Time');

  final String label;
  const FormatPart(this.label);
}

/// Immutable state holding user preferences for date and time formatting.
class TimePreferencesState {
  /// Whether to follow the device system default format instead of custom options.
  final bool useSystemFormat;

  /// Whether 24-hour time display (e.g., 14:30) is enabled.
  final bool is24Hour;

  /// Day representation pattern ('d' or 'dd').
  final String dayFormat;

  /// Month representation pattern ('M', 'MM', 'MMM', 'MMMM').
  final String monthFormat;

  /// Year representation pattern ('yy' or 'yyyy').
  final String yearFormat;

  /// Separator symbol inserted between date parts ('-', '/', '.', ' ').
  final String separator;

  /// Ordered list specifying the sequence of day, month, year, and time components.
  final List<FormatPart> order;

  const TimePreferencesState({
    this.useSystemFormat = false,
    this.is24Hour = false,
    this.dayFormat = 'dd',
    this.monthFormat = 'MMM',
    this.yearFormat = 'yyyy',
    this.separator = '-',
    this.order = const [FormatPart.day, FormatPart.month, FormatPart.year, FormatPart.time],
  });

  TimePreferencesState copyWith({
    bool? useSystemFormat,
    bool? is24Hour,
    String? dayFormat,
    String? monthFormat,
    String? yearFormat,
    String? separator,
    List<FormatPart>? order,
  }) {
    return TimePreferencesState(
      useSystemFormat: useSystemFormat ?? this.useSystemFormat,
      is24Hour: is24Hour ?? this.is24Hour,
      dayFormat: dayFormat ?? this.dayFormat,
      monthFormat: monthFormat ?? this.monthFormat,
      yearFormat: yearFormat ?? this.yearFormat,
      separator: separator ?? this.separator,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimePreferencesState &&
        other.useSystemFormat == useSystemFormat &&
        other.is24Hour == is24Hour &&
        other.dayFormat == dayFormat &&
        other.monthFormat == monthFormat &&
        other.yearFormat == yearFormat &&
        other.separator == separator &&
        _listEquals(other.order, order);
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      useSystemFormat,
      is24Hour,
      dayFormat,
      monthFormat,
      yearFormat,
      separator,
      Object.hashAll(order),
    );
  }
}

/// Riverpod [Notifier] that manages date/time preferences and persists changes
/// to local storage via [SharedPreferenceManager].
class TimePreferencesNotifier extends Notifier<TimePreferencesState> {
  late final SharedPreferenceManager _prefs;

  @override
  TimePreferencesState build() {
    _prefs = ref.watch(sharedPreferenceProvider);

    final orderStrings = _prefs.timeOrder;
    final parsedOrder = orderStrings.map((s) {
      switch (s) {
        case 'day':
          return FormatPart.day;
        case 'month':
          return FormatPart.month;
        case 'year':
          return FormatPart.year;
        case 'time':
          return FormatPart.time;
        default:
          return FormatPart.day;
      }
    }).toList();

    return TimePreferencesState(
      useSystemFormat: _prefs.timeUseSystemFormat,
      is24Hour: _prefs.timeIs24Hour,
      dayFormat: _prefs.timeDayFormat,
      monthFormat: _prefs.timeMonthFormat,
      yearFormat: _prefs.timeYearFormat,
      separator: _prefs.timeSeparator,
      order: parsedOrder.isEmpty
          ? const [FormatPart.day, FormatPart.month, FormatPart.year, FormatPart.time]
          : parsedOrder,
    );
  }

  /// Toggles whether system default formatting should be copied.
  void toggleSystemFormat(bool value) {
    if (state.useSystemFormat == value) return;
    state = state.copyWith(useSystemFormat: value);
    _prefs.setTimeUseSystemFormat(value);
  }

  /// Updates 12-hour vs 24-hour clock preference.
  void set24Hour(bool value) {
    if (state.is24Hour == value) return;
    state = state.copyWith(is24Hour: value);
    _prefs.setTimeIs24Hour(value);
  }

  /// Updates day format (e.g. 'd' or 'dd').
  void setDayFormat(String value) {
    if (state.dayFormat == value) return;
    state = state.copyWith(dayFormat: value);
    _prefs.setTimeDayFormat(value);
  }

  /// Updates month format (e.g. 'M', 'MM', 'MMM', or 'MMMM').
  void setMonthFormat(String value) {
    if (state.monthFormat == value) return;
    state = state.copyWith(monthFormat: value);
    _prefs.setTimeMonthFormat(value);
  }

  /// Updates year format (e.g. 'yy' or 'yyyy').
  void setYearFormat(String value) {
    if (state.yearFormat == value) return;
    state = state.copyWith(yearFormat: value);
    _prefs.setTimeYearFormat(value);
  }

  /// Updates date separator symbol (e.g. '-', '/', '.', or ' ').
  void setSeparator(String value) {
    if (state.separator == value) return;
    state = state.copyWith(separator: value);
    _prefs.setTimeSeparator(value);
  }

  /// Reorders layout chips when dragged by user via [onReorderItem] and saves the new order.
  void reorderPartsDirect(int oldIndex, int newIndex) {
    final newOrder = List<FormatPart>.from(state.order);
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    state = state.copyWith(order: newOrder);

    final orderNames = newOrder.map((e) => e.name).toList();
    _prefs.setTimeOrder(orderNames);
  }

  /// Resets all time preferences to standard defaults.
  void resetToDefaults() {
    state = const TimePreferencesState();
    _prefs.setTimeUseSystemFormat(false);
    _prefs.setTimeIs24Hour(false);
    _prefs.setTimeDayFormat('dd');
    _prefs.setTimeMonthFormat('MMM');
    _prefs.setTimeYearFormat('yyyy');
    _prefs.setTimeSeparator('-');
    _prefs.setTimeOrder(['day', 'month', 'year', 'time']);
  }

  /// Formats a [DateTime] instance using [TimeHelper] according to current preferences.
  String formatDateTime(DateTime date) {
    return TimeHelper.formatCustomDateTime(
      date,
      useSystemFormat: state.useSystemFormat,
      is24Hour: state.is24Hour,
      dayFormat: state.dayFormat,
      monthFormat: state.monthFormat,
      yearFormat: state.yearFormat,
      separator: state.separator,
      order: state.order.map((e) => e.name).toList(),
    );
  }
}

/// Global provider for managing and observing date/time preferences.
final timePreferencesProvider = NotifierProvider<TimePreferencesNotifier, TimePreferencesState>(() {
  return TimePreferencesNotifier();
});

// ============================================================================
// 2. UI / PAGE
// ============================================================================

/// Main settings page allowing users to configure date and time display preferences.
///
/// Features a modern card-based Material 3 layout with a live preview, system format toggle,
/// component format dropdowns, interactive drag-to-reorder chips, and separator selection.
class DemoTimeSettingsPage extends ConsumerWidget {
  const DemoTimeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final prefs = ref.watch(timePreferencesProvider);
    final notifier = ref.read(timePreferencesProvider.notifier);

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.timeSettings,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- TOP NAVIGATION HEADER ---
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time & Date Format',
                              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Customize how dates and timestamps appear across NoteIt',
                              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.restart_alt_rounded),
                        tooltip: 'Reset to Defaults',
                        onPressed: () => notifier.resetToDefaults(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- 1. LIVE PREVIEW CARD ---
                  Card(
                    elevation: 0,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, size: 20, color: colorScheme.primary),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  ),

                  const SizedBox(height: 20),

                  // --- 2. GENERAL OPTIONS CARD ---
                  _buildSectionHeader('General Settings', textTheme, colorScheme),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          secondary: Icon(Icons.tune_rounded, color: colorScheme.onSurfaceVariant),
                          activeThumbColor: colorScheme.primary,
                          title: Text(
                            'Copy System Format',
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Follow system locale settings and disable custom layout overrides',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          value: prefs.useSystemFormat,
                          onChanged: (val) => notifier.toggleSystemFormat(val),
                        ),
                        Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        SwitchListTile(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                          ),
                          secondary: Icon(Icons.access_time_rounded, color: colorScheme.onSurfaceVariant),
                          activeThumbColor: colorScheme.primary,
                          title: Text(
                            '24-Hour Clock',
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Display time as 14:30 instead of 2:30 PM',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          value: prefs.is24Hour,
                          onChanged: prefs.useSystemFormat ? null : (val) => notifier.set24Hour(val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 3. CUSTOM FORMAT BUILDER (Fades when System Format is ON) ---
                  AnimatedOpacity(
                    opacity: prefs.useSystemFormat ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: prefs.useSystemFormat,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // A. FORMAT COMPONENTS
                          _buildSectionHeader('Individual Component Formats', textTheme, colorScheme),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final itemWidth = (constraints.maxWidth - 16) / 2;
                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: [
                                      SizedBox(
                                        width: itemWidth > 200 ? itemWidth : constraints.maxWidth,
                                        child: _buildDropdownTile(
                                          context: context,
                                          icon: Icons.calendar_today_rounded,
                                          label: 'Day Format',
                                          value: prefs.dayFormat,
                                          items: const {'d': 'Numeric (1)', 'dd': 'Two-digit (01)'},
                                          onChanged: (val) => notifier.setDayFormat(val!),
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth > 200 ? itemWidth : constraints.maxWidth,
                                        child: _buildDropdownTile(
                                          context: context,
                                          icon: Icons.calendar_month_rounded,
                                          label: 'Month Format',
                                          value: prefs.monthFormat,
                                          items: const {
                                            'M': 'Numeric (4)',
                                            'MM': 'Two-digit (04)',
                                            'MMM': 'Short Name (Apr)',
                                            'MMMM': 'Full Name (April)'
                                          },
                                          onChanged: (val) => notifier.setMonthFormat(val!),
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth > 200 ? itemWidth : constraints.maxWidth,
                                        child: _buildDropdownTile(
                                          context: context,
                                          icon: Icons.event_repeat_rounded,
                                          label: 'Year Format',
                                          value: prefs.yearFormat,
                                          items: const {'yy': 'Two-digit (26)', 'yyyy': 'Four-digit (2026)'},
                                          onChanged: (val) => notifier.setYearFormat(val!),
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth > 200 ? itemWidth : constraints.maxWidth,
                                        child: _buildDropdownTile(
                                          context: context,
                                          icon: Icons.schedule_rounded,
                                          label: 'Time Display',
                                          value: prefs.is24Hour ? '24' : '12',
                                          items: const {'12': '12-Hour (5:30 PM)', '24': '24-Hour (17:30)'},
                                          onChanged: (val) => notifier.set24Hour(val == '24'),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // B. REORDERABLE SEQUENCE
                          _buildSectionHeader('Layout Sequence', textTheme, colorScheme),
                          const SizedBox(height: 4),
                          Text(
                            'Drag chips horizontally to reorder how date and time parts appear',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                              child: SizedBox(
                                height: 48,
                                child: ReorderableListView(
                                  scrollDirection: Axis.horizontal,
                                  buildDefaultDragHandles: false,
                                  onReorderItem: (oldIndex, newIndex) => notifier.reorderPartsDirect(oldIndex, newIndex),
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
                          ),

                          const SizedBox(height: 24),

                          // C. DATE SEPARATOR
                          _buildSectionHeader('Date Separator', textTheme, colorScheme),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: '-', label: Text('Dash (-)')),
                                  ButtonSegment(value: '/', label: Text('Slash (/)')),
                                  ButtonSegment(value: '.', label: Text('Dot (.)')),
                                  ButtonSegment(value: ' ', label: Text('Space')),
                                ],
                                selected: {prefs.separator},
                                onSelectionChanged: (set) => notifier.setSeparator(set.first),
                                style: SegmentedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            ),
          ),
        ),
      ),
    );
  }

  /// Helper widget for section headers.
  Widget _buildSectionHeader(String title, TextTheme textTheme, ColorScheme colorScheme) {
    return Text(
      title,
      style: textTheme.titleSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
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
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: colorScheme.onSurfaceVariant),
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
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
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
            Icon(Icons.drag_indicator_rounded, size: 18, color: colorScheme.onSurfaceVariant),
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
