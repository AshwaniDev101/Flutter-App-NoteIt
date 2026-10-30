import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/overlays/app_scaffold.dart';
import '../../home/view/desktop/content_panel/core/navigator.dart';

/// Reusable layout wrapper for all Settings pages in NoteIt.
///
/// Provides consistent page scaffolding, scrollability, centered max-width constraint,
/// and edge padding across desktop and mobile form factors.
class SettingsPageLayout extends ConsumerWidget {
  /// The [RightPanelPageOptions] panel identifier associated with this page.
  final RightPanelPageOptions option;

  /// The child content displayed inside the centered constrained scroll container.
  final Widget child;

  /// Maximum layout width constraint for settings content. Defaults to `650.0`.
  final double maxWidth;

  /// Horizontal padding applied around settings content. Defaults to `16.0`.
  final double horizontalPadding;

  /// Vertical padding applied around settings content. Defaults to `24.0`.
  final double verticalPadding;

  const SettingsPageLayout({
    super.key,
    required this.option,
    required this.child,
    this.maxWidth = 650.0,
    this.horizontalPadding = 16.0,
    this.verticalPadding = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold.rightPanel(
      option: option,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized header row for Settings sub-pages featuring back navigation,
/// a page title, optional subtitle, and custom right-aligned trailing actions.
class SettingsPageHeader extends ConsumerWidget {
  /// Main title text for the settings page.
  final String title;

  /// Optional subtitle description displayed below the title.
  final String? subtitle;

  /// Optional callback for the back navigation button. If null, navigates back
  /// to the root settings page (`RightPanelPageOptions.settings`).
  final VoidCallback? onBack;

  /// Optional trailing action widgets (e.g. search bars, reset buttons).
  final List<Widget>? actions;

  const SettingsPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to Settings',
              onPressed: onBack ??
                  () {
                    ref.read(drawerNavigationProvider).navigate(
                          context,
                          RightPanelPageOptions.settings,
                        );
                  },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ...?actions,
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Styled section header title text for grouping related settings options.
class SettingsSectionHeader extends StatelessWidget {
  /// Section category title string.
  final String title;

  /// Optional bottom padding after the title. Defaults to `8.0`.
  final double bottomPadding;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.bottomPadding = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: 8.0, bottom: bottomPadding),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Standardized card container used across all settings screens to group related options.
class SettingsCard extends StatelessWidget {
  /// The inner contents of the card.
  final Widget child;

  /// Optional inner padding around the card content.
  final EdgeInsetsGeometry? padding;

  /// Optional custom background color. Defaults to `null` (uses default card surface).
  final Color? color;

  /// Border radius applied to card corners. Defaults to `16.0`.
  final double borderRadius;

  const SettingsCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget cardChild = child;
    if (padding != null) {
      cardChild = Padding(padding: padding!, child: cardChild);
    }

    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: cardChild,
    );
  }
}

/// Standardized navigation or action list tile used in settings menus.
class SettingsTile extends StatelessWidget {
  /// Icon displayed on the left side of the tile.
  final IconData? icon;

  /// Widget displayed in place of the default icon.
  final Widget? leading;

  /// Primary label title.
  final String title;

  /// Optional description subtitle text.
  final String? subtitle;

  /// Widget displayed on the right side of the tile. Defaults to a chevron icon.
  final Widget? trailing;

  /// Callback executed when the tile is tapped.
  final VoidCallback? onTap;

  /// Content padding around the tile. Defaults to `(horizontal: 16, vertical: 4)`.
  final EdgeInsetsGeometry contentPadding;

  const SettingsTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final leadingWidget = leading ??
        (icon != null
            ? Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant)
            : null);

    return ListTile(
      contentPadding: contentPadding,
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: leadingWidget,
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            size: 18,
            color: theme.colorScheme.outline,
          ),
      onTap: onTap,
    );
  }
}

/// Standardized toggle switch list tile used for boolean settings.
class SettingsSwitchTile extends StatelessWidget {
  /// Icon displayed on the left side of the switch tile.
  final IconData? icon;

  /// Primary label title.
  final String title;

  /// Optional description subtitle text.
  final String? subtitle;

  /// Current boolean toggle state value.
  final bool value;

  /// Callback executed when the switch is toggled.
  final ValueChanged<bool>? onChanged;

  /// Content padding around the tile. Defaults to `(horizontal: 16, vertical: 4)`.
  final EdgeInsetsGeometry contentPadding;

  const SettingsSwitchTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      contentPadding: contentPadding,
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      secondary: icon != null
          ? Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant)
          : null,
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Standardized slider setting tile with a title, icon, formatted value label, and slider bar.
class SettingsSliderTile extends StatelessWidget {
  /// Section title for the slider option.
  final String title;

  /// Formatted string representing the current slider value (e.g. `'22 px'`).
  final String valueText;

  /// Current numerical slider value.
  final double value;

  /// Minimum slider value.
  final double min;

  /// Maximum slider value.
  final double max;

  /// Number of discrete slider divisions.
  final int divisions;

  /// Icon displayed next to the slider title.
  final IconData icon;

  /// Callback triggered continuously while dragging the slider.
  final ValueChanged<double> onChanged;

  /// Callback triggered when the user finishes dragging the slider.
  final ValueChanged<double> onChangeEnd;

  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.icon,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              valueText,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueText,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}
