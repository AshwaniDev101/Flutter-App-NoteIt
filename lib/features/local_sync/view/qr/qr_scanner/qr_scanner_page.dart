import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:noteit/features/local_sync/view/qr/qr_scanner/widgets/shaded_overlay.dart';

import '../../../provider/sync_client_provider.dart';
import '../../../../../shared/app_scaffold.dart';
import '../../../../../shared/snack_bar_manager.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isConnecting = false;

  void _onDetect(BarcodeCapture capture) {
    // Prevent multiple triggers while processing the first valid scan
    if (_isConnecting) return;

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;

      // Ensure we only react to our specific WebSocket URL format
      if (rawValue != null && rawValue.startsWith('ws://')) {
        setState(() => _isConnecting = true);

        // Stop the camera immediately to save resources
        cameraController.stop();

        // Parse the device name out of URL
        final uri = Uri.parse(rawValue);

        final ip = uri.host;
        final port = uri.port;
        final hostName = uri.queryParameters['host_name'] ?? 'Unknown Host';
        final hostUuid = uri.queryParameters['host_uuid'] ?? '';

        // --- Extract strict platform and version from the QR URL ---
        final devicePlatform = uri.queryParameters['host_platform'] ?? 'unknown';
        final vStr = uri.queryParameters['v'];
        final protocolVersion = vStr != null ? (int.tryParse(vStr) ?? 0) : 0;
        // ----------------------------------------------------------------

        if (ip.isNotEmpty && port > 0 && hostUuid.isNotEmpty) {

          // Trigger the Riverpod provider with the raw ingredients AND new metadata
          ref.read(syncClientProvider.notifier).connectToHost(
            ip: ip,
            port: port,
            hostUuid: hostUuid,
            hostName: hostName,
            devicePlatform: devicePlatform,
            protocolVersion: protocolVersion,
          );

          SnackBarManager.show(
            msg: 'Connecting to $hostName...',
            type: SnackBarMessageType.info,
          );
        }

        // Pop the scanner page to return to the main app
        if (mounted) {
          Navigator.pop(context);
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.scan,
      actions: [IconButton(icon: const Icon(Icons.cameraswitch), onPressed: () => cameraController.switchCamera())],
      body: MobileScanner(
        controller: cameraController,
        onDetect: _onDetect,

        overlayBuilder: (context, constraints) {
          return ShadedOverlay(
            boxConstraints: constraints,
            onClickGallery: () {},
            onClickFlash: () {
              cameraController.toggleTorch();
            },
          );
        },
      ),
    );
  }
}
