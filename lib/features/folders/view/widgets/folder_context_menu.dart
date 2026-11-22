import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/menus/context_menu_helper.dart';
import '../../../../database/drift/folders/folders_dao.dart';
import '../../../../database/drift/local_database.dart';
import '../../viewmodel/folder_view_model.dart';
import '../dialogs/folder_editor_dialog.dart';

class FolderContextMenu {
  static Widget _buildMenuItem(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required Folder folder,
    Offset? position,
    Folder? selectedFolder,
    ValueChanged<Folder?>? onFolderSelected,
  }) async {
    Offset tapPosition = position ?? Offset.zero;

    if (tapPosition == Offset.zero) {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null && box.attached) {
        final topLeft = box.localToGlobal(Offset.zero);
        final size = box.size;
        tapPosition = Offset(topLeft.dx + 16, topLeft.dy + size.height / 2);
      } else {
        tapPosition = const Offset(100, 100);
      }
    }

    final isPinned = folder.pinnedAt != null;
    final errorColor = Theme.of(context).colorScheme.error;

    final selectedAction = await ContextMenuHelper.show<String>(
      context: context,
      globalTapPosition: tapPosition,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      constraints: const BoxConstraints(minWidth: 160),
      items: [
        PopupMenuItem(
          value: 'pin',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(
            isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            isPinned ? 'Unpin' : 'Pin',
          ),
        ),
        PopupMenuItem(
          value: 'update',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(Icons.edit_outlined, 'Edit'),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: 'delete',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(Icons.delete_outline_rounded, 'Delete', color: errorColor),
        ),
      ],
    );

    if (selectedAction != null && context.mounted) {
      await _handleContextMenuAction(
        context: context,
        ref: ref,
        action: selectedAction,
        folder: folder,
        selectedFolder: selectedFolder,
        onFolderSelected: onFolderSelected,
      );
    }
  }

  static Future<void> _handleContextMenuAction({
    required BuildContext context,
    required WidgetRef ref,
    required String action,
    required Folder folder,
    Folder? selectedFolder,
    ValueChanged<Folder?>? onFolderSelected,
  }) async {
    final viewModel = ref.read(folderViewModelProvider.notifier);

    switch (action) {
      case 'pin':
        await viewModel.togglePinStatus(folder.uuid);
        break;

      case 'update':
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => FolderEditorDialog(
            initialName: folder.name,
            initialColorIndex: folder.colorIndex,
          ),
        );

        if (result != null && context.mounted) {
          await viewModel.updateFolder(
            uuid: folder.uuid,
            name: result['name'],
            colorIndex: result['colorIndex'],
          );

          if (selectedFolder?.uuid == folder.uuid && onFolderSelected != null) {
            final dao = ref.read(foldersDaoProvider);
            final updatedFolder = (await dao.select(dao.folders).get()).firstWhere((f) => f.uuid == folder.uuid);
            onFolderSelected(updatedFolder);
          }
        }
        break;

      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Folder?'),
            content: Text('Are you sure you want to delete "${folder.name}"?\nNotes inside will be kept safely.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          await viewModel.softDeleteFolder(folder.uuid, platform: 'desktop');
          if (selectedFolder?.uuid == folder.uuid && onFolderSelected != null) {
            onFolderSelected(null);
          }
        }
        break;
    }
  }
}
