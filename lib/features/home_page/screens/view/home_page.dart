import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/core/theme/note_theme.dart';
import 'package:noteit/database/firebase/firebase_database.dart';
import 'package:noteit/models/note_model.dart';

import '../../../password_page/screens/view/password_page.dart';
import '../core/sort.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool isSelectMode = false;
  final Set<String> noteIds = {};

  @override
  Widget build(BuildContext context) {
    final firestoreDatabase = ref.watch(noteFirebaseDatabaseProvider);
    final noteTheme = Theme.of(context).extension<NoteTheme>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final currentSortOption = ref.watch(noteSortOptionProvider);

    return Scaffold(
      appBar: isSelectMode
          ? AppBar(
        backgroundColor: noteTheme.selectedAppBar,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            setState(() {
              isSelectMode = false;
              noteIds.clear();
            });
          },
          icon: const Icon(Icons.close),
        ),
        title: Text(
          '${noteIds.length} Selected',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await firestoreDatabase.deleteNotes(noteIds);
              setState(() {
                isSelectMode = false;
                noteIds.clear();
              });
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      )
          : AppBar(
        title: const Text(
          'Note-it',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.push(AppRoutes.search);
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.grid_view_rounded),
          ),
          IconButton(
            onPressed: () {
              context.push(AppRoutes.settings);
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          context.push(AppRoutes.edit);
        },
        child: const Icon(Icons.add),
      ),

      body: Center(

        // ConstrainedBox(
        //   constraints: const BoxConstraints(maxWidth: 1000),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Created'),
                    selected: currentSortOption == NoteSortOption.createdAt,
                    onSelected: (_) => ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.createdAt),
                    avatar: const Icon(Icons.access_time, size: 16),
                    showCheckmark: false,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Name'),
                    selected: currentSortOption == NoteSortOption.name,
                    onSelected: (_) => ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.name),
                    avatar: const Icon(Icons.sort_by_alpha, size: 16),
                    showCheckmark: false,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Last Updated'),
                    selected: currentSortOption == NoteSortOption.updatedAt,
                    onSelected: (_) => ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.updatedAt),
                    avatar: const Icon(Icons.update, size: 16),
                    showCheckmark: false,
                  ),
                ],
              )
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                // Watch the sorted provider instead of the raw database stream
                child: ref.watch(sortedNotesProvider).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (data) {
                    if (data.isEmpty) {
                      return const Center(
                        child: Text('No notes yet. Tap + to add one!'),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      gridDelegate: defaultTargetPlatform == TargetPlatform.android && !kIsWeb
                      // Android, Strict 3 columns
                          ? const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 0.0,
                        mainAxisSpacing: 0.0,
                        childAspectRatio: 0.85,
                      )
                      // Dynamic width for everything else
                          : const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        crossAxisSpacing: 0.0,
                        mainAxisSpacing: 0.0,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final isSelected = noteIds.contains(data[index].id);
                        return _SelectableCard(
                          onTap: () {
                            if (isSelectMode) {
                              setState(() {
                                if (isSelected) {
                                  noteIds.remove(data[index].id);
                                  if (noteIds.isEmpty) {
                                    isSelectMode = false;
                                  }
                                } else {
                                  noteIds.add(data[index].id);
                                }
                              });
                            } else {
                              if (data[index].isLocked) {
                                _promptForPassword(context, data[index]);
                              } else {
                                context.push(
                                  AppRoutes.edit,
                                  extra: data[index],
                                );
                              }
                            }
                          },
                          onLongPress: () {
                            if (!isSelectMode) {
                              setState(() {
                                isSelectMode = true;
                                noteIds.add(data[index].id);
                              });
                            }
                          },
                          isSelected: isSelected,
                          child: _Card(note: data[index], isSelected: isSelected),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptForPassword(BuildContext context, NoteModel note) async {
    final String? enteredPassword = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Password Dialog',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const PasswordPage();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    if (enteredPassword != null && enteredPassword == "1234") {
      if (context.mounted) {
        context.push(AppRoutes.edit, extra: note);
      }
    }
  }
}

class _SelectableCard extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final void Function() onTap;
  final void Function() onLongPress;

  const _SelectableCard({
    required this.child,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedScale(
        scale: isSelected ? 0.95 : 1.0, // Slight bounce down effect when selected
        duration: const Duration(milliseconds: 150),
        child: Stack(
          children: [
            child,
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final NoteModel note;
  final bool isSelected;

  const _Card({
    required this.note,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final noteTheme = Theme.of(context).extension<NoteTheme>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 1 : 0,
      color: noteTheme.cardContentBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: noteTheme.cardTitleBackground ?? colorScheme.surfaceContainerHigh,
              child: Text(
                note.title.isEmpty ? "Untitled" : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: noteTheme.cardTitleForeground ?? colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: note.isLocked
                    ? Center(
                  child: Icon(
                    Icons.lock_outlined,
                    size: 32,
                    color: (noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant)
                        .withValues(alpha: 0.4),
                  ),
                )
                    : Text(
                  note.content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}