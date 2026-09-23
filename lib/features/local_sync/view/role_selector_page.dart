import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routing.dart';

class RoleSelectorPage extends StatelessWidget {
  const RoleSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Detect if the app is running on a desktop platform
    final platform = Theme.of(context).platform;
    final isDesktop = platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;

    final clientTile = RoleTile(
      title: "Connect to a Host",
      roleBadge: "Client Mode",
      description:
      "Find and join a sync session on your local network. Best for mobile phones and tablets.",
      icons: const [Icons.phone_android, Icons.tablet_mac],
      color: Colors.blue,
      isRecommended: !isDesktop, // Recommended if on Mobile
      onTap: () {
        context.push(AppRoutes.searchNearBy);
      },
    );

    final hostTile = RoleTile(
      title: "Host a Sync Session",
      roleBadge: "Host Mode",
      description:
      "Create a local server that other devices can discover and join. Best for desktops and laptops.",
      icons: const [Icons.desktop_windows_outlined, Icons.laptop],
      color: Colors.green,
      isRecommended: isDesktop, // Recommended if on Desktop
      onTap: () {
        context.push(AppRoutes.broadcastNearBy);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Sync'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            shrinkWrap: true,
            children: [
              const Text(
                'Choose Device Role',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'How do you want to connect this device?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Dynamically reorder based on the device type
              if (isDesktop) ...[
                hostTile,
                const SizedBox(height: 16),
                clientTile,
              ] else ...[
                clientTile,
                const SizedBox(height: 16),
                hostTile,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RoleTile extends StatelessWidget {
  final String title;
  final String roleBadge;
  final String description;
  final List<IconData> icons;
  final Color color;
  final VoidCallback onTap;
  final bool isRecommended;

  const RoleTile({
    super.key,
    required this.title,
    required this.roleBadge,
    required this.description,
    required this.icons,
    required this.color,
    required this.onTap,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero, // Keep spacing controlled by ListView
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Make the border slightly thicker and darker if it's the recommended option
        side: BorderSide(
          color: isRecommended ? color.withOpacity(0.8) : color.withOpacity(0.3),
          width: isRecommended ? 2.0 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Padding(
          // Reduced outer padding from 20 to 16 for better mobile fit
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                // Shrunk icon slightly from 32 to 28 to give text more horizontal space
                child: Icon(icons.first, color: color, size: 28),
              ),
              const SizedBox(width: 16), // Reduced gap from 20 to 16
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isRecommended)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'RECOMMENDED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          roleBadge,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const Spacer(),
                        ...icons.map((iconData) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(iconData, size: 18, color: Colors.grey.shade400),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}