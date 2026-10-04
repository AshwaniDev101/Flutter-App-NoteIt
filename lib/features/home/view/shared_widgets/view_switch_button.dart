import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/core/providers.dart';


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
