import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

// Assuming you still have this from your previous setup
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class SnackBarManager {
  static void show({required String msg}) {
    // Grab the context in the background so we can match your app's exact theme!
    final context = scaffoldMessengerKey.currentContext;

    toastification.show(
      context: context, // This line is crucial for Dark Mode support
      title: Text(
        msg,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      type: ToastificationType.success,

      // 'fillColored' gives a solid, native look without weird accent borders
      style: ToastificationStyle.fillColored,

      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 3),

      // Ensures the shrinking time bar is completely hidden
      showProgressBar: false,

      // Use the new `closeButton` parameter wrapping the `ToastCloseButton` configuration
      closeButton: const ToastCloseButton(
        showType: CloseButtonShowType.none,
      ),

      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      // Creates a subtle, premium shadow
      boxShadow: highModeShadow,
    );
  }
}