import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:noteit/features/home_page/screens/core/sort.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/core/theme/note_theme.dart';
import 'package:noteit/database/drift/drift_database.dart';
import 'package:noteit/features/password_page/screens/view/password_page.dart';
import '../../../../shared/managers/lock_manger/lock_manager.dart';
import '../../../../shared/widgets/note_card.dart';
import 'widgets/homepage_drawer.dart';
import '../../../../database/sync_manager.dart';

// STATE MANAGEMENT & PROVIDERS  --------------------------

enum PlatformFilter { all, android, windows }

enum MenuOption { sortCreated, sortName, sortUpdated, filterPhone, filterWindows }

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class PlatformFilterNotifier extends Notifier<PlatformFilter> {
  @override
  PlatformFilter build() => PlatformFilter.all;

  void toggleFilter(PlatformFilter filter) {
    if (state == filter) {
      state = PlatformFilter.all;
    } else {
      state = filter;
    }
  }
}

final platformFilterProvider = NotifierProvider<PlatformFilterNotifier, PlatformFilter>(PlatformFilterNotifier.new);

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final sortedNotesAsync = ref.watch(sortedNotesProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
  final platformFilter = ref.watch(platformFilterProvider);

  final lockState = ref.watch(lockManagerProvider);

  return sortedNotesAsync.whenData((notes) {
    List<Note> result = notes;

    if (platformFilter != PlatformFilter.all) {
      final targetPlatform = platformFilter == PlatformFilter.android ? 'android' : 'windows';
      result = result.where((note) {
        return note.creationPlatform?.toLowerCase() == targetPlatform;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      result = result.where((note) {
        final matchesTitle = note.title.toLowerCase().contains(searchQuery);

        final canReadContent = !note.isLocked || lockState.sessionUnlockedNoteIds.contains(note.id);
        final matchesContent = canReadContent && note.content.toLowerCase().contains(searchQuery);
        // final matchesContent = !note.isLocked && note.content.toLowerCase().contains(searchQuery);
        return matchesTitle || matchesContent;
      }).toList();
    }

    return result;
  });
});

// DESKTOP/WINDOWS UI COMPONENTS  -----------------------------

class SortOptionsBar extends ConsumerWidget {
  const SortOptionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSortOption = ref.watch(noteSortOptionProvider);
    final currentPlatformFilter = ref.watch(platformFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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

            Container(
              width: 1,
              height: 24,
              color: Colors.grey.withValues(alpha: 0.3),
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            Container(
              width: 1,
              height: 24,
              color: Colors.grey.withValues(alpha: 0.3),
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),

            ChoiceChip(
              label: const Text('Phone'),
              selected: currentPlatformFilter == PlatformFilter.android,
              onSelected: (_) => ref.read(platformFilterProvider.notifier).toggleFilter(PlatformFilter.android),
              avatar: const Icon(Icons.phone_android_outlined, size: 16, color: Colors.grey),
              showCheckmark: false,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Windows'),
              selected: currentPlatformFilter == PlatformFilter.windows,
              onSelected: (_) => ref.read(platformFilterProvider.notifier).toggleFilter(PlatformFilter.windows),
              avatar: const Icon(Icons.desktop_windows_outlined, size: 16, color: Colors.grey),
              showCheckmark: false,
            ),
            const SizedBox(width: 8),

            // TODO: remove it on release only for testing
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.redAccent),
              onPressed: () {
                context.push(AppRoutes.dev);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// SHARED UI COMPONENTS -----------------------
class NotesGridView extends ConsumerWidget {
  final bool isSelectMode;
  final Set<int> noteIds;
  final Function(int) onToggleSelection;
  final Function() onEnableSelectMode;
  final Future<void> Function(BuildContext, Note) onPromptPassword;

  const NotesGridView({
    super.key,
    required this.isSelectMode,
    required this.noteIds,
    required this.onToggleSelection,
    required this.onEnableSelectMode,
    required this.onPromptPassword,
  });

  Future<void> _deleteNote(WidgetRef ref, int id) async {
    final driftDatabase = ref.read(noteDriftDatabaseProvider);
    await driftDatabase.softDeleteNotes({id}, platform: defaultTargetPlatform.name);
    ref.read(syncNotifierProvider.notifier).executeFullSync();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(filteredNotesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: notesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes found.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(syncNotifierProvider.notifier).executeFullSync();
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              gridDelegate: defaultTargetPlatform == TargetPlatform.android && !kIsWeb
                  ? const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.85)
                  : const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, childAspectRatio: 0.85),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final currentNote = notes[index];
                final isSelected = noteIds.contains(currentNote.id);

                final isSessionUnlocked = ref
                    .watch(lockManagerProvider)
                    .sessionUnlockedNoteIds
                    .contains(currentNote.id);
                final displayAsLocked = currentNote.isLocked && !isSessionUnlocked;

                return NoteCard(
                  note: currentNote,
                  isSelected: isSelected,
                  searchQuery: ref.read(searchQueryProvider),
                  onTap: () async {
                    if (isSelectMode) {
                      onToggleSelection(currentNote.id);
                    } else if (displayAsLocked) {
                      // Note is locked and not in session -> Ask for password
                      await onPromptPassword(context, currentNote);
                    } else {
                      // Note is unlocked -> Open editor
                      await context.push(AppRoutes.edit, extra: currentNote);

                      // ENFORCE PREFERENCE: We are back on the homepage now.
                      // If they don't want to keep it unlocked, lock it instantly.
                      final lockState = ref.read(lockManagerProvider);
                      if (currentNote.isLocked && !lockState.keepUnlockedDuringSession) {
                        ref.read(lockManagerProvider.notifier).lockSessionNote(currentNote.id);
                      }
                    }
                  },
                  onLongPress: () {
                    if (!isSelectMode) {
                      onEnableSelectMode();
                      onToggleSelection(currentNote.id);
                    }
                  },
                  hoverActions: [
                    IconButton(
                      icon: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (!isSelectMode) onEnableSelectMode();
                        onToggleSelection(currentNote.id);
                      },
                    ),

                    if (!isSelectMode) ...[
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _deleteNote(ref, currentNote.id),
                      ),

                      // 1. Note is completely UNLOCKED -> Option to permanently lock it
                      if (!currentNote.isLocked)
                        IconButton(
                          icon: const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Lock Note',
                          onPressed: () async {
                            final lockManager = ref.read(lockManagerProvider.notifier);
                            if (!lockManager.hasMasterPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tap the note to set a Master Password first!'))
                              );
                              return;
                            }
                            final driftDatabase = ref.read(noteDriftDatabaseProvider);
                            await driftDatabase.lockNote(currentNote.id, isLocked: true);
                            ref.read(syncNotifierProvider.notifier).executeFullSync();
                          },
                        ),

                      // 2. Note is LOCKED, but UNLOCKED FOR SESSION -> Option to lock it immediately
                      if (currentNote.isLocked && isSessionUnlocked)
                        IconButton(
                          icon: const Icon(Icons.lock_open_rounded, size: 18, color: Colors.green),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Lock instantly',
                          onPressed: () {
                            // Assuming your lock manager has a method to remove from the session list
                            ref.read(lockManagerProvider.notifier).lockSessionNote(currentNote.id);
                          },
                        ),

                      // 3. Note is LOCKED and LOCKED FOR SESSION -> Option to unlock directly from hover
                      if (currentNote.isLocked && !isSessionUnlocked)
                        IconButton(
                          icon: const Icon(Icons.lock_rounded, size: 18, color: Colors.grey),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Unlock',
                          onPressed: () => onPromptPassword(context, currentNote),
                        ),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// MAIN SCREEN ------------------------

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool isSelectMode = false;
  final Set<int> noteIds = {};

  bool isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncNotifierProvider.notifier).executeFullSync();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (noteIds.contains(id)) {
        noteIds.remove(id);
        if (noteIds.isEmpty) isSelectMode = false;
      } else {
        noteIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    // This forces Riverpod to keep the SyncManager and its Auth listeners fully awake
    // the entire time the user is on the Home Screen.
    ref.watch(syncNotifierProvider);

    return PopScope(
      canPop: !isSelectMode && !isSearchMode,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return; // If it already popped, do nothing

        // If in selection mode, exit selection mode
        if (isSelectMode) {
          setState(() {
            isSelectMode = false;
            noteIds.clear();
          });
        }
        // Also intercept back button to exit search mode
        else if (isSearchMode) {
          _searchController.clear();
          ref.read(searchQueryProvider.notifier).clear();
          setState(() => isSearchMode = false);
        }
      },

      child: Scaffold(
        drawer: const HomepageDrawer(),
        appBar: _buildAppBar(isAndroid),

        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.edit),
          child: const Icon(Icons.add),
        ),

        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Render ChoiceChips only in non-search mode and on desktop/web environments
              if (!isSearchMode && !isAndroid) const SortOptionsBar(),
              Expanded(
                child: NotesGridView(
                  isSelectMode: isSelectMode,
                  noteIds: noteIds,
                  onToggleSelection: _toggleSelection,
                  onEnableSelectMode: () => setState(() => isSelectMode = true),
                  onPromptPassword: _promptForPassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // APPBAR CONFIGURATION ------------------
  PreferredSizeWidget _buildAppBar(bool isAndroid) {
    if (isSelectMode) return _buildSelectAppBar();
    if (isSearchMode) return _buildSearchAppBar();
    return _buildDefaultAppBar(isAndroid);
  }

  PreferredSizeWidget _buildSelectAppBar() {
    final noteTheme = Theme.of(context).extension<NoteTheme>()!;
    final driftDatabase = ref.watch(noteDriftDatabaseProvider);

    // Get the current list of filtered notes to know what "All" means
    final currentNotesState = ref.watch(filteredNotesProvider);
    final currentNotes = currentNotesState.value ?? [];

    // Determine if everything is currently selected
    final isAllSelected = currentNotes.isNotEmpty && noteIds.length == currentNotes.length;

    return AppBar(
      backgroundColor: noteTheme.selectedAppBar,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() {
          isSelectMode = false;
          noteIds.clear();
        }),
      ),
      title: Text('${noteIds.length} Selected', style: const TextStyle(color: Colors.white)),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white, // Text and ripple color
              side: const BorderSide(color: Colors.white, width: 1.5), // Border color and thickness
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0), // Rounded corners
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () {
              setState(() {
                if (isAllSelected) {
                  // Deselect all
                  noteIds.clear();
                  isSelectMode = false;
                } else {
                  // Select all visible notes
                  noteIds.addAll(currentNotes.map((note) => note.id));
                }
              });
            },
            child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
          ),
        ),

        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await driftDatabase.softDeleteNotes(noteIds, platform: defaultTargetPlatform.name);
            ref.read(syncNotifierProvider.notifier).executeFullSync();
            setState(() {
              isSelectMode = false;
              noteIds.clear();
            });
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _searchController.clear();
          ref.read(searchQueryProvider.notifier).clear();
          setState(() => isSearchMode = false);
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(hintText: 'Search notes...', border: InputBorder.none),
        onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
      ),
      actions: [
        if (ref.watch(searchQueryProvider).isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).clear();
            },
          ),
      ],
    );
  }

  PreferredSizeWidget _buildDefaultAppBar(bool isAndroid) {
    final currentSortOption = ref.watch(noteSortOptionProvider);
    final currentPlatformFilter = ref.watch(platformFilterProvider);

    // Capture the state here instead of just calling the watch blindly
    final isSyncing = ref.watch(syncNotifierProvider);

    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: const Text('Note-it', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        // Desktop Search TextField
        if (!isAndroid)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 250,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).clear();
                          },
                        )
                      : null,
                ),
                onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
              ),
            ),
          ),

        // Mobile Search Toggle
        if (isAndroid) IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => isSearchMode = true)),

        // Manual Sync (Desktop Only)
        if (!isAndroid)
          isSyncing
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  child: Row(
                    children: [
                      Icon(Icons.sync),
                      SizedBox(width: 8),
                      if (!isAndroid) ...[Text("Sync")],
                    ],
                  ),

                  onPressed: () => ref.read(syncNotifierProvider.notifier).executeFullSync(),
                ),
        SizedBox(width: 8),

        // Mobile Sort & Filter Options Menu
        if (isAndroid)
          PopupMenuButton<MenuOption>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Sort & Filter',
            onSelected: (MenuOption value) {
              switch (value) {
                case MenuOption.sortCreated:
                  ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.createdAt);
                  break;
                case MenuOption.sortName:
                  ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.name);
                  break;
                case MenuOption.sortUpdated:
                  ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.updatedAt);
                  break;
                case MenuOption.filterPhone:
                  ref.read(platformFilterProvider.notifier).toggleFilter(PlatformFilter.android);
                  break;
                case MenuOption.filterWindows:
                  ref.read(platformFilterProvider.notifier).toggleFilter(PlatformFilter.windows);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOption>>[
              // --- SORTING SECTION (Radios) ---
              const PopupMenuItem<MenuOption>(
                enabled: false,
                child: Text('SORT BY', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              const PopupMenuItem<MenuOption>(
                enabled: false,
                child: Text('SORT BY', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              PopupMenuItem<MenuOption>(
                value: MenuOption.sortCreated,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Created'),
                    // Visual indicator instead of the deprecated Radio widget
                    Icon(
                      currentSortOption == NoteSortOption.createdAt
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: currentSortOption == NoteSortOption.createdAt ? colorScheme.primary : Colors.grey,
                    ),
                  ],
                ),
              ),
              PopupMenuItem<MenuOption>(
                value: MenuOption.sortName,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Name'),
                    Icon(
                      currentSortOption == NoteSortOption.name
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: currentSortOption == NoteSortOption.name ? colorScheme.primary : Colors.grey,
                    ),
                  ],
                ),
              ),
              PopupMenuItem<MenuOption>(
                value: MenuOption.sortUpdated,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Last Updated'),
                    Icon(
                      currentSortOption == NoteSortOption.updatedAt
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: currentSortOption == NoteSortOption.updatedAt ? colorScheme.primary : Colors.grey,
                    ),
                  ],
                ),
              ),

              const PopupMenuDivider(),

              // --- FILTERING SECTION (Checkboxes) ---
              const PopupMenuItem<MenuOption>(
                enabled: false,
                child: Text('FILTER PLATFORM', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              PopupMenuItem<MenuOption>(
                value: MenuOption.filterPhone,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.phone_android_outlined, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Phone'),
                      ],
                    ),
                    IgnorePointer(
                      child: Checkbox(value: currentPlatformFilter == PlatformFilter.android, onChanged: (_) {}),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<MenuOption>(
                value: MenuOption.filterWindows,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.desktop_windows_outlined, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Windows'),
                      ],
                    ),
                    IgnorePointer(
                      child: Checkbox(value: currentPlatformFilter == PlatformFilter.windows, onChanged: (_) {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  // DIALOG CONTROLLERS --------------------------
  Future<void> _promptForPassword(BuildContext context, Note note) async {
    final String? enteredPassword = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Password Dialog',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => const PasswordPage(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    if (enteredPassword != null && enteredPassword.isNotEmpty && context.mounted) {
      final lockManager = ref.read(lockManagerProvider.notifier);

      // NEW: If no password exists, treat this input as creating the new password!
      if (!lockManager.hasMasterPassword) {
        await lockManager.setupMasterPassword(enteredPassword);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New Master Password Set!')));
      }

      final success = lockManager.verifyAndSessionUnlock(note.id, enteredPassword);

      if (success) {
        context.push(AppRoutes.edit, extra: note);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Password')));
      }
    }
  }
}
