import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:noteit/features/home_page/screens/core/sort.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/features/home_page/screens/view/widgets/homepage_card.dart';
import 'package:noteit/core/theme/note_theme.dart';
import 'package:noteit/database/drift/drift_database.dart';
import 'package:noteit/features/password_page/screens/view/password_page.dart';
import 'widgets/homepage_drawer.dart';
import '../../../../database/sync_manager.dart';
import '../../../../shared/selectable_card.dart';

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

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final sortedNotesAsync = ref.watch(sortedNotesProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();

  return sortedNotesAsync.whenData((notes) {
    if (searchQuery.isEmpty) return notes;

    return notes.where((note) {
      final matchesTitle = note.title.toLowerCase().contains(searchQuery);
      final matchesContent = !note.isLocked && note.content.toLowerCase().contains(searchQuery);
      return matchesTitle || matchesContent;
    }).toList();
  });
});

class SortOptionsBar extends ConsumerWidget {
  const SortOptionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSortOption = ref.watch(noteSortOptionProvider);

    return Padding(
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
    );
  }
}

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(filteredNotesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: notesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes found.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            gridDelegate: defaultTargetPlatform == TargetPlatform.android && !kIsWeb
                ? const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 0.85)
                : const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220, childAspectRatio: 0.85),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final currentNote = notes[index];
              final isSelected = noteIds.contains(currentNote.id);

              return SelectableCard(
                isSelected: isSelected,
                onTap: () {
                  if (isSelectMode) {
                    onToggleSelection(currentNote.id);
                  } else if (currentNote.isLocked) {
                    onPromptPassword(context, currentNote);
                  } else {
                    context.push(AppRoutes.edit, extra: currentNote);
                  }
                },
                onLongPress: () {
                  if (!isSelectMode) {
                    onEnableSelectMode();
                    onToggleSelection(currentNote.id);
                  }
                },
                child: HomepageCard(note: currentNote, isSelected: isSelected),
              );
            },
          );
        },
      ),
    );
  }
}

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
    return Scaffold(
      drawer: const HomepageDrawer(),
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.edit),
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSearchMode) const SortOptionsBar(),
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
    );
  }

  // --- APPBAR LOGIC  ---

  PreferredSizeWidget _buildAppBar() {
    if (isSelectMode) return _buildSelectAppBar();
    if (isSearchMode) return _buildSearchAppBar();
    return _buildDefaultAppBar();
  }

  PreferredSizeWidget _buildSelectAppBar() {
    final noteTheme = Theme.of(context).extension<NoteTheme>()!;
    final driftDatabase = ref.watch(noteDriftDatabaseProvider);

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
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await driftDatabase.softDeleteNotes(noteIds);
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

  PreferredSizeWidget _buildDefaultAppBar() {
    // Determine if we are on Android
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return AppBar(
      title: const Text('Note-it', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [

        // WINDOWS / DESKTOP MODE: Show the inline TextField
        if (!isAndroid)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 250,
              child: TextField(
                controller: _searchController, // Wired to your controller
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  //  Add a small clear button inside the text field
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
                // Wired to your Riverpod search state
                onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
              ),
            ),
          ),

        // ANDROID MODE: Show the Search Icon to trigger the Search AppBar
        if (isAndroid)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => isSearchMode = true),
          ),

        // BOTH PLATFORMS: Show the Sync Button
        Consumer(
          builder: (context, ref, child) {
            final isSyncing = ref.watch(syncNotifierProvider);
            if (isSyncing) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => ref.read(syncNotifierProvider.notifier).executeFullSync(),
            );
          },
        ),
      ],
    );
  }

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

    if (enteredPassword != null && enteredPassword == "1234" && context.mounted) {
      context.push(AppRoutes.edit, extra: note);
    }
  }
}