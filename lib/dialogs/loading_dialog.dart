import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';

// Utility class for showing and hiding loading dialogs
class LoadingDialog {
  // Show a loading dialog with "Please wait..." message
  // Returns a function that can be called to close the dialog
  static VoidCallback show(
    BuildContext context, {
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => PopScope(
        canPop: barrierDismissible,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('please_wait'.tr()),
            ],
          ),
        ),
      ),
    );
    
    // Return a function to close the dialog
    return () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };
  }
  
  // Show a simple loading spinner without text
  static VoidCallback showSpinner(
    BuildContext context, {
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => PopScope(
        canPop: barrierDismissible,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
    
    // Return a function to close the dialog
    return () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };
  }
  
  // Hide the loading dialog
  static void hide(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}