import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:noteit/features/local_sync/view/qr_scanner/widgets/shaded_overlay.dart';

import '../../provider/sync_client_provider.dart';

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

        // Parse the device name out of URL (e.g., ?name=Varsha's Desktop)
        final uri = Uri.parse(rawValue);

        final ip = uri.host;
        final port = uri.port;
        final hostName = uri.queryParameters['host_name'] ?? 'Unknown Host';
        final hostUuid = uri.queryParameters['host_uuid'] ?? '';

        if (ip.isNotEmpty && port > 0 && hostUuid.isNotEmpty) {
          // Trigger the Riverpod provider with the raw ingredients
          ref
              .read(syncClientProvider.notifier)
              .connectToHost(ip: ip, port: port, hostUuid: hostUuid, hostName: hostName);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connecting to $hostName...')), // Connecting since it's not confirmed yet!
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan to Sync'),
        actions: [IconButton(icon: const Icon(Icons.cameraswitch), onPressed: () => cameraController.switchCamera())],
      ),
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
