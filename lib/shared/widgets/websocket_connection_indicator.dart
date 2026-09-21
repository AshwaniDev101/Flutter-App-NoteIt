import 'package:flutter/material.dart';

class WebSocketConnectionIndicator extends StatefulWidget {
  final bool isConnected;

  const WebSocketConnectionIndicator({super.key, required this.isConnected});

  @override
  State<WebSocketConnectionIndicator> createState() => _WebSocketConnectionIndicatorState();
}

class _WebSocketConnectionIndicatorState extends State<WebSocketConnectionIndicator> {
  // AnimatedScale shrinks the widget to 0 (invisible) when disconnected,
  // and grows it to normal size (1.0) when connected.
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.isConnected ? 1.0 : 00,
      duration: Duration(seconds: 1),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.greenAccent,
          boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)],
        ),
      ),
    );
  }
}
