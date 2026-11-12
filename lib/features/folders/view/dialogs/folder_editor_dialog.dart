import 'dart:math';
import 'package:flutter/material.dart';
import 'package:noteit/core/theme/folder_theme_colors.dart';

class FolderEditorDialog extends StatefulWidget {
  final String? initialName;
  final int? initialColorIndex;

  const FolderEditorDialog({
    super.key,
    this.initialName,
    this.initialColorIndex,
  });

  @override
  State<FolderEditorDialog> createState() => _FolderEditorDialogState();
}

class _FolderEditorDialogState extends State<FolderEditorDialog> {
  late final TextEditingController _nameController;
  late int _selectedColorIndex;
  late final bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialName != null;
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedColorIndex = widget.initialColorIndex ?? Random().nextInt(12);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      Navigator.pop(context, {
        'name': name,
        'colorIndex': _selectedColorIndex,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      title: Text(
        _isEditing ? 'Edit Folder' : 'New Folder',
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              style: textTheme.bodyMedium,
              onChanged: (value) => setState(() {}),
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                hintText: 'Folder name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "COLOR",
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (index) {
                final color = FolderThemeColors.of(context, index);
                final isSelected = _selectedColorIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ] : null,
                      border: isSelected
                          ? Border.all(color: colorScheme.onSurface, width: 2.0)
                          : Border.all(color: Colors.transparent, width: 2.0),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant,
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isNotEmpty ? _submit : null,
          child: Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
