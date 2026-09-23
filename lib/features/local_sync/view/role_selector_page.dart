import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routing.dart';

class RoleSelectorPage extends StatelessWidget {
  const RoleSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            shrinkWrap: true, // Centers the content vertically
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

              RoleTile(
                title: "Connect to a Host",
                roleBadge: "Client Mode",
                description:
                "Find and join a sync session on your local network. Best for mobile phones and tablets.",
                icons: const [Icons.phone_android, Icons.tablet_mac],
                color: Colors.blue,
                onTap: () {
                  context.push(AppRoutes.searchNearBy);
                },
              ),

              const SizedBox(height: 16),

              RoleTile(
                title: "Host a Sync Session",
                roleBadge: "Host Mode",
                description:
                "Create a local server that other devices can discover and join. Best for desktops and laptops.",
                icons: const [Icons.desktop_windows_outlined, Icons.laptop],
                color: Colors.green,
                onTap: () {
                  context.push(AppRoutes.broadcastNearBy); // Assuming you added this route!
                },
              ),
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

  const RoleTile({
    super.key,
    required this.title,
    required this.roleBadge,
    required this.description,
    required this.icons,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias, // Ensures the InkWell splash stays inside the rounded corners
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular colored icon background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icons.first, color: color, size: 32),
              ),
              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        // Display the row of small device icons
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