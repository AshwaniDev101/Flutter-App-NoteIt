import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../provider/sync_session_provider.dart';



class QrCodePage extends ConsumerWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the FutureProvider
    final syncSessionAsync = ref.watch(syncSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Local Sync'),
        centerTitle: true,

        // actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.share))],
      ),

      // Use Riverbed's .when() to handle the loading, error, and success states
      body: syncSessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Network Error: $error')),
        data: (syncData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            syncData.deviceName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade800),
                          ),
                          // Text("LanternChat Contact", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade800)),
                          SizedBox(height: 8),
                          Container(
                            color: Colors.white,
                            height: 200,
                            width: 200,
                            child: QrImageView(data: syncData.qrUrl),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Scan this QR code using Note-It on another device to sync over Wi-Fi.',
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.push(AppRoutes.scan);
                  },
                  child: const Text("Scan QR"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
