import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../dialogs/storage_setup_dialog.dart';
import '../dialogs/caldav_setup_dialogs.dart';
import '../providers/settings_provider.dart';
import '../providers/diary_provider.dart';
import '../services/file_storage_service.dart';
import '../services/google_calendar_service.dart';
import '../services/logger_service.dart';
import '../utils/app_localizations.dart';
import '../utils/error_snackbar.dart';

class InitializationManager {
  final BuildContext context;
  final SettingsProvider settingsProvider;
  final DiaryProvider diaryProvider;
  final GoogleCalendarService googleCalendarService;

  InitializationManager({
    required this.context,
    required this.settingsProvider,
    required this.diaryProvider,
    required this.googleCalendarService,
  });

  // Perform all initialization checks and setup
  Future<void> setupPrompts() async {
    // 1. Check storage setup (only shows once on first launch)
    await _checkStorageSetup();

    // 2. Check calendar server setup (CalDAV or Google Calendar)
    await _checkCalendarServerSetup();
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

            ErrorSnackbar.showSuccess(
              context,
              'setup.storage_saf_success'.tr(),
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
                ErrorSnackbar.showSuccess(
                  context,
                  'setup.storage_move_success'.tr(),
                );
              }
            } else {
              logger.error('Failed to move entries to new location');
              if (context.mounted) {
                ErrorSnackbar.showError(
                  context,
                  'setup.storage_move_failed'.tr(),
                );
              }
            }
          } catch (e) {
            logger.error('Error moving entries: $e');
            if (context.mounted) {
              Navigator.pop(context); // Close loading
              ErrorSnackbar.showError(
                context,
                'error_'.tr([e.toString()]),
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

  Future<void> _checkCalendarServerSetup() async {
    // Skip if user disabled the initial setup prompt
    if (!settingsProvider.showInitialSetupPrompt) {
      return;
    }

    // Check if any calendar server is already configured
    final hasCalDAV = settingsProvider.caldavUrl != null &&
        settingsProvider.caldavUrl!.isNotEmpty;
    final hasGoogleCalendar = settingsProvider.calendarProvider == CalendarProvider.google &&
        googleCalendarService.isSignedIn &&
        settingsProvider.googleCalendarId != null;

    // If either CalDAV or Google Calendar is configured, skip setup
    if (hasCalDAV || hasGoogleCalendar) {
      logger.info('Calendar server already configured, skipping setup');
      return;
    }

    // Neither is configured - show setup dialog
    if (!context.mounted) return;

    // Small delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));

    if (context.mounted) {
      logger.info('No calendar server configured, showing setup dialog');
      CaldavSetupDialog.show(context);
    }
  }

  Future<void> _performInitialSync() async {
    // Skip if sync is disabled
    if (settingsProvider.caldavSyncDisabled) {
      logger.info('Sync disabled in settings, skipping initial sync');
      return;
    }

    // Check if any calendar server is configured
    if (!diaryProvider.isCalDAVConfigured) {
      logger.info('No calendar server configured, skipping initial sync');
      return;
    }

    try {
      logger.info('Performing initial calendar sync');
      await diaryProvider.syncWithCalDAV();
      logger.info('Initial calendar sync completed');

      if (context.mounted) {
        ErrorSnackbar.showSuccess(
          context,
          'sync_completed'.tr(),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (error) {
      logger.error('Initial calendar sync error: $error');

      // Check if it's an authentication error (Google Calendar token expired)
      final errorString = error.toString();
      if (errorString.contains('Authentication failed') ||
          errorString.contains('401') ||
          errorString.contains('Invalid Credentials')) {
        logger.error('Authentication error detected - user may need to re-authenticate');

        // Show user-friendly error message
        if (context.mounted) {
          ErrorSnackbar.showWarning(
            context,
            'setup.sync_auth_failed'.tr(),
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        // Other sync errors - less critical, just log
        logger.info('Sync failed but not critical: $error');
      }
    }
  }
}
