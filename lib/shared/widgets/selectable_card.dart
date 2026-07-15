import 'package:flutter/material.dart';

class SelectableCard extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final void Function() onTap;
  final void Function() onLongPress;

  const SelectableCard({super.key, required this.child, required this.isSelected, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedScale(
        scale: isSelected ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Stack(
          children: [
            child,
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}