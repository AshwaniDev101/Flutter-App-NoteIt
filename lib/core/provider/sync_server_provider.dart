import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import '../../database/local_sync_service.dart';

class SyncServerNotifier extends Notifier<HttpServer?> {
  @override
  HttpServer? build() {
    ref.onDispose(() => state?.close(force: true));
    return null;
  }

  Future<void> startHosting(String ip) async {
    if (state != null) return;

    print('Starting Host Server on $ip...');

    var handler = webSocketHandler((webSocketChannel, _) {
      print('A Client has connected to the Host!');

      ref.read(localSyncServiceProvider).setActiveConnection(webSocketChannel);

      // Listen for disconnection via the stream or sink done future
      webSocketChannel.sink.done.then((_) {
        print('Client disconnected');
        ref.read(localSyncServiceProvider).stop();
      }).catchError((_) {
        ref.read(localSyncServiceProvider).stop();
      });
    });

    final server = await shelf_io.serve(handler, ip, 8080);
    print('Sync server hosting at ws://${server.address.host}:${server.port}');

    state = server;
  }

  void stopHosting() {
    ref.read(localSyncServiceProvider).stop();
    state?.close(force: true);
    state = null;
  }
}

final syncServerProvider = NotifierProvider<SyncServerNotifier, HttpServer?>(() {
  return SyncServerNotifier();
});