import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import '../../../database/drift/device_pairs/device_pairs_dao.dart';
import '../../../database/sync/local_sync_service.dart';

final syncServerProvider = NotifierProvider<SyncServerNotifier, HttpServer?>(() {
  return SyncServerNotifier();
});

class SyncServerNotifier extends Notifier<HttpServer?> {
  String _currentPin = '';

  @override
  HttpServer? build() {
    ref.onDispose(() => state?.close(force: true));
    return null;
  }

  Future<({String ip, int port})> startHosting({required String ip, required String expectedPin}) async {
    //ALWAYS update the PIN, even if the server is already running!
    _currentPin = expectedPin;

    // If the server is already running, it ignores the command so we don't crash the app
    if (state != null) {
      // Server is already running, just hand back its existing URL
      // 'ws://${server.address.host}:${server.port}';
      return (ip: state!.address.host, port: state!.port);
    }

    print('Starting Host Server on $ip...');

    // This is the receptionist. It just sits and waits for a client (the device that scanned the QR code) to connect.
    var wsHandler = webSocketHandler((webSocketChannel, _) {
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

    final authHandler = _createAuthHandler(wsHandler);

    // 8080 is common for web servers testing, 0 to let the OS pick a port
    final server = await shelf_io.serve(authHandler, ip, 0);
    print('Sync server hosting at ws://${server.address.host}:${server.port}');

    state = server;
    return (ip: state!.address.host, port: state!.port);
  }

  /// Middleware that checks the PIN and Database before allowing WebSocket access
  Handler _createAuthHandler(Handler wsHandler) {
    return (Request request) async {
      final queryParams = request.requestedUri.queryParameters;
      final clientUuid = queryParams['client_uuid'];
      final clientName = queryParams['client_name'];
      final clientPin = queryParams['pin'];

      if (clientUuid == null) {
        return Response.badRequest(body: 'Missing client_uuid');
      }

      final devicePairsDao = ref.read(devicePairsDaoProvider);
      final isKnown = await devicePairsDao.isDeviceKnown(clientUuid);

      if (!isKnown) {
        // Verify PIN
        if (clientPin != _currentPin) {
          print("Host: Connection rejected. Invalid PIN from $clientName.");
          return Response.forbidden('Invalid PIN');
        } else {
          // PIN matched! Whitelist them for next time
          print("Host: PIN matched! Trusting $clientName...");
          await devicePairsDao.upsertDeviceAsClient(uuid: clientUuid, name: clientName ?? 'Unknown Device');
        }
      } else {
        print("Host: Known device connecting ($clientName)");
      }

      // Authorization passed, hand off to the WebSocket handler
      return wsHandler(request);
    };
  }

  void stopHosting() {
    ref.read(localSyncServiceProvider.notifier).stop();
    state?.close(force: true);
    state = null;
  }
}
