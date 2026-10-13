import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/view/desktop/right_panel/core/navigator.dart';
import 'package:noteit/shared/widgets/app_scaffold.dart';

import '../../../../core/util/platform_helper.dart'; // Adjust imports to your path
import '../../../../database/drift/local_database.dart';
import '../../../../shared/widgets/note_card/note_card.dart';
import '../../database/drift/notes/notes_dao.dart';


final archivedNotesStreamProvider = StreamProvider.autoDispose<List<Note>>((ref) {
  return ref.watch(notesDaoProvider).watchArchivedNotes();
});

class ArchivePage extends ConsumerWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedNotesState = ref.watch(archivedNotesStreamProvider);

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.archivePage,

      // appBar: AppBar(
      //   title: const Text('Archive'),
      //   elevation: 0,
      //   scrolledUnderElevation: PlatformHelper.isDesktopScreen ? 0.0 : null,
      // ),
      body: archivedNotesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive_outlined, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Your archive is empty.',
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
            // Reusing your adaptive grid logic!
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
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCard(
                note: note,
                key: ValueKey(note.uuid),
                // Only show these two options!
                contextMenuOptions: const [
                  NoteContextMenuOption.unarchive,
                  NoteContextMenuOption.delete,
                ],
                onTap: () {
                  // TODO: Open note in editor
                  // E.g. ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.editNote, note);
                },
                onContextMenuAction: (option) {
                  // You can handle right-clicking archived notes here later!
                  // For example, calling your NoteActionsController to unarchive or delete it.
                },

              );
            },
          );
        },
      ),
    );
  }
}