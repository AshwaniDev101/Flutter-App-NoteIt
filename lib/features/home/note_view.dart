import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

enum NoteViewType { list, detailedList, grid, largeGrid }

final noteViewTypeProvider = StateProvider<NoteViewType>((ref) => NoteViewType.grid);

class ViewSwitcherButton extends ConsumerWidget {
  const ViewSwitcherButton({super.key});

  IconData _getIconForView(NoteViewType view) {
    switch (view) {
      case NoteViewType.list: return Icons.view_list_rounded;
      case NoteViewType.detailedList: return Icons.view_agenda_rounded;
      case NoteViewType.grid: return Icons.grid_view_rounded;
      case NoteViewType.largeGrid: return Icons.calendar_view_month;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(noteViewTypeProvider);

    return PopupMenuButton<NoteViewType>(
      icon: Icon(_getIconForView(currentView)),
      tooltip: 'Change View',
      onSelected: (NoteViewType selectedView) {
        ref.read(noteViewTypeProvider.notifier).state = selectedView;
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<NoteViewType>>[
        const PopupMenuItem<NoteViewType>(
          value: NoteViewType.list,
          child: ListTile(leading: Icon(Icons.view_list_rounded), title: Text('Compact List'), contentPadding: EdgeInsets.zero),
        ),
        const PopupMenuItem<NoteViewType>(
          value: NoteViewType.detailedList,
          child: ListTile(leading: Icon(Icons.view_agenda_rounded), title: Text('Detailed List'), contentPadding: EdgeInsets.zero),
        ),
        const PopupMenuItem<NoteViewType>(
          value: NoteViewType.grid,
          child: ListTile(leading: Icon(Icons.grid_view_rounded), title: Text('Grid View'), contentPadding: EdgeInsets.zero),
        ),
        const PopupMenuItem<NoteViewType>(
          value: NoteViewType.largeGrid,
          child: ListTile(leading: Icon(Icons.calendar_view_month), title: Text('Large Grid'), contentPadding: EdgeInsets.zero),
        ),
      ],
    );
  }
}