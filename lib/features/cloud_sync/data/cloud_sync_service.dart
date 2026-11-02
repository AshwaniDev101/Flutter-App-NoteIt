import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(ref);
});

class CloudSyncService {
  final Ref ref;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  CloudSyncService(this.ref);

  void start() {
    if (_isRunning) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      AppLogger.w("CloudSyncService: Cannot start engine. User is not authenticated.");
      return;
    }

    _isRunning = true;
    AppLogger.d("CloudSyncService: Starting Firebase sync engine for user ${user.uid}...");

    executeFullSync();
  }

  void stop() {
    if (!_isRunning) return;
    _isRunning = false;
    AppLogger.d("CloudSyncService: Stopping Firebase sync engine...");
  }

  Future<void> executeFullSync() async {
    if (!_isRunning) return;

    AppLogger.d("CloudSyncService: Executing full sync...");
  }
}
