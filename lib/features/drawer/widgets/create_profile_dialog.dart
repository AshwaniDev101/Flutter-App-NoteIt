import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_providers.dart';

/// Modal dialog for creating a new user profile workspace.
class CreateProfileDialog extends ConsumerStatefulWidget {
  const CreateProfileDialog({super.key});

  @override
  ConsumerState<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends ConsumerState<CreateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aliasController = TextEditingController();

  int _selectedColorValue = 0xFF2196F3; // Default Blue

  static const List<int> _presetColors = [
    0xFF2196F3, // Ocean Blue
    0xFF4CAF50, // Emerald Green
    0xFFFF9800, // Amber / Orange
    0xFF9C27B0, // Royal Purple
    0xFFE91E63, // Crimson Rose
    0xFF009688, // Teal
    0xFF3F51B5, // Indigo
    0xFF00BCD4, // Cyan
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  void _onCreateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final alias = _aliasController.text.trim();

    final newProfile = await ref.read(profilesListProvider.notifier).createProfile(
          name: name,
          customAlias: alias.isNotEmpty ? alias : null,
          colorValue: _selectedColorValue,
          iconName: 'person',
        );

    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      await ref.read(activeProfileProvider.notifier).switchProfile(newProfile);
      SnackBarManager.show(
        msg: 'Created and switched to "$name" profile.',
        type: SnackBarMessageType.acknowledgment,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.add_to_photos_rounded, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Create New Profile',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Profile Name *',
                    hintText: 'e.g. Work, Personal, Side Projects',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.workspace_premium_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a profile name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _aliasController,
                  decoration: InputDecoration(
                    labelText: 'Subtitle / Custom Alias (Optional)',
                    hintText: 'e.g. Company X, Daily Journal',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.subtitles_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ACCENT COLOR',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _presetColors.map((colorHex) {
                    final isSelected = _selectedColorValue == colorHex;
                    final color = Color(colorHex);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorValue = colorHex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colorScheme.onSurface : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onCreateProfile,
          child: const Text('Create Profile'),
        ),
      ],
    );
  }
}
