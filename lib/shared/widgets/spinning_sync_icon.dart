import 'package:flutter/material.dart';

class SpinningSyncIcon extends StatefulWidget {
  final bool isSyncing;
  final Color color;

  const SpinningSyncIcon({
    super.key,
    required this.isSyncing,
    required this.color,
  });

  @override
  State<SpinningSyncIcon> createState() => _SpinningSyncIconState();
}

class _SpinningSyncIconState extends State<SpinningSyncIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Start spinning immediately if created during an active sync
    if (widget.isSyncing) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // This function trigger when parent rebuild not when rebuild happen locally
  @override
  void didUpdateWidget(covariant SpinningSyncIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSyncing && !oldWidget.isSyncing) {
      _animationController.repeat(); // Start spinning
    } else if (!widget.isSyncing && oldWidget.isSyncing) {
      _animationController.stop(); // Stop spinning
    }
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animationController,
      child: Icon(Icons.sync, color: widget.color),
    );
  }
}
