import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Central logging utility used across the app.
/// Wraps the 'logger' package so logging behavior can be controlled
/// from a single place (levels, formatting, debug filtering).
class AppLogger {

  /// Internal logger instance configured for development-friendly output.
  static final Logger _logger = Logger(
    filter: DevelopmentFilter(),          // Suppress most logs in release builds
    // printer: PrettyPrinter(
    //     methodCount: 1,                     // Show limited stack trace for readability
    //     errorMethodCount: 8,                // Show more stack info for errors
    //     lineLength: 120,                    // Max line width
    //     colors: true,                       // Colored logs in supported terminals
    //     printEmojis: true,                  // Adds emojis for log level indicators
    //     dateTimeFormat: DateTimeFormat.none // Disable timestamp printing
    // ),
    printer: SimplePrinter(
      colors: true,
      printTime: false,
    ),
    level: kDebugMode ? Level.debug : Level.warning, // Less verbose logging in release
  );

  /// Trace log for very detailed debugging information.
  /// Only runs in debug mode.
  static void t(dynamic message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) _logger.t(message, error: error, stackTrace: stack);
  }

  /// Debug log for development details such as variable values or state changes.
  /// Only runs in debug mode.
  static void d(dynamic message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) _logger.d(message, error: error, stackTrace: stack);
  }

  /// Informational log for normal app flow or successful operations.
  static void i(dynamic message, [Object? error, StackTrace? stack]) {
    _logger.i(message, error: error, stackTrace: stack);
  }

  /// Warning log for unexpected situations that do not crash the app.
  static void w(dynamic message, [Object? error, StackTrace? stack]) {
    _logger.w(message, error: error, stackTrace: stack);
  }

  /// Error log for exceptions or serious failures.
  static void e(dynamic message, {Object? error, StackTrace? stack}) {
    _logger.e(message, error: error, stackTrace: stack);
  }

  /// Fatal log for critical failures where the app may become unusable.
  static void f(dynamic message, {Object? error, StackTrace? stack}) {
    _logger.f(message, error: error, stackTrace: stack);
  }
}