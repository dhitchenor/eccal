import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../dialogs/storage_setup_dialog.dart';
import '../providers/diary_provider.dart';
import '../services/file_storage_service.dart';
import '../services/logger_service.dart';
import '../utils/app_localizations.dart';
import '../utils/error_snackbar.dart';

// Helper class for Storage Access Framework (SAF) operations on Android.
class SafHelper {
  static const MethodChannel _channel = MethodChannel(
    'com.dhitchenor.eccal/saf',
  );

  // Pick a directory using SAF and get persistent URI permission
  // Returns the tree URI string if successful, null if cancelled
  static Future<String?> pickDirectory() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }

    try {
      final String? uri = await _channel.invokeMethod('pickDirectory');
      return uri;
    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') {
        return null; // User cancelled
      }
      rethrow;
    }
  }

  // Persist URI permission for a saved tree URI
  // Call this when restoring from SharedPreferences to ensure we still have access
  static Future<bool> persistUriPermission(String uri) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }

    try {
      final bool result = await _channel.invokeMethod('persistUriPermission', {
        'uri': uri,
      });
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Write content to a file in the SAF directory
  // Returns the file URI if successful
  static Future<String> writeFile({
    required String treeUri,
    required String fileName,
    required String content,
    String? subfolder, // Optional subfolder within the SAF directory
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }

    final String fileUri = await _channel.invokeMethod('writeFile', {
      'treeUri': treeUri,
      'fileName': fileName,
      'content': content,
      'subfolder': subfolder, // Pass subfolder to Kotlin
    });
    return fileUri;
  }

  // Write binary content (bytes) to a file in the SAF directory (with optional subfolder)
  // Returns the file URI if successful
  // Use this for ZIP files, PDFs, images, etc.
  static Future<String> writeFileBytes({
    required String treeUri,
    required String fileName,
    required List<int> bytes,
    String? subfolder, // Optional subfolder within the SAF directory
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }

    final String fileUri = await _channel.invokeMethod('writeFileBytes', {
      'treeUri': treeUri,
      'fileName': fileName,
      'bytes': Uint8List.fromList(
        bytes,
      ), // Convert to Uint8List for platform channel
      'subfolder': subfolder,
    });
    return fileUri;
  }

  // Read content from a file in the SAF directory
  static Future<String> readFile({
    required String treeUri,
    required String fileName,
    String? subfolder,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }

    final String content = await _channel.invokeMethod('readFile', {
      'treeUri': treeUri,
      'fileName': fileName,
      'subfolder': subfolder,
    });
    return content;
  }

  /// List all .ics files in the SAF directory
  static Future<List<String>> listFiles(
    String treeUri, {
    String? subfolder,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }

    final List<dynamic> files = await _channel.invokeMethod('listFiles', {
      'treeUri': treeUri,
      'subfolder': subfolder,
    });
    return files.cast<String>();
  }

  // Delete a file from the SAF directory
  static Future<bool> deleteFile({
    required String treeUri,
    required String fileName,
    String? subfolder, // Optional subfolder within the SAF directory
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }

    final bool deleted = await _channel.invokeMethod('deleteFile', {
      'treeUri': treeUri,
      'fileName': fileName,
      'subfolder': subfolder,
    });
    return deleted;
  }

  // Check if we still have access to a saved URI
  static Future<bool> checkAccess(String uri) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }

    final bool hasAccess = await _channel.invokeMethod('checkAccess', {
      'uri': uri,
    });
    return hasAccess;
  }

  /// Get display name for a tree URI (folder name)
  static Future<String?> getDisplayName(String treeUri) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }

    try {
      final String? name = await _channel.invokeMethod('getDisplayName', {
        'treeUri': treeUri,
      });
      return name;
    } on PlatformException catch (_) {
      return null;
    }
  }

  // Open storage picker and handle selection
  //
  // Handles both Android SAF and Desktop/iOS file picker
  static Future<void> openStoragePicker(
    BuildContext context,
    DiaryProvider diaryProvider,
  ) async {
    try {
      if (Platform.isAndroid) {
        await _handleAndroidSAFPicker(context, diaryProvider);
      } else {
        await _handleDesktopFilePicker(context, diaryProvider);
      }
    } catch (e) {
      logger.error('Error opening storage picker: $e');
    }
  }

  // Handle Android SAF picker
  static Future<void> _handleAndroidSAFPicker(
    BuildContext context,
    DiaryProvider diaryProvider,
  ) async {
    // Use SAF on Android - loop until valid selection or cancel
    while (true) {
      final fileStorage = FileStorageService();
      final result = await fileStorage.pickAndSaveDirectory();

      if (result == 'DOWNLOADS_BLOCKED') {
        // Downloads folder blocked - show warning and try again
        if (!context.mounted) return;

        final retry = await DownloadsWarningDialog.show(context);

        if (retry != true) {
          // User cancelled
          return;
        }

        // Loop continues - picker will open again
        continue;
      } else if (result != null) {
        // SAF selection successful
        logger.info('SAF directory selected');

        if (!context.mounted) return;

        ErrorSnackbar.showSuccess(context, 'setup.storage_saf_success'.tr());

        // Reload entries from new location
        await diaryProvider.loadEntriesFromStorage();
        return;
      } else {
        // User cancelled picker
        logger.info('User cancelled SAF picker');
        return;
      }
    }
  }

  // Handle Desktop/iOS file picker
  static Future<void> _handleDesktopFilePicker(
    BuildContext context,
    DiaryProvider diaryProvider,
  ) async {
    // Use FilePicker for Desktop/iOS
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      logger.info('User cancelled storage location selection');
      return;
    }

    logger.info('User selected storage location: $selectedDirectory');

    // Show confirmation dialog
    if (!context.mounted) return;

    final confirmed = await showConfirmationDialog(context, selectedDirectory);

    if (confirmed != true) return;

    // Move entries to new location
    await moveEntriesToNewLocation(context, diaryProvider, selectedDirectory);
  }

  // Show confirmation dialog for selected directory
  static Future<bool?> showConfirmationDialog(
    BuildContext context,
    String selectedDirectory,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('setup.storagenotice.confirm_location'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'setup.storagenotice.selected_location'.tr()}:'),
            const SizedBox(height: 8),
            Text(
              selectedDirectory,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }

  // Move entries to new storage location
  static Future<void> moveEntriesToNewLocation(
    BuildContext context,
    DiaryProvider diaryProvider,
    String selectedDirectory,
  ) async {
    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await diaryProvider.moveEntriesToNewLocation(
        selectedDirectory,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      if (success) {
        logger.info('Successfully moved entries to new location');
        if (context.mounted) {
          ErrorSnackbar.showSuccess(context, 'setup.storage_move_success'.tr());
        }
      } else {
        logger.error('Failed to move entries to new location');
        if (context.mounted) {
          ErrorSnackbar.showError(context, 'setup.storage_move_failed'.tr());
        }
      }
    } catch (e) {
      logger.error('Error moving entries: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ErrorSnackbar.showError(context, 'error_'.tr([e.toString()]));
      }
    }
  }
}
