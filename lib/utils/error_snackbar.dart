import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';

// General-purpose error snackbar utility for consistent error handling across the app
class ErrorSnackbar {
  // Show a generic error snackbar
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message,
      Colors.red,
      duration: duration,
      action: action,
    );
  }

  // Show a warning snackbar (orange)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message,
      Colors.orange,
      duration: duration,
      action: action,
    );
  }

  // Show a success snackbar (green)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackbar(context, message, Colors.green, duration: duration);
  }

  // Show an info snackbar (blue)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackbar(context, message, Colors.blue, duration: duration);
  }

  // Show a user-friendly error for keyring/secure storage issues
  static void showKeyringError(BuildContext context, dynamic error) {
    if (!SettingsProvider.isKeyringError(error)) {
      // Not a keyring error - show generic error
      showError(context, 'An error occurred: ${error.toString()}');
      return;
    }

    // Keyring-specific error - show helpful message with action button
    showWarning(
      context,
      'Keyring service not available. '
      'Please install gnome-keyring or kwalletmanager. '
      'See FAQ for details.',
      duration: const Duration(seconds: 10), // Longer for important message
      action: SnackBarAction(
        label: 'Help',
        textColor: Colors.white,
        onPressed: () {
          // TODO: Open FAQ in browser or show dialog
          // For now, just dismiss
        },
      ),
    );
  }

  // Try to execute an async function and show appropriate snackbar feedback
  static Future<bool> tryAsync(
    BuildContext context,
    Future<void> Function() action, {
    String? successMessage,
    String? errorPrefix,
    bool showGenericError = true,
  }) async {
    try {
      await action();
      if (successMessage != null && context.mounted) {
        showSuccess(context, successMessage);
      }
      return true;
    } catch (e) {
      if (context.mounted && showGenericError) {
        final message = errorPrefix != null
            ? '$errorPrefix: ${e.toString()}'
            : e.toString();
        showError(context, message);
      }
      return false;
    }
  }

  // Try an async operation with specific handling for keyring errors
  static Future<bool> tryAsyncWithKeyring(
    BuildContext context,
    Future<void> Function() action, {
    String? successMessage,
    String? errorPrefix,
  }) async {
    try {
      await action();
      if (successMessage != null && context.mounted) {
        showSuccess(context, successMessage);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        // Check if it's a keyring error first
        if (SettingsProvider.isKeyringError(e)) {
          showKeyringError(context, e);
        } else {
          // Generic error
          final message = errorPrefix != null
              ? '$errorPrefix: ${e.toString()}'
              : e.toString();
          showError(context, message);
        }
      }
      return false;
    }
  }

  // Generic snackbar helper (private)
  static void _showSnackbar(
    BuildContext context,
    String message,
    Color backgroundColor, {
    Duration duration = const Duration(seconds: 5),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }
}
