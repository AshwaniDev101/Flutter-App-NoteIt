import 'package:drift/wasm.dart';

void main() {
  // This is the modern, high-performance worker initialization
  WasmDatabase.workerMainForOpen();

  // run this code to make drift work for web: dart compile js web/drift_worker.dart -o web/drift_worker.js
}