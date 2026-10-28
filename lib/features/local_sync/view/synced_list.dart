import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helpers/time_helper.dart';
import '../../../database/drift/synced_devices/synced_devices_dao.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import '../../../shared/overlays/app_scaffold.dart';

class SyncedDevicesListView extends ConsumerWidget {
  const SyncedDevicesListView({super.key});



  IconData _getPlatformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'android': return Icons.android;
      case 'ios': return Icons.apple;
      case 'windows': return Icons.desktop_windows;
      case 'macos': return Icons.laptop_mac;
      case 'linux': return Icons.computer;
      case 'web': return Icons.language;
      default: return Icons.devices_other;
    }
  }

  String _getLastRole(DateTime? hostDate, DateTime? clientDate) {
    if (hostDate == null && clientDate == null) return 'Unknown';
    if (hostDate == null) return 'Client';
    if (clientDate == null) return 'Host';
    return hostDate.isAfter(clientDate) ? 'Host' : 'Client';
  }

  DateTime? _getLastSeenDate(DateTime? hostDate, DateTime? clientDate) {
    if (hostDate == null) return clientDate;
    if (clientDate == null) return hostDate;
    return hostDate.isAfter(clientDate) ? hostDate : clientDate;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsyncValue = ref.watch(syncedDevicesStreamProvider);
    final formatDateTime = ref.watch(timeFormatterProvider);

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.syncedList,
      body: devicesAsyncValue.when(
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(child: Text('No devices found.'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final lastRole = _getLastRole(device.lastSeenAsHostAt, device.lastSeenAsClientAt);
                  final lastSeenDate = _getLastSeenDate(device.lastSeenAsHostAt, device.lastSeenAsClientAt);

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha:0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            children: [
                              Icon(
                                _getPlatformIcon(device.deviceType),
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  device.deviceName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (device.blockedAt != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                                  ),
                                  child: const Text(
                                    'Blocked',
                                    style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                              _RoleBadge(role: lastRole),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  device.blockedAt != null ? Icons.block : Icons.shield_outlined,
                                  size: 20,
                                  color: device.blockedAt != null ? Colors.red : null,
                                ),
                                tooltip: device.blockedAt != null ? 'Unblock device' : 'Block device',
                                splashRadius: 20,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  final dao = ref.read(syncedDevicesDaoProvider);
                                  final willBlock = device.blockedAt == null;
                                  await dao.setDeviceBlocked(device.deviceUuid, isBlocked: willBlock);

                                  if (context.mounted) {
                                    SnackBarManager.show(
                                      msg: willBlock
                                          ? '${device.deviceName} blocked'
                                          : '${device.deviceName} unblocked',
                                      type: SnackBarMessageType.acknowledgment,
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                splashRadius: 20,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  final dao = ref.read(syncedDevicesDaoProvider);
                                  await dao.deleteDevice(device.deviceUuid);

                                  if (context.mounted) {
                                    SnackBarManager.show(
                                      msg: '${device.deviceName} deleted',
                                      type: SnackBarMessageType.acknowledgment,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Wrap layout with clear labels
                          Wrap(
                            spacing: 24, // Horizontal space between items
                            runSpacing: 10, // Vertical space when wrapping to a new line
                            children: [
                              _CompactDetail(
                                icon: Icons.fingerprint,
                                label: 'UUID',
                                value: device.deviceUuid,
                              ),
                              // Conditional rendering for IP/Port
                              if (device.lastKnownIp != null || device.lastKnownPort != null)
                                _CompactDetail(
                                  icon: Icons.network_check,
                                  label: 'IP/Port',
                                  value: '${device.lastKnownIp ?? 'Unknown'}:${device.lastKnownPort ?? 'Unknown'}',
                                ),
                              _CompactDetail(
                                icon: Icons.verified,
                                label: 'Platform',
                                value: '${device.deviceType ?? 'Unknown'} (v${device.protocolVersion ?? 0})',
                              ),
                              _CompactDetail(
                                icon: Icons.access_time,
                                label: 'Last Seen',
                                value: lastSeenDate != null ? formatDateTime(lastSeenDate) : 'Never',
                              ),
                            ],
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

class _CompactDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CompactDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final iconColor = Theme.of(context).textTheme.bodySmall?.color;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: RichText(
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: textColor,
          ),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(icon, size: 14, color: iconColor),
              ),
            ),
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isHost = role == 'Host';
    final isUnknown = role == 'Unknown';

    final color = isUnknown
        ? Colors.grey
        : (isHost ? Colors.deepPurple : Colors.teal);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.5)),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}