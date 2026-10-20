import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../shared/app_scaffold.dart';

/// Glassmorphism shell wrapper for lock dialog views.
class LockDialogShell extends StatelessWidget {
  final Widget child;
  final double width;
  final EdgeInsetsGeometry padding;

  const LockDialogShell({
    super.key,
    required this.child,
    this.width = 340,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.25),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent inner tap from closing dialog
              child: Container(
                width: width,
                padding: padding,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
