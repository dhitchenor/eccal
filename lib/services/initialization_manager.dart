import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../dialogs/storage_setup_dialog.dart';
import '../dialogs/caldav_setup_dialogs.dart';
import '../providers/settings_provider.dart';
import '../providers/diary_provider.dart';
import '../services/file_storage_service.dart';
import '../services/logger_service.dart';
import '../utils/app_localizations.dart';

class InitializationManager {
  final BuildContext context;
  final SettingsProvider settingsProvider;
  final DiaryProvider diaryProvider;

  InitializationManager({
    required this.context,
    required this.settingsProvider,
    required this.diaryProvider,
  });

  // Perform all initialization checks and setup
  Future<void> performSetup() async {
    // Configure CalDAV in DiaryProvider
    diaryProvider.setSettingsProvider(settingsProvider);
    diaryProvider.configureCalDAV(
      url: settingsProvider.caldavUrl,
      username: settingsProvider.caldavUsername,
      password: settingsProvider.caldavPassword,
      calendarName: settingsProvider.caldavCalendarName,
      eventDurationMinutes: settingsProvider.eventDurationMinutes,
    );

    // 1. Check storage setup (only shows once on first launch)
    await _checkStorageSetup();

    // 2. Check CalDAV setup (only shows if not configured)
    await _checkCalDAVSetup();

    // 3. Initial sync with CalDAV server
    await _performInitialSync();
  }

  Future<void> _checkStorageSetup() async {
    // Storage setup dialog only needed on Android
    // Desktop/iOS use default Documents directory which is always accessible
    if (!Platform.isAndroid) {
      return;
    }

    final fileStorage = FileStorageService();

    if (await fileStorage.shouldShowStorageSetupDialog()) {
      if (!context.mounted) return;

      final action = await StorageSetupDialog.show(context);

      switch (action) {
        case StorageSetupAction.notNow:
          // Do nothing - show again next launch
          break;

        case StorageSetupAction.dontShowAgain:
          // Mark as shown - never show again, use hidden storage
          await fileStorage.markStorageSetupDialogShown();
          break;

        case StorageSetupAction.chooseLocation:
          // Mark as shown
          await fileStorage.markStorageSetupDialogShown();

          // Open SAF file picker
          if (context.mounted) {
            await _openStoragePicker();
          }
          break;

        case null:
          // Dialog dismissed
          break;
      }
    }
  }

  Future<void> _openStoragePicker() async {
    try {
      if (Platform.isAndroid) {
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

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('setup.storage_saf_success'.tr()),
                backgroundColor: Colors.green,
              ),
            );

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

      // Desktop/iOS - use FilePicker
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        logger.info('User selected storage location: $selectedDirectory');

        // Show confirmation dialog
        if (!context.mounted) return;

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('setup.storage_confirm_location'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${'setup.storage_selected_location'.tr()}:'),
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

        if (confirmed == true) {
          // Move entries to new location
          if (!context.mounted) return;

          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('setup.storage_move_success'.tr()),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              logger.error('Failed to move entries to new location');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('setup.storage_move_failed'.tr()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            logger.error('Error moving entries: $e');
            if (context.mounted) {
              Navigator.pop(context); // Close loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('error'.tr([e.toString()])),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        logger.info('User cancelled storage location selection');
      }
    } catch (e) {
      logger.error('Error opening storage picker: $e');
    }
  }

  Future<void> _checkCalDAVSetup() async {
    final shouldShowPrompt =
        settingsProvider.showInitialSetupPrompt &&
        (settingsProvider.caldavUrl == null ||
            settingsProvider.caldavUrl!.isEmpty);

    if (shouldShowPrompt) {
      if (!context.mounted) return;

      // Show CalDAV setup dialog
      await Future.delayed(const Duration(milliseconds: 300));
      if (context.mounted) {
        CaldavSetupDialog.show(context);
      }
    }
  }

  Future<void> _performInitialSync() async {
    if (diaryProvider.isCalDAVConfigured &&
        !settingsProvider.caldavSyncDisabled) {
      try {
        logger.info('Performing initial CalDAV sync');
        await diaryProvider.syncWithCalDAV();
        logger.info('Initial CalDAV sync completed');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync completed'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        logger.error('Initial CalDAV sync error: $error');
        // Don't show error snackbar - not critical
      }
    }
  }
}
