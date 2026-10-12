import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/drift/synced_devices/synced_devices_dao.dart';
import '../../home/view/shared/desktop_close_button.dart';

class SyncedDevicesListView extends ConsumerWidget {
  const SyncedDevicesListView({super.key});

  // Helper method to format dates cleanly
  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // --- Helper to pick the correct icon based on the platform string ---
  IconData _getPlatformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'android': return Icons.android;
      case 'ios': return Icons.apple; // Note: Ensure you have cupertino_icons or use Icons.phone_iphone
      case 'windows': return Icons.desktop_windows;
      case 'macos': return Icons.laptop_mac;
      case 'linux': return Icons.computer;
      case 'web': return Icons.language;
      default: return Icons.devices_other;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsyncValue = ref.watch(syncedDevicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synced Devices'),
        centerTitle: true,
        actions: [
          DesktopCloseButton(),
        ],
      ),
      body: devicesAsyncValue.when(
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(child: Text('No devices found.'));
          }

          // Use Center and ConstrainedBox to limit width on desktop
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600, // Maximum width the list will take on large screens
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Device Name and Delete Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // --- Show the platform icon next to the name ---
                              Icon(_getPlatformIcon(device.deviceType), color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  device.deviceName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final dao = ref.read(syncedDevicesDaoProvider);
                                  await dao.deleteDevice(device.deviceUuid);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${device.deviceName} deleted')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const Divider(),

                          // Device Details
                          _DetailRow(
                            icon: Icons.fingerprint,
                            label: 'UUID',
                            value: device.deviceUuid,
                          ),

                          // --- Display the Protocol Version and Platform ---
                          _DetailRow(
                            icon: Icons.developer_board,
                            label: 'Platform',
                            value: device.deviceType ?? 'Unknown',
                          ),
                          _DetailRow(
                            icon: Icons.verified,
                            label: 'Protocol Version',
                            value: 'v${device.protocolVersion ?? 0}',
                          ),
                          // ----------------------------------------------------

                          _DetailRow(
                            icon: Icons.network_check,
                            label: 'IP Address',
                            value: device.lastKnownIp ?? 'Unknown',
                          ),
                          _DetailRow(
                            icon: Icons.settings_ethernet,
                            label: 'Port',
                            value: device.lastKnownPort?.toString() ?? 'Unknown',
                          ),
                          const SizedBox(height: 8),

                          // Timestamps
                          _DetailRow(
                            icon: Icons.login,
                            label: 'Last Seen (Host)',
                            value: _formatDate(device.lastSeenAsHostAt),
                          ),
                          _DetailRow(
                            icon: Icons.logout,
                            label: 'Last Seen (Client)',
                            value: _formatDate(device.lastSeenAsClientAt),
                          ),
                          _DetailRow(
                            icon: Icons.calendar_today,
                            label: 'First Paired',
                            value: _formatDate(device.firstPairedAt),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading devices: $error'),
        ),
      ),
    );
  }
}

// A reusable widget for displaying icon + label + value neatly
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}