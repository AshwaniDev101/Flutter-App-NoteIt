import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import '../../database/local_sync_service.dart';

final syncServerProvider = NotifierProvider<SyncServerNotifier, HttpServer?>(() {
  return SyncServerNotifier();
});

class SyncServerNotifier extends Notifier<HttpServer?> {
  @override
  HttpServer? build() {
    ref.onDispose(() => state?.close(force: true));
    return null;
  }

  Future<void> startHosting(String ip) async {
    // If the server is already running, it ignores the command so we don't crash the app
    if (state != null) return;

    print('Starting Host Server on $ip...');

    // This is the receptionist. It just sits and waits for a client (the device that scanned the QR code) to connect.
    var handler = webSocketHandler((webSocketChannel, _) {
      print('A Client has connected to the Host!');

      // second a client connects, the receptionist grabs the live, open data pipeline (webSocketChannel) and hands it over to your localSyncServiceProvider
      ref.read(localSyncServiceProvider.notifier).setActiveConnection(webSocketChannel);

      // Listen for disconnection via the stream or sink done future
      webSocketChannel.sink.done
          .then((_) {
            print('Client disconnected');
            ref.read(localSyncServiceProvider.notifier).stop();
          })
          .catchError((_) {
            ref.read(localSyncServiceProvider.notifier).stop();
          });
    });

    final server = await shelf_io.serve(handler, ip, 8080);
    print('Sync server hosting at ws://${server.address.host}:${server.port}');

    state = server;
  }

  void stopHosting() {
    ref.read(localSyncServiceProvider.notifier).stop();
    state?.close(force: true);
    state = null;
  }
}
