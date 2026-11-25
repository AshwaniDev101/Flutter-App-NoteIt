import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/theme/app_theme.dart';

import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import '../../../shared/overlays/app_scaffold.dart';

class ThemesPage extends ConsumerWidget {
  const ThemesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.themes,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: GridView(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 96,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            children: [
              for (final themeType in AppThemeType.values)
                _ThemeTile(
                  themeType: themeType,
                  currentTheme: currentTheme,
                  onTap: () => ref.read(themeProvider.notifier).setTheme(themeType),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final AppThemeType themeType;
  final AppThemeType currentTheme;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.themeType,
    required this.currentTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = themeType == currentTheme;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: themeType.iconColor.withValues(alpha: 0.2),
              child: Icon(Icons.palette, color: themeType.iconColor),
            ),
            title: Text(
              themeType.label,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(themeType.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
          ),
        ),
      ),
    );
  }
}
