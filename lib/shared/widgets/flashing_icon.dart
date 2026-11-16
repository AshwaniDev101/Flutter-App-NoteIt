import 'package:flutter/material.dart';

class FlashingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const FlashingIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 18,
  });

  @override
  State<FlashingIcon> createState() => _FlashingIconState();
}

class _FlashingIconState extends State<FlashingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.2,
    ).animate(_animationController);

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Icon(
        widget.icon,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}
