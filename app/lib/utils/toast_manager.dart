import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// A utility class for showing toast notifications
class ToastManager {
  // Keep track of the current processing toast
  static FToast? _fToast;
  static Widget? _currentProcessingToast;

  /// Shows a success toast notification
  ///
  /// [message] The message to display in the toast
  static void showSuccess(String message) {
    // Cancel any processing toast first
    _cancelProcessingToast();

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Shows an error toast notification
  ///
  /// [message] The message to display in the toast
  static void showError(String message) {
    // Cancel any processing toast first
    _cancelProcessingToast();

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Shows a warning toast notification
  ///
  /// [message] The message to display in the toast
  static void showWarning(String message) {
    // Cancel any processing toast first
    _cancelProcessingToast();

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Shows a processing toast notification that stays visible until canceled
  ///
  /// [message] The message to display in the toast
  /// [context] The BuildContext for showing the toast
  static void showProcessing(String message, BuildContext context) {
    // Cancel any existing processing toast first
    _cancelProcessingToast();

    // Initialize FToast
    _fToast = FToast();
    _fToast!.init(context);

    // Create the custom toast widget
    _currentProcessingToast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.grey[700],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12.0),
          Text(message, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );

    // Show the toast
    _fToast!.showToast(
      child: _currentProcessingToast!,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(
        days: 1,
      ), // Effectively &quot;forever&quot; until canceled
    );
  }

  /// Cancels any currently showing processing toast
  static void _cancelProcessingToast() {
    if (_fToast != null && _currentProcessingToast != null) {
      _fToast!.removeQueuedCustomToasts();
      _currentProcessingToast = null;
    }
  }

  /// Explicitly cancel a processing toast from outside
  static void cancelProcessing() {
    _cancelProcessingToast();
  }
}
