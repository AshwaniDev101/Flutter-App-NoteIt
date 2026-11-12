import 'package:flutter/material.dart';

import '../../../../core/helpers/platform_helper.dart';
import '../../../../database/drift/local_database.dart';
import '../../../../database/drift/notes/notes_dao.dart';
import '../../../../shared/menus/view_menu_button.dart';
import '../../../../shared/note_card/core/note_action.dart';
import '../../../../shared/note_card/folder_trash_card.dart';
import '../../../../shared/note_card/note_card.dart';
import 'trash_empty_state.dart';

class TrashContentArea extends StatelessWidget {
  final List<NoteWithFolder> filteredNotes;
  final List<Folder> filteredFolders;
  final bool hasAnyTrashItems;
  final NoteViewType currentView;
  final String searchQuery;
  final bool isSelectMode;
  final Set<String> selectedNoteIds;
  final Set<String> selectedFolderIds;
  final ValueChanged<String> onToggleNoteSelection;
  final ValueChanged<String> onToggleFolderSelection;
  final VoidCallback onEnterSelectMode;
  final void Function({List<String>? noteUuids, List<String>? folderUuids}) onRestoreItems;
  final void Function({List<String>? noteUuids, List<String>? folderUuids}) onDeleteItems;

  const TrashContentArea({
    super.key,
    required this.filteredNotes,
    required this.filteredFolders,
    required this.hasAnyTrashItems,
    required this.currentView,
    required this.searchQuery,
    required this.isSelectMode,
    required this.selectedNoteIds,
    required this.selectedFolderIds,
    required this.onToggleNoteSelection,
    required this.onToggleFolderSelection,
    required this.onEnterSelectMode,
    required this.onRestoreItems,
    required this.onDeleteItems,
  });

  SliverGridDelegate _getGridDelegate(BuildContext context, NoteViewType viewType) {
    final isMobile = !PlatformHelper.isWideLayout(context);
    switch (viewType) {
      case NoteViewType.list:
        return const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisExtent: 44,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        );
      case NoteViewType.detailedList:
        return const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisExtent: 125,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        );
      case NoteViewType.largeGrid:
        return isMobile
            ? const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              )
            : const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                childAspectRatio: 1.0,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              );
      case NoteViewType.grid:
        return isMobile
            ? const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              )
            : const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = filteredNotes.isEmpty && filteredFolders.isEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: isEmpty
          ? KeyedSubtree(
              key: const ValueKey('empty_trash_view'),
              child: TrashEmptyState(hasAnyTrashItems: hasAnyTrashItems),
            )
          : KeyedSubtree(
              key: const ValueKey('trash_scroll_view'),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  ..._buildFoldersSlivers(context, filteredFolders),
                  ..._buildNotesSlivers(
                    context,
                    notes: filteredNotes,
                    currentView: currentView,
                    searchQuery: searchQuery,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildFoldersSlivers(BuildContext context, List<Folder> folders) {
    if (folders.isEmpty) return const [];

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text(
            'Folders (${folders.length})',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: folders.map((folder) => _buildFolderCard(context, folder)).toList(),
          ),
        ),
      ),
    ];
  }

  Widget _buildFolderCard(BuildContext context, Folder folder) {
    final isSelected = selectedFolderIds.contains(folder.uuid);

    return AnimatedScale(
      scale: isSelected ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: FolderTrashCard(
        folder: folder,
        isSelected: isSelected,
        onTap: () {
          if (isSelectMode) {
            onToggleFolderSelection(folder.uuid);
          }
        },
        onLongPress: () {
          if (!isSelectMode) {
            onEnterSelectMode();
          }
          onToggleFolderSelection(folder.uuid);
        },
        onContextMenuAction: (option) {
          switch (option) {
            case NoteAction.select:
              if (!isSelectMode) onEnterSelectMode();
              if (!isSelected) onToggleFolderSelection(folder.uuid);
              break;

            case NoteAction.restore:
              final targetUuids = isSelected ? selectedFolderIds.toList() : [folder.uuid];
              onRestoreItems(folderUuids: targetUuids);
              break;

            case NoteAction.deleteForever:
              final targetUuids = isSelected ? selectedFolderIds.toList() : [folder.uuid];
              onDeleteItems(folderUuids: targetUuids);
              break;

            default:
              break;
          }
        },
      ),
    );
  }

  List<Widget> _buildNotesSlivers(
    BuildContext context, {
    required List<NoteWithFolder> notes,
    required NoteViewType currentView,
    required String searchQuery,
  }) {
    if (notes.isEmpty) return const [];

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
          child: Text(
            'Notes (${notes.length})',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        sliver: SliverGrid(
          gridDelegate: _getGridDelegate(context, currentView),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final noteWithFolder = notes[index];
              return _buildNoteCard(
                context,
                noteWithFolder: noteWithFolder,
                currentView: currentView,
                searchQuery: searchQuery,
              );
            },
            childCount: notes.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildNoteCard(
    BuildContext context, {
    required NoteWithFolder noteWithFolder,
    required NoteViewType currentView,
    required String searchQuery,
  }) {
    final uuid = noteWithFolder.note.uuid;
    final isSelected = selectedNoteIds.contains(uuid);

    return AnimatedScale(
      scale: isSelected ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: NoteCard(
        key: ValueKey(uuid),
        noteWithFolder: noteWithFolder,
        viewType: currentView,
        searchQuery: searchQuery,
        isSelected: isSelected,
        contextMenuOptions: const [
          NoteAction.select,
          NoteAction.restore,
          NoteAction.deleteForever,
        ],
        onTap: () {
          if (isSelectMode) {
            onToggleNoteSelection(uuid);
          }
        },
        onLongPress: () {
          if (!isSelectMode) {
            onEnterSelectMode();
          }
          onToggleNoteSelection(uuid);
        },
        onContextMenuAction: (option) {
          switch (option) {
            case NoteAction.select:
              if (!isSelectMode) onEnterSelectMode();
              if (!isSelected) onToggleNoteSelection(uuid);
              break;

            case NoteAction.restore:
              final targetUuids = isSelected ? selectedNoteIds.toList() : [uuid];
              onRestoreItems(noteUuids: targetUuids);
              break;

            case NoteAction.deleteForever:
              final targetUuids = isSelected ? selectedNoteIds.toList() : [uuid];
              onDeleteItems(noteUuids: targetUuids);
              break;

            default:
              break;
          }
        },
      ),
    );
  }
}
