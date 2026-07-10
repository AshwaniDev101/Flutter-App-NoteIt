// import 'package:flutter/material.dart';
//
// import '../../../../../core/theme/note_theme.dart';
// import '../../../../../database/drift/drift_database.dart';
//
// class HomepageCard extends StatefulWidget {
//   final Note note;
//   final bool isSelected;
//
//   final VoidCallback onSelect;
//   final VoidCallback onDelete;
//
//   const HomepageCard({super.key, required this.note, required this.isSelected, required this.onSelect, required this.onDelete});
//
//   @override
//   State<HomepageCard> createState() => _HomepageCardState();
// }
//
// class _HomepageCardState extends State<HomepageCard> {
//   bool _isHovering = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final noteTheme = Theme.of(context).extension<NoteTheme>()!;
//     final colorScheme = Theme.of(context).colorScheme;
//
//     return MouseRegion(
//       onEnter: (_) => setState(() => _isHovering = true),
//       onExit: (_) => setState(() => _isHovering = false),
//       cursor: SystemMouseCursors.click,
//       child: Card(
//         elevation: widget.isSelected ? 1 : 0,
//         color: noteTheme.cardContentBackground,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//           side: BorderSide(
//             color: widget.isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.3),
//             width: widget.isSelected ? 2 : 1,
//           ),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: Stack(
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         color: noteTheme.cardTitleBackground ?? colorScheme.surfaceContainerHigh,
//                         child: Text(
//                           widget.note.title.isEmpty ? "Untitled" : widget.note.title,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                             color: noteTheme.cardTitleForeground ?? colorScheme.onSurface,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   //Content
//                   Expanded(
//                     child: Stack(
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: widget.note.isLocked
//                               ? Center(
//                                   child: Icon(
//                                     Icons.lock_outlined,
//                                     size: 32,
//                                     color: (noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant).withValues(
//                                       alpha: 0.4,
//                                     ),
//                                   ),
//                                 )
//                               : Text(
//                                   widget.note.content,
//                                   maxLines: 5,
//                                   overflow: TextOverflow.ellipsis,
//                                   style: TextStyle(
//                                     fontSize: 13,
//                                     height: 1.4,
//                                     color: noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant,
//                                   ),
//                                 ),
//                         ),
//
//                         Positioned(bottom: 8, right: 8, child: getPlatformIcon(widget.note)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//
//               // if in focus, like mouse hovering over card
//               if (_isHovering &&  !widget.isSelected)
//                 Positioned(
//                   top: 0,
//                   right: 3,
//                   child: Column(
//                     children: [
//                         IconButton(
//                           icon: Icon(Icons.radio_button_unchecked_rounded, size: 18, color: colorScheme.primary),
//                           visualDensity: VisualDensity.compact,
//
//                           onPressed: widget.onSelect,
//                         ),
//                       IconButton(
//                         icon: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
//                         visualDensity: VisualDensity.compact,
//                         // padding: const EdgeInsets.symmetric(horizontal: 8),
//                         onPressed: widget.onDelete,
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget getPlatformIcon(Note note) {
//     final platform = note.creationPlatform?.toLowerCase();
//
//     switch (platform) {
//       case "android":
//         return const Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey);
//       case "windows":
//         return const Icon(Icons.desktop_windows_rounded, size: 14, color: Colors.grey);
//       default:
//         return const SizedBox.shrink();
//     }
//   }
// }
