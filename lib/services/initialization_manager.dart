import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';
import '../providers/diary_provider.dart';
import '../services/google_calendar_service.dart';
import '../services/setup_dialogs_manager.dart';
import '../services/logger_service.dart';

// Manages app initialization sequence
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

    // 3. Perform initial sync if server is configured
    await _performInitialSync();
  }

  // Check and show storage setup dialog if needed
  Future<void> _checkStorageSetup() async {
    await SetupDialogsManager.checkAndShowStorageSetup(
      context: context,
      diaryProvider: diaryProvider,
    );
  }

  // Check and show calendar server setup dialog if needed
  Future<void> _checkCalendarServerSetup() async {
    await SetupDialogsManager.checkAndShowInitialServerSetup(
      context: context,
      settingsProvider: settingsProvider,
      googleCalendarService: googleCalendarService,
    );
  }

  // Perform initial sync with calendar server if configured
  Future<void> _performInitialSync() async {
    // Check if provider is authenticated
    final provider = settingsProvider.calendarProvider;
    bool isProviderAuthenticated = false;

    if (provider == CalendarProvider.caldav) {
      // Get password from secure storage first
      String? password;
      try {
        password = await settingsProvider.caldavPassword;
      } catch (e) {
        logger.error('Failed to retrieve CalDAV password: $e');
        password = null;
      }

      // Check if CalDAV is fully configured
      isProviderAuthenticated =
          settingsProvider.caldavUrl != null &&
          settingsProvider.caldavUrl!.isNotEmpty &&
          settingsProvider.caldavUsername != null &&
          settingsProvider.caldavUsername!.isNotEmpty &&
          password != null &&
          password.isNotEmpty &&
          settingsProvider.caldavCalendarName != null &&
          settingsProvider.caldavCalendarName!.isNotEmpty;
    } else if (provider == CalendarProvider.google) {
      // Check if Google Calendar is configured (has calendar ID and email)
      isProviderAuthenticated =
          settingsProvider.googleCalendarId != null &&
          settingsProvider.googleCalendarId!.isNotEmpty &&
          settingsProvider.googleUserEmail != null &&
          settingsProvider.googleUserEmail!.isNotEmpty;
    }

    // Perform initial server sync (ONLY if authenticated and sync enabled)
    final shouldSync =
        isProviderAuthenticated &&
        !settingsProvider.caldavSyncDisabled &&
        diaryProvider.isCalDAVConfigured;

    if (shouldSync) {
      try {
        logger.info('Performing initial server sync');
        await diaryProvider.syncWithCalDAV();
        logger.info('Initial server sync completed');
      } catch (e) {
        logger.error('Initial server sync failed: $e');
        // Don't show error to user - this is handled during startup
      }
    } else {
      logger.info('Skipping server sync - not authenticated or sync disabled');
    }
  }
}
