import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/core/note_tap_handler.dart';
import 'package:noteit/features/home/view/desktop/right_panel/core/navigator.dart';
import 'package:noteit/shared/widgets/app_scaffold.dart';

import '../../core/util/platform_helper.dart';
import '../../database/drift/local_database.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../shared/widgets/note_card/note_card.dart';

final archivedNotesStreamProvider = StreamProvider.autoDispose<List<Note>>((ref) {
  return ref.watch(notesDaoProvider).watchArchivedNotes();
});

class ArchivePage extends ConsumerStatefulWidget {
  const ArchivePage({super.key});

  @override
  ConsumerState<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends ConsumerState<ArchivePage> {
  bool _isSearching = false;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archivedNotesState = ref.watch(archivedNotesStreamProvider);
    final searchQuery = _searchController.text.trim();

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.archivePage,
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Archive',
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
              // Small delay to ensure the TextField is built before focusing
              Future.delayed(const Duration(milliseconds: 50), () {
                _searchFocusNode.requestFocus();
              });
            },
          ),
      ],
      body: Column(
        children: [
          if (_isSearching)
            Align(
              alignment: Alignment.topRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search archived notes...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                
                
                      const SizedBox(width: 8),
                
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close Search',
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _searchController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Expanded(
            child: archivedNotesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (notes) {
                final filteredNotes = searchQuery.isEmpty
                    ? notes
                    : notes.where((note) {
                        final queryLower = searchQuery.toLowerCase();
                        return note.title.toLowerCase().contains(queryLower) ||
                            note.content.toLowerCase().contains(queryLower);
                      }).toList();

                if (filteredNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          notes.isEmpty
                              ? 'Your archive is empty.'
                              : 'No matching archived notes found.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: PlatformHelper.isMobileScreen
                      ? const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        )
                      : const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return NoteCard(
                      note: note,
                      searchQuery: searchQuery,
                      key: ValueKey(note.uuid),
                      contextMenuOptions: const [
                        NoteContextMenuOption.unarchive,
                        NoteContextMenuOption.delete,
                      ],
                      onTap: () {
                        NoteTapHandler.openNote(context, ref, note);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
