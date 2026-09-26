import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'desktop_home_page.dart';
import 'mobile_home_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
