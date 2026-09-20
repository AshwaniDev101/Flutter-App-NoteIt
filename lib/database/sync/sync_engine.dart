import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';


enum SyncEngine { cloud, local, offline }

final syncEngineProvider = NotifierProvider<SyncEngineNotifier, SyncEngine>(() {
  return SyncEngineNotifier();
});

class SyncEngineNotifier extends Notifier<SyncEngine> {
  @override
  SyncEngine build() {
    // Grab the initial saved value when the app boots
    return ref.watch(sharedPreferenceProvider).currentEngine;
  }

  Future<void> setEngine(SyncEngine newEngine) async {
    // Save to the physical device disk
    await ref.read(sharedPreferenceProvider).setCurrentEngine(newEngine);
    // Update the Riverpod state to instantly trigger Firebase/UI listeners
    state = newEngine;
  }
}
