import 'package:flutter/material.dart';

class TrashEmptyState extends StatelessWidget {
  final bool hasAnyTrashItems;

  const TrashEmptyState({
    super.key,
    required this.hasAnyTrashItems,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delete_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            !hasAnyTrashItems ? 'Trash is empty' : 'No matching trashed items found',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
