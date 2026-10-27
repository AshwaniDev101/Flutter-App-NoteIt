import 'dart:math';
import 'package:flutter/material.dart';

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
    _selectedColorIndex = widget.initialColorIndex ?? Random().nextInt(Colors.primaries.length);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      title: Text(
        _isEditing ? 'Update Folder' : 'New Folder',
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              style: textTheme.bodyMedium,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                hintText: 'Folder name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "COLOR",
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(Colors.primaries.length, (index) {
                final color = Colors.primaries[index];
                final isSelected = _selectedColorIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ] : null,
                      border: isSelected
                          ? Border.all(color: colorScheme.onSurface, width: 2.5)
                          : Border.all(color: Colors.transparent, width: 2.5),
                    ),
                    child: isSelected
                        ? Icon(
                      Icons.check_rounded,
                      color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                      size: 18,
                    )
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () {
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'colorIndex': _selectedColorIndex,
            });
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
          ),
          child: Text(_isEditing ? 'Save' : 'Create', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
