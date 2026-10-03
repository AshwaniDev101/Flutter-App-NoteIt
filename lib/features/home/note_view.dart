import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enhanced Enum: Centralizes the icon and label data
enum NoteViewType {
  list('Compact List', Icons.view_list_rounded),
  detailedList('Detailed List', Icons.view_agenda_rounded),
  grid('Grid View', Icons.grid_view_rounded),
  largeGrid('Large Grid', Icons.calendar_view_month);

  final String label;
  final IconData icon;

  const NoteViewType(this.label, this.icon);
}

class NoteViewTypeNotifier extends Notifier<NoteViewType> {
  @override
  NoteViewType build() => NoteViewType.grid;

  void updateView(NoteViewType view) {
    state = view;
  }
}

final noteViewTypeProvider = NotifierProvider<NoteViewTypeNotifier, NoteViewType>(NoteViewTypeNotifier.new);

class ViewSwitcherButton extends ConsumerWidget {
  const ViewSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(noteViewTypeProvider);

    return PopupMenuButton<NoteViewType>(
      // The icon dynamically updates based on the current state via the enum
      icon: Icon(currentView.icon),
      tooltip: 'Change View',
      onSelected: (NoteViewType selectedView) {
        ref.read(noteViewTypeProvider.notifier).updateView(selectedView);
      },
      //  Dynamic Menu Generation using .map()
      itemBuilder: (BuildContext context) {
        return NoteViewType.values.map((view) {
          final isSelected = view == currentView;

          return PopupMenuItem<NoteViewType>(
            value: view,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(view.icon, color: isSelected ? Colors.blue : Colors.black54, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      view.label,
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                // Show a checkmark for the currently selected view
                if (isSelected) const Icon(Icons.check, color: Colors.blue, size: 20),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
