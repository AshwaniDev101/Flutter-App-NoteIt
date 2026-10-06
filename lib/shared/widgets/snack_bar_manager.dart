import 'package:flutter/material.dart';
import 'package:noteit/core/theme/app_typography.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class SnackBarManager {
  static void show({required String msg}) {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        width: 400,
        content: Text(
          msg,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        // margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
        elevation: 0,
      ),
    );
  }
}
