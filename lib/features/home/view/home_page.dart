import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'desktop_home_page.dart';
import 'mobile_home_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // @override
  // Widget build(BuildContext context) {
  //   // If the screen is wider than 800 pixels, serve the Desktop Split-View.
  //   // Otherwise, serve the standard Mobile View.
  //
  //   return LayoutBuilder(
  //     builder: (context, constraints) {
  //       if (constraints.maxWidth > 800) {
  //         return const DesktopHomePage();
  //       } else {
  //         return const MobileHomePage();
  //       }
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktop) {
      return const DesktopHomePage();
    } else {
      return const MobileHomePage();
    }
  }
}
