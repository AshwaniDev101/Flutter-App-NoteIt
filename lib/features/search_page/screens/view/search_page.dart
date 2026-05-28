import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/database/firebase/firebase_database.dart';
import 'package:noteit/models/note_model.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  final List<String> _recentSearches = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _saveSearchToHistory(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _recentSearches.remove(trimmed);
      _recentSearches.insert(0, trimmed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreDatabase = ref.watch(noteFirebaseDatabaseProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search your notes...',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          style: textTheme.bodyLarge,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          onSubmitted: (value) => _saveSearchToHistory(value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _searchQuery.isEmpty
                    ? _buildRecentSearches(colorScheme, textTheme)
                    : _buildSearchResults(firestoreDatabase, colorScheme, textTheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches(ColorScheme colorScheme, TextTheme textTheme) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Text(
          'Type to start searching',
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            'Recent Searches',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final term = _recentSearches[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
                leading: Icon(Icons.history, color: colorScheme.onSurfaceVariant),
                title: Text(term, style: textTheme.bodyLarge),
                trailing: IconButton(
                  icon: Icon(Icons.close, size: 20, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    setState(() {
                      _recentSearches.removeAt(index);
                    });
                  },
                ),
                onTap: () {
                  _searchController.text = term;
                  setState(() {
                    _searchQuery = term;
                  });
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _searchController.text.length),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(dynamic firestoreDatabase, ColorScheme colorScheme, TextTheme textTheme) {
    return StreamBuilder<List<NoteModel>>(
      stream: firestoreDatabase.watchNotes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final query = _searchQuery.toLowerCase().trim();

        final filteredNotes = data.where((note) {
          return note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query);
        }).toList();

        if (filteredNotes.isEmpty) {
          return Center(
            child: Text(
              'No matching notes found.',
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredNotes.length,
          itemBuilder: (context, index) {
            final note = filteredNotes[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  note.isLocked ? "Locked Note" : (note.title.isEmpty ? "Untitled" : note.title),
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    note.isLocked ? "Unlock to view content" : note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                trailing: note.isLocked
                    ? Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant)
                    : null,
                onTap: () {
                  _saveSearchToHistory(_searchQuery);

                  if (note.isLocked) {
                    print("Prompt for password");
                  } else {
                    context.push(AppRoutes.edit, extra: note);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}