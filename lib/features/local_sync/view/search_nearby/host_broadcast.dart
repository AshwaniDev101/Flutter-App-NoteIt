import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/sync_session_provider.dart';
import '../qr/qr_page.dart';

class HostBroadcastPage extends ConsumerWidget {
  const HostBroadcastPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching this provider automatically starts the server and mDNS broadcast.
    // Because it is autoDispose, leaving this page will automatically shut them down.
    final sessionAsync = ref.watch(syncSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Host Sync Session')),
      body: sessionAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Starting server and broadcasting...')],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Failed to host: $error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  // Invalidate forces the provider to retry from scratch
                  onPressed: () => ref.invalidate(syncSessionProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (hostData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_tethering, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                Text('Broadcasting as', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  hostData.deviceName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('IP: ${hostData.ip}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 40),
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 16),
                const Text('Waiting for nearby devices to connect...'),

                // TODO: When we implement the PIN system, display the generated PIN right here!
              ],
            ),
          );
        },
      ),
    );
  }
}
