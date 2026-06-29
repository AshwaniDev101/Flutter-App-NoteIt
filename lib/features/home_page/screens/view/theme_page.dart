import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/theme/app_theme.dart'; // Adjust path to your unified theme file

class ThemesPage extends ConsumerWidget {
  const ThemesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current theme so we can show a checkmark next to the active one
    final currentTheme = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _ThemeTile(
            title: 'Light Mode',
            subtitle: 'Standard bright and clean look',
            themeType: AppThemeType.light,
            currentTheme: currentTheme,
            iconColor: Colors.orange,
            onTap: () => ref.read(themeProvider.notifier).setTheme(AppThemeType.light),
          ),
          _ThemeTile(
            title: 'Dark Mode',
            subtitle: 'Easy on the eyes, deep blue tint',
            themeType: AppThemeType.dark,
            currentTheme: currentTheme,
            iconColor: Colors.indigo,
            onTap: () => ref.read(themeProvider.notifier).setTheme(AppThemeType.dark),
          ),
          _ThemeTile(
            title: 'AMOLED Black',
            subtitle: 'True pitch black, saves battery',
            themeType: AppThemeType.amoled,
            currentTheme: currentTheme,
            iconColor: Colors.black87,
            onTap: () => ref.read(themeProvider.notifier).setTheme(AppThemeType.amoled),
          ),
          _ThemeTile(
            title: 'Sepia',
            subtitle: 'Warm e-reader paper style',
            themeType: AppThemeType.sepia,
            currentTheme: currentTheme,
            iconColor: Colors.brown,
            onTap: () => ref.read(themeProvider.notifier).setTheme(AppThemeType.sepia),
          ),
        ],
      ),
    );
  }
}

// A reusable widget to make the list look polished
class _ThemeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final AppThemeType themeType;
  final AppThemeType currentTheme;
  final Color iconColor;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.title,
    required this.subtitle,
    required this.themeType,
    required this.currentTheme,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = themeType == currentTheme;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.2),
          child: Icon(Icons.palette, color: iconColor),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}