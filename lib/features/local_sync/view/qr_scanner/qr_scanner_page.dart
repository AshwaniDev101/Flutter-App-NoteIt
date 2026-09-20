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
        final hostName = uri.queryParameters['name'] ?? 'Unknown Host';

        // Trigger the Riverpod provider to establish the connection
        ref.read(syncClientProvider.notifier).connectToHost(rawValue);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected to $hostName!')));

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
      body: Stack(
        children: [
          MobileScanner(
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
          // Show a loading overlay the moment a valid code is detected
          if (_isConnecting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Establishing connection...')],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
