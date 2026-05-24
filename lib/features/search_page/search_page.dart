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
  // This keeps track of searches for this session only
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
      // Remove it if it exists so we can bump it to the top
      _recentSearches.remove(trimmed);
      _recentSearches.insert(0, trimmed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreDatabase = ref.watch(noteFirebaseDatabaseProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // --- TOP SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24), // Rounded corners
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search your notes...',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
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

            // --- BODY (History OR Results) ---
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildRecentSearches()
                  : _buildSearchResults(firestoreDatabase),
            ),
          ],
        ),
      ),
    );
  }

  // UI: Recent Searches
  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Text('Type to start searching'),
      );
    }

    return ListView.builder(
      itemCount: _recentSearches.length,
      itemBuilder: (context, index) {
        final term = _recentSearches[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(term),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _recentSearches.removeAt(index);
              });
            },
          ),
          onTap: () {
            // Apply history term to search bar
            _searchController.text = term;
            setState(() {
              _searchQuery = term;
            });
            // Move cursor to the end
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
          },
        );
      },
    );
  }

  // UI: Search Results from Firebase Stream
  Widget _buildSearchResults(dynamic firestoreDatabase) {
    return StreamBuilder<List<NoteModel>>(
      stream: firestoreDatabase.watchNotes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final query = _searchQuery.toLowerCase().trim();

        // 1. Filter the notes locally
        final filteredNotes = data.where((note) {
          return note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query);
        }).toList();

        // 2. Handle empty state
        if (filteredNotes.isEmpty) {
          return const Center(child: Text('No matching notes found.'));
        }

        // 3. Display results (using a simple ListView here, but you can swap
        //    this with your GridView.builder from HomePage if you prefer!)
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredNotes.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final note = filteredNotes[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              title: Text(
                note.isLocked ? "Locked Note" : note.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                note.isLocked ? "Unlock to view content" : note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: note.isLocked ? const Icon(Icons.lock) : null,
              onTap: () {
                // Save to history when a result is actually tapped
                _saveSearchToHistory(_searchQuery);

                if (note.isLocked) {
                  // TODO: trigger your password dialog here like you do on HomePage
                  print("Prompt for password");
                } else {
                  context.push(AppRoutes.edit, extra: note);
                }
              },
            );
          },
        );
      },
    );
  }
}