import 'package:flutter/material.dart';

class ShadedOverlay extends StatelessWidget {
  final BoxConstraints boxConstraints;
  final VoidCallback onClickFlash;
  final VoidCallback onClickGallery;

  const ShadedOverlay({required this.boxConstraints, super.key, required this.onClickFlash, required this.onClickGallery});

  @override
  Widget build(BuildContext context) {
    final size = boxConstraints.biggest;
    final width = boxConstraints.maxWidth;

    final scanSize = width * 0.7;

    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanSize,
      height: scanSize,
    );


    return Stack(
      children: [


        // Clipped Scan Area
        IgnorePointer(
          child: ClipPath(
            clipper: _CutoutClipper(scanSize),
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
        ),

        // White border
        Center(
          child: Container(
            width: scanSize,
            height: scanSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Label 'Scan a LanternChat QR Code'
        Positioned(
          top: scanRect.bottom + 24,
          left: 0,
          right: 0,
          // right: 0,
          child: Center(
            child: Text(
              'Scan a LanternChat QR Code',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),
        ),

        // Flash & Gallery Button
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IconButton(
                  // TODO Implement Image Picker
                  onPressed: onClickGallery,
                  icon: Icon(Icons.photo_library_outlined, color: Colors.white, size: 32),
                ),
                IconButton(
                  onPressed: () {
                    onClickFlash();
                  },
                  icon: Icon(Icons.flash_off, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
        ),


      ],
    );
  }
}


class _CutoutClipper extends CustomClipper<Path> {
  final double scanSize;

  _CutoutClipper(this.scanSize);

  @override
  Path getClip(Size size) {
    // Full size rectangle
    final Rect fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    // From Center we offset the rect shape
    final Rect scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanSize,
      height: scanSize,
    );

    // Outer path: Full screen
    final outerPath = Path()
      ..addRect(fullRect);

    // Inner path: the area we want to KEEP visible (cut-out)
    // adding Rounded corner to inner rect path
    final innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));

    return Path.combine(PathOperation.difference, outerPath, innerPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
