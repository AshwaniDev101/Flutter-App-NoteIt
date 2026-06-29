import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/core/theme/note_theme.dart';

import 'package:noteit/database/drift/drift_database.dart';
import 'package:noteit/features/home_page/screens/view/widgets/homepage_card.dart';
import 'package:noteit/features/home_page/screens/view/widgets/homepage_drawer.dart';
import 'package:noteit/features/password_page/screens/view/password_page.dart';
import 'package:noteit/features/home_page/screens/core/sort.dart';

import '../../../../database/sync_manager.dart';
import '../../../../shared/selectable_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool isSelectMode = false;
  final Set<int> noteIds = {};

  // Search State Variables
  bool isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger the new Delta Sync engine on startup
      ref.read(syncNotifierProvider.notifier).executeFullSync();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driftDatabase = ref.watch(noteDriftDatabaseProvider);
    final noteTheme = Theme.of(context).extension<NoteTheme>()!;
    final currentSortOption = ref.watch(noteSortOptionProvider);

    return Scaffold(
      // Dynamic AppBar Logic
      drawer: const HomepageDrawer(),
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
              title: Text('${noteIds.length} Selected', style: const TextStyle(color: Colors.white)),
              actions: [
                IconButton(
                  onPressed: () async {
                    // Soft delete locally
                    await driftDatabase.softDeleteNotes(noteIds);

                    // Trigger background sync to push deletes to the cloud
                    ref.read(syncNotifierProvider.notifier).executeFullSync();

                    // Update UI state
                    setState(() {
                      isSelectMode = false;
                      noteIds.clear();
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            )
          : isSearchMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    isSearchMode = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              ),
              title: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(hintText: 'Search notes...', border: InputBorder.none),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              actions: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
              ],
            )
          : AppBar(
              title: const Text('Note-it', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      isSearchMode = true;
                    });
                  },
                  icon: const Icon(Icons.search),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.grid_view_rounded)),

                // Manual Sync Button
                // IconButton(
                //   onPressed: () {
                //     // Show a quick snack bar so the user knows it's syncing
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(content: Text('Syncing notes...'), duration: Duration(seconds: 1)),
                //     );
                //     ref.read(syncNotifierProvider.notifier).executeFullSync(ref);
                //   },
                //   icon: const Icon(Icons.sync),
                // ),
                // Inside your AppBar actions:

                // Manual Sync button with animating
                Consumer(
                  builder: (context, ref, child) {
                    // Watch the boolean state directly!
                    final isSyncing = ref.watch(syncNotifierProvider);

                    if (isSyncing) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }

                    return IconButton(
                      onPressed: () {
                        ref.read(syncNotifierProvider.notifier).executeFullSync();
                      },
                      icon: const Icon(Icons.sync),
                    );
                  },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only show Sort Chips if we are not searching (optional, keeps UI clean)
            if (!isSearchMode)
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
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: ref
                    .watch(sortedNotesProvider)
                    .when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(child: Text('Error: $error')),
                      data: (data) {
                        if (data.isEmpty) {
                          return const Center(child: Text('No notes yet. Tap + to add one!'));
                        }

                        // Dynamic Search Filtering
                        List<Note> displayedNotes = data;
                        if (_searchQuery.isNotEmpty) {
                          final query = _searchQuery.toLowerCase().trim();
                          displayedNotes = data.where((note) {
                            final matchesTitle = note.title.toLowerCase().contains(query);
                            // Prevent exposing content of locked notes in search
                            final matchesContent = !note.isLocked && note.content.toLowerCase().contains(query);
                            return matchesTitle || matchesContent;
                          }).toList();
                        }

                        // Handle empty search results
                        if (displayedNotes.isEmpty) {
                          return const Center(child: Text('No matching notes found.'));
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          gridDelegate: defaultTargetPlatform == TargetPlatform.android && !kIsWeb
                              ? const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 0.0,
                                  mainAxisSpacing: 0.0,
                                  childAspectRatio: 0.85,
                                )
                              : const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 220,
                                  crossAxisSpacing: 0.0,
                                  mainAxisSpacing: 0.0,
                                  childAspectRatio: 0.85,
                                ),
                          itemCount: displayedNotes.length, // Updated to use filtered list
                          itemBuilder: (context, index) {
                            final currentNote = displayedNotes[index]; // Updated to use filtered list
                            final isSelected = noteIds.contains(currentNote.id);

                            return SelectableCard(
                              onTap: () {
                                if (isSelectMode) {
                                  setState(() {
                                    if (isSelected) {
                                      noteIds.remove(currentNote.id);
                                      if (noteIds.isEmpty) {
                                        isSelectMode = false;
                                      }
                                    } else {
                                      noteIds.add(currentNote.id);
                                    }
                                  });
                                } else {
                                  if (currentNote.isLocked) {
                                    _promptForPassword(context, currentNote);
                                  } else {
                                    context.push(AppRoutes.edit, extra: currentNote);
                                  }
                                }
                              },
                              onLongPress: () {
                                if (!isSelectMode) {
                                  setState(() {
                                    isSelectMode = true;
                                    noteIds.add(currentNote.id);
                                  });
                                }
                              },
                              isSelected: isSelected,
                              child: HomepageCard(note: currentNote, isSelected: isSelected),
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

  Future<void> _promptForPassword(BuildContext context, Note note) async {
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

