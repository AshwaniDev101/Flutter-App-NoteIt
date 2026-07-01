import 'package:flutter/material.dart';

import '../../../../../core/theme/note_theme.dart';
import '../../../../../database/drift/drift_database.dart';



class HomepageCard extends StatelessWidget {
  final Note note;
  final bool isSelected;

  const HomepageCard({super.key, required this.note, required this.isSelected});

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
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.3),
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

            //Content
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: note.isLocked
                        ? Center(
                            child: Icon(
                              Icons.lock_outlined,
                              size: 32,
                              color: (noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant).withValues(
                                alpha: 0.4,
                              ),
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

                  Positioned(bottom: 8, right: 8, child: getPlatformIcon(note)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getPlatformIcon(Note note) {
    final platform = note.creationPlatform?.toLowerCase();

    switch (platform) {
      case "android":
        return const Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey);
      case "windows":
        return const Icon(Icons.desktop_windows_rounded, size: 14, color: Colors.grey);
      default:
        return const SizedBox.shrink();
    }
  }
}
