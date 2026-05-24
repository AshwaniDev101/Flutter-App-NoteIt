import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/core/theme/note_theme.dart';
import 'package:noteit/database/firebase/firebase_database.dart';
import 'package:noteit/models/note_model.dart';

import '../../../password_page/screens/view/password_page.dart';

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
    // final localDb = ref.watch(noteDriftDatabaseProvider);
    final firestoreDatabase = ref.watch(noteFirebaseDatabaseProvider);
    final noteTheme = Theme.of(context).extension<NoteTheme>()!;

    return Scaffold(

      appBar: isSelectMode
          ? AppBar(
        backgroundColor: noteTheme.selectedAppBar,
        leading: IconButton(
          onPressed: () {
            setState(() {
              isSelectMode = false;
              noteIds.clear();
            });
          },
          icon: Icon(Icons.arrow_back,),
        ),
        title: Text(
          '${noteIds.length} Selected',

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
            icon: Icon(Icons.delete,),
          ),
        ],
      )
          : AppBar(
        title: Text(
          'Note-it',
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.grid_view_rounded,),
          ),
          IconButton(
            onPressed: () async{

              final password = await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const PasswordPage(),
              );

              print(password);

            },
            icon: Icon(Icons.lock, ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          context.push(AppRoutes.edit);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sort by: Name',

              )
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: StreamBuilder<List<NoteModel>>(
                stream: firestoreDatabase.watchNotes(),
                builder: (BuildContext context, AsyncSnapshot<List<NoteModel>> snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!;

                  if (data.isEmpty) {
                    return Center(
                      child: Text(
                        'No notes yet. Tap + to add one!',
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return _SelectableCard(
                        onTap: () {
                          if (isSelectMode) {
                            setState(() {
                              if (noteIds.contains(data[index].id)) {
                                noteIds.remove(data[index].id);
                                if (noteIds.isEmpty) {
                                  isSelectMode = false;
                                }
                              } else {
                                noteIds.add(data[index].id);
                              }
                            });
                          } else {

                            if(data[index].isLocked)
                              {
                                _promptForPassword(context, data[index]);
                              }else
                                {
                                  context.push(
                                    AppRoutes.edit,
                                    extra: data[index],
                                  );
                                }

                          }
                        },
                        onLongPress: () {
                          setState(() {
                            isSelectMode = true;
                            noteIds.add(data[index].id);
                          });
                        },
                        isSelected: noteIds.contains(data[index].id),
                        child: _Card(note: data[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _promptForPassword(BuildContext context, NoteModel note) async {
    // We specify <String> because your Navigator.pop(context, password) returns a String.
    final String? enteredPassword = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true, // Lets the user tap outside to dismiss
      barrierLabel: 'Dismiss Password Dialog',
      barrierColor: Colors.transparent, // Set to transparent because widget handles the background color and blur!
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const PasswordPage(); // Custom widget
      },
      // Optional: Add a nice fade transition
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );

    // Handle the result after the dialog closes
    if (enteredPassword != null) {
      print("User entered: $enteredPassword");
      // Password verification logic here

      if(enteredPassword=="1234")
        {
          context.push(
            AppRoutes.edit,
            extra: note,
          );
        }
    } else {
      print("User canceled or tapped outside.");
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          child,
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final NoteModel note;

  const _Card({required this.note, super.key});

  @override
  Widget build(BuildContext context) {
    final noteTheme = Theme.of(context).extension<NoteTheme>()!;


    if(note.isLocked)
      {
        return Card(

          color: noteTheme.cardContentBackground,
          child: Container(
            constraints: const BoxConstraints.expand(),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: noteTheme.cardTitleBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: noteTheme.cardTitleForeground,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Icon(Icons.lock, size: 40, color: noteTheme.cardContentForeground.withValues(alpha: 0.5)),
                  )
                )
              ],
            ),
          ),
        );
      }

    return Card(

      color: noteTheme.cardContentBackground,
      child: Container(
        constraints: const BoxConstraints.expand(),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: noteTheme.cardTitleBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  note.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: noteTheme.cardTitleForeground,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  note.content,
                  style: TextStyle(color: noteTheme.cardContentForeground),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}