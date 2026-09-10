import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:noteit/features/local_sync_page/screens/view/scan_qr/widgets/shaded_overlay.dart';


class ScanQrTab extends ConsumerStatefulWidget {
  const ScanQrTab({super.key});

  @override
  ConsumerState<ScanQrTab> createState() => _ScanQrTabState();
}

class _ScanQrTabState extends ConsumerState<ScanQrTab> {
  late final MobileScannerController controller;

  @override
  void initState() {
    controller = MobileScannerController(detectionSpeed: DetectionSpeed.normal);
    controller.start();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // final scanStateProvider = ref.watch(qrScanStateNotifier);

    // When Some User is found show the Card
    // if (scanStateProvider.isUserFound) {
    //   return Card(child: Text("place Holder"),);
    // }

    return Scaffold(

      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return MobileScanner(
              controller: controller,
              scanWindow: null,
              // transparent black overlay for qr code just for visuals no functionality
              overlayBuilder: (context, constraints) {
                return ShadedOverlay(
                  boxConstraints: constraints,
                  onClickGallery: () {},
                  onClickFlash: () {
                    controller.toggleTorch();
                  },
                );
              },

              onDetect: (BarcodeCapture capture) async {
                // this is the avoid qr detection spamming Snack bar
                // if (scanStateProvider.isCoolDown) return;

                final barcode = capture.barcodes.first;
                final String? code = barcode.rawValue;

                // We have code
                if (code != null && code.isNotEmpty) {
                  // print("==== Qr Detected $code");
                  // ref.read(qrScanStateNotifier.notifier).startCooldown();

                  // Separating the appName (fullCode[0]) and userID (fullCode[1])
                  final fullCode = code.split('/');

                  // Is this QR is for my own app?
                  // Yes
                  if (fullCode[0].contains("noteit random string")) {}



                }
              },
            );
          },
        ),
      ),
    );
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
