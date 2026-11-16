import 'package:flutter/material.dart';

class SpinningIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const SpinningIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 18,
  });

  @override
  State<SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<SpinningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: -1.0,
    ).animate(_animationController);

    // Start spinning immediately if created during an active sync
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotationAnimation,
      child: Icon(
        widget.icon,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}

/// Backward compatibility alias for SpinningIcon.
typedef SpinningSyncIcon = SpinningIcon;
