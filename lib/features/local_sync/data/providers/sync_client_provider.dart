import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/config/config.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/core/util/device_info.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/drift/synced_devices/synced_devices_dao.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/local_sync/data/network/local_sync_service.dart';
import 'package:noteit/features/local_sync/data/network/mdns_broadcast.dart';
import 'package:noteit/features/local_sync/data/providers/local_sync_session_manager.dart';
import 'package:noteit/features/local_sync/data/providers/sync_server_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final syncClientProvider = NotifierProvider<SyncClientNotifier, WebSocketChannel?>(() {
  return SyncClientNotifier();
});

class SyncClientNotifier extends Notifier<WebSocketChannel?> {
  @override
  WebSocketChannel? build() {
    ref.onDispose(disconnect);
    return null;
  }

  Future<void> connectToHost({
    required String ip,
    required int port,
    required String hostUuid,
    required String hostName,
    String? pin,
    required String devicePlatform,
    required int protocolVersion,
  }) async {
    // --- POLICE CODE: ENFORCE MUTUAL EXCLUSIVITY ---
    final isHostActive = ref.read(syncServerProvider) != null;
    if (isHostActive) {
      AppLogger.d('SyncClientNotifier: Device is hosting. Shutting down server before connecting as Client...');
      ref.read(syncServerProvider.notifier).stopHosting();
      ref.read(mdnsBroadcastProvider.notifier).stopBroadcasting();
    }
    // -----------------------------------------------

    disconnect();

    AppLogger.d('SyncClientNotifier: Attempting to connect to Host at $ip:$port');

    try {
      final String myUuid = ref.read(sharedPreferenceProvider).hostUuid;

      final BaseDeviceInfo info = await ref.read(deviceInfoProvider.future);
      final myDeviceName = info.extractName;
      final myPlatform = info.extractPlatform;

      final Map<String, dynamic> queryParams = {
        'host_uuid': hostUuid,
        'host_name': hostName,
        'client_uuid': myUuid,
        'client_name': myDeviceName,
        'client_platform': myPlatform,
        'v': AppConfig.syncProtocolVersion.toString(),
      };
      if (pin != null) {
        queryParams['pin'] = pin;
      }

      final finalUri = Uri(scheme: 'ws', host: ip, port: port, queryParameters: queryParams);

      final channel = WebSocketChannel.connect(finalUri);

      try {
        await channel.ready.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            channel.sink.close();
            throw TimeoutException('Ghost IP or Host unreachable');
          },
        );

        AppLogger.d('SyncClientNotifier: Connection Confirmed!');

        await ref.read(syncModeProvider.notifier).setMode(SyncMode.localClient);

        await ref.read(syncedDevicesDaoProvider).upsertDeviceAsHost(
          uuid: hostUuid,
          name: hostName,
          lastKnownIp: ip,
          lastKnownPort: port,
          deviceType: devicePlatform,
          protocolVersion: protocolVersion,
        );
        AppLogger.d('SyncClientNotifier: Saved Host $hostName to Drift DB.');

        state = channel;

        ref.read(localSyncSessionProvider.notifier).establishSession(
          channel: channel,
          role: SyncRole.client,
          peerUuid: hostUuid,
          peerName: hostName,
          peerPlatform: devicePlatform,
        );
      } catch (_) {
        if (state != channel) {
          channel.sink.close();
        }
        rethrow;
      }

    } on TimeoutException catch (e) {
      AppLogger.w('SyncClientNotifier: Hit a Ghost IP or router blocked connection: $e');
      state = null;
      throw Exception('Host not found. Please try scanning the QR code.');

    } on WebSocketChannelException catch (e) {
      AppLogger.w('SyncClientNotifier: Connection rejected by host. Wrong PIN? Error: $e');
      state = null;
      throw Exception('Connection rejected. Please check the PIN and try again.');

    } catch (e, st) {
      AppLogger.e('SyncClientNotifier: Failed to connect to host', error: e, stack: st);
      state = null;
      throw Exception('Failed to connect to device.');
    }
  }

  void disconnect() {
    if (state != null) {
      AppLogger.d("SyncClientNotifier: Disconnecting from host...");
      ref.read(localSyncServiceProvider.notifier).stop();

      state?.sink.close();
      state = null;
    }
  }
}
