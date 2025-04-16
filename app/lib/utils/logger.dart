import 'package:flutter/foundation.dart';

/// A simple logger utility that only logs in debug mode
class Logger {
  final String _tag;

  /// Creates a new logger with the specified tag
  Logger(this._tag);

  /// Log an informational message
  void info(String message) {
    _log('INFO', message);
  }

  /// Log a debug message
  void debug(String message) {
    _log('DEBUG', message);
  }

  /// Log an error message with optional exception
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', '$message ${error != null ? '- $error' : ''}');
    if (kDebugMode && stackTrace != null) {
      print(stackTrace);
    }
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('WARNING', '$message ${error != null ? '- $error' : ''}');
    if (kDebugMode && stackTrace != null) {
      print(stackTrace);
    }
  }

  /// Internal logging method that only logs in debug mode
  void _log(String level, String message) {
    if (kDebugMode) {
      print('[$level] $_tag: $message');
    }
  }
}
