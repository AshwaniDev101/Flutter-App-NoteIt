import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../provider/sync_session_provider.dart';
import '../../../../shared/overlays/app_scaffold.dart';
import '../../../../shared/overlays/snack_bar_manager.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

class QrCodePage extends ConsumerWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the FutureProvider
    final syncSessionAsync = ref.watch(syncSessionProvider);

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.qr,
      body: syncSessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Network Error: $error')),
        data: (syncData) {
          final colorScheme = Theme.of(context).colorScheme;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            syncData.deviceName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white, // Keep QR background white for high contrast scanning
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SizedBox(
                              height: 200,
                              width: 200,
                              child: QrImageView(data: syncData.qrUrl),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Scan this QR code using Note-It on another device to sync over Wi-Fi.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.scan);
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text("Scan QR"),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: syncData.qrUrl));
                          SnackBarManager.show(
                            msg: 'Connection URL copied to clipboard!',
                            type: SnackBarMessageType.info,
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text("Copy Link"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
