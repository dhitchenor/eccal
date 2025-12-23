import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dialogs/calendar_verification_dialog.dart';
import '../dialogs/caldav_setup_dialogs.dart';
import '../dialogs/storage_setup_dialog.dart';
import '../dialogs/timezone_setup_dialogs.dart';
import '../providers/settings_provider.dart';
import '../providers/diary_provider.dart';
import '../screens/settings_screen.dart';
import '../services/file_storage_service.dart';
import '../services/google_calendar_service.dart';
import '../services/logger_service.dart';
import '../utils/saf_helper.dart';

// Manages all initial setup dialogs and flows
class SetupDialogsManager {
  final TabController tabController;
  final BuildContext Function() getContext;
  bool _hasShownVerificationDialog = false;

  SetupDialogsManager({required this.tabController, required this.getContext}) {
    tabController.addListener(_onTabChanged);
  }

  void dispose() {
    tabController.removeListener(_onTabChanged);
  }

  // STORAGE SETUP
  // =============================

  static Future<void> checkAndShowStorageSetup({
    required BuildContext context,
    required DiaryProvider diaryProvider,
  }) async {
    // Storage setup dialog only needed on Android
    if (!Platform.isAndroid) return;

    final fileStorage = FileStorageService();

    if (await fileStorage.shouldShowStorageSetupDialog()) {
      if (!context.mounted) return;

      final action = await StorageSetupDialog.show(context);

      switch (action) {
        case StorageSetupAction.skip:
          break;

        case StorageSetupAction.cancel:
          await fileStorage.markStorageSetupDialogShown();
          break;

        case StorageSetupAction.choose:
          await fileStorage.markStorageSetupDialogShown();
          if (context.mounted) {
            await SafHelper.openStoragePicker(context, diaryProvider);
          }
          break;

        case null:
          break;
      }
    }
  }

  // SERVER SETUP
  // =============================

  static Future<void> checkAndShowInitialServerSetup({
    required BuildContext context,
    required SettingsProvider settingsProvider,
    GoogleCalendarService? googleCalendarService,
  }) async {
    if (!settingsProvider.initialServerSetup) {
      logger.info('Server setup flag disabled, checking remaining dialogs');
      await _checkRemainingInitialDialogsStatic(context, settingsProvider);
      return;
    }

    final hasServer = _checkServerConfigured(
      settingsProvider,
      googleCalendarService,
    );

    if (hasServer) {
      logger.info('Calendar server already configured');
      await settingsProvider.disableInitialServerSetup();
      await _checkRemainingInitialDialogsStatic(context, settingsProvider);
      return;
    }

    if (!context.mounted) return;

    await Future.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) return;

    logger.debug('Showing server setup dialog');
    await settingsProvider.setInitialSetupFlow(true);

    // Show dialog and await user action
    final action = await CaldavSetupDialog.show(context);

    logger.debug('Server setup dialog returned: $action');

    if (!context.mounted) return;

    // Handle user's choice
    switch (action) {
      case ServerSetupAction.cancel:
        logger.debug('User chose: Don\'t show again');
        await settingsProvider.disableInitialServerSetup();
        await settingsProvider.setInitialSetupFlow(false);
        await _checkRemainingInitialDialogsStatic(context, settingsProvider);
        break;

      case ServerSetupAction.skip:
        logger.debug('User chose: Skip');
        await settingsProvider.setInitialSetupFlow(false);
        await _checkRemainingInitialDialogsStatic(context, settingsProvider);
        break;

      case ServerSetupAction.setup:
        logger.debug('User chose: Setup Server');
        // Navigate to Settings - initial setup flow stays true
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SettingsScreen(initialTabIndex: 3),
          ),
        );
        break;

      case null:
        logger.debug('Dialog returned null');
        await settingsProvider.setInitialSetupFlow(false);
        break;
    }
  }

  /// Check if server is configured
  static bool _checkServerConfigured(
    SettingsProvider settings,
    GoogleCalendarService? googleService,
  ) {
    final hasCalDAV =
        settings.caldavUrl != null && settings.caldavUrl!.isNotEmpty;
    final hasGoogle =
        settings.calendarProvider == CalendarProvider.google &&
        (googleService?.isSignedIn ?? false) &&
        settings.googleCalendarId != null;
    return hasCalDAV || hasGoogle;
  }

  // REMAINING INITIAL DIALOGS (Timezone + Calendar)
  // =============================

  /// Show remaining initial dialogs when server setup is skipped/completed
  static Future<void> _checkRemainingInitialDialogsStatic(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    // 1. Timezone dialog - show if flag is true
    if (settings.initialTzChoice) {
      if (!context.mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) return;

      logger.debug('Showing timezone confirmation dialog');
      final shouldNavigate = await _showTimezoneDialogStatic(context, settings);
      if (shouldNavigate) {
        // User wants to change timezone - navigate to Settings
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SettingsScreen(initialTabIndex: 0),
            ),
          );
        }
        return;
      }
      // If user skipped or cancelled, continue to calendar dialog
    }

    // 2. Calendar dialog - only if server is configured
    if (settings.initialCalChoice && _isServerConfigured(settings)) {
      if (!context.mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) return;

      logger.debug('Showing calendar verification dialog');
      final shouldNavigate = await _showCalendarDialogStatic(context, settings);
      if (shouldNavigate) {
        // User wants to choose calendar - navigate to Settings
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SettingsScreen(initialTabIndex: 3),
            ),
          );
        }
      }
    }
  }

  // Show remaining dialogs when leaving Server tab
  Future<void> _showRemainingInitialDialogs(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    // 1. Timezone dialog
    if (settings.initialTzChoice) {
      if (!context.mounted) return;
      final shouldNavigate = await _showTimezoneDialog(context, settings);
      if (shouldNavigate) return; // User is changing timezone, stop chain
      // If skipped, continue to calendar dialog
    }

    // 2. Calendar dialog
    if (settings.initialCalChoice && _isProviderLoggedIn(settings)) {
      if (!context.mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) return;
      await _showCalendarDialog(context, settings);
    }
  }

  // SETTINGS SCREEN - POP HANDLING
  // =============================

  bool shouldBlockPop(SettingsProvider settings) {
    return settings.inTimezoneChangeFlow &&
        tabController.index == 0 &&
        !_hasShownVerificationDialog;
  }

  Future<void> handlePopAttempt(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    if (!shouldBlockPop(settings)) return;

    logger.debug('Showing calendar verification dialog');

    _hasShownVerificationDialog = true;
    await settings.setTimezoneChangeFlow(false);

    final shouldShow =
        settings.initialCalChoice && _isProviderLoggedIn(settings);

    if (!shouldShow) {
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    if (!context.mounted) return;

    final shouldNavigate = await _showCalendarDialog(context, settings);

    if (!context.mounted) return;

    // If user didn't navigate to Server tab, allow closing
    if (!shouldNavigate && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  // SETTINGS SCREEN - TAB CHANGE HANDLING
  // =============================

  void _onTabChanged() async {
    logger.debug('=== _onTabChanged FIRED ===');
    logger.debug('Current index: ${tabController.index}');
    logger.debug('Previous index: ${tabController.previousIndex}');

    final context = getContext();
    if (!context.mounted) {
      logger.debug('Context not mounted, returning');
      return;
    }

    final settings = context.read<SettingsProvider>();
    logger.debug('inTimezoneChangeFlow: ${settings.inTimezoneChangeFlow}');
    logger.debug('inInitialSetupFlow: ${settings.inInitialSetupFlow}');
    logger.debug('initialTzChoice: ${settings.initialTzChoice}');
    logger.debug('initialCalChoice: ${settings.initialCalChoice}');

    // Leaving General tab during timezone change flow
    if (settings.inTimezoneChangeFlow &&
        tabController.previousIndex == 0 &&
        tabController.index != 0 &&
        !_hasShownVerificationDialog) {
      logger.debug(
        '>>> Triggered: Leaving General tab during timezone change flow',
      );
      // Wait for tab animation to complete
      await Future.delayed(const Duration(milliseconds: 300));

      _hasShownVerificationDialog = true;
      await settings.setTimezoneChangeFlow(false);

      final shouldShow =
          settings.initialCalChoice && _isProviderLoggedIn(settings);

      if (!shouldShow) {
        logger.debug('Not showing calendar dialog - conditions not met');
        return;
      }

      final currentContext = getContext();
      if (!currentContext.mounted) return;

      logger.debug('Showing calendar dialog after leaving General tab');
      await _showCalendarDialog(currentContext, settings);
    }

    // Leaving Server tab during initial setup flow
    if (settings.inInitialSetupFlow &&
        tabController.previousIndex == 3 &&
        tabController.index != 3) {
      logger.debug(
        '>>> Triggered: Leaving Server tab during initial setup flow',
      );
      await settings.setInitialSetupFlow(false);
      await Future.delayed(const Duration(milliseconds: 200));

      final currentContext = getContext();
      if (!currentContext.mounted) return;

      logger.debug('Calling _showRemainingInitialDialogs');
      await _showRemainingInitialDialogs(currentContext, settings);
    }

    logger.debug('=== _onTabChanged END ===');
  }

  // SERVER SETUP SAVE - TIMEZONE & CALENDAR
  // =============================

  Future<void> handleServerSetupSave({
    required BuildContext context,
    required String url,
    required String username,
    required String password,
    required String calendarName,
  }) async {
    final settings = context.read<SettingsProvider>();
    final diaryProvider = context.read<DiaryProvider>();

    // Save CalDAV settings
    settings.setCaldavSettings(url, username, password, calendarName);

    diaryProvider.configureCalDAV(
      url: url,
      username: username,
      password: password,
      calendarName: calendarName,
      eventDurationMinutes: settings.eventDurationMinutes,
    );

    await settings.disableInitialServerSetup();

    // Check if we should show timezone dialog
    if (!settings.initialTzChoice) {
      // Timezone flag disabled, go straight to calendar
      await _checkAndShowCalendarChoice(context, settings);
      return;
    }

    // Show timezone dialog
    final shouldNavigate = await _showTimezoneDialog(context, settings);

    if (shouldNavigate) {
      // User wants to change timezone, don't continue chain
      return;
    }

    // User skipped or cancelled timezone dialog, continue to calendar
    await _checkAndShowCalendarChoice(context, settings);
  }

  Future<void> _checkAndShowCalendarChoice(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    if (!settings.initialCalChoice || !_isProviderLoggedIn(settings)) {
      return;
    }

    if (!context.mounted) return;

    await Future.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) return;

    await _showCalendarDialog(context, settings);
  }

  // DIALOG HELPERS
  // =============================

  /// Show timezone dialog
  Future<bool> _showTimezoneDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    if (!context.mounted) return false;

    final action = await TimezoneConfirmationDialog.show(context);

    switch (action) {
      case TimezoneAction.cancel:
        await settings.disableInitialTzChoice();
        return false;

      case TimezoneAction.change:
        await settings.disableInitialTzChoice();
        await settings.setTimezoneChangeFlow(true);
        tabController.animateTo(0);
        return true;

      case TimezoneAction.skip:
      case null:
        return false;
    }
  }

  // Show timezone dialog
  static Future<bool> _showTimezoneDialogStatic(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    if (!context.mounted) return false;

    final action = await TimezoneConfirmationDialog.show(context);

    switch (action) {
      case TimezoneAction.cancel:
        await settings.disableInitialTzChoice();
        return false;

      case TimezoneAction.change:
        await settings.disableInitialTzChoice();
        return true;

      case TimezoneAction.skip:
      case null:
        return false;
    }
  }

  // Show calendar dialog (instance version)
  Future<bool> _showCalendarDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    if (!context.mounted) return false;

    final action = await CalendarVerificationDialog.show(context);

    switch (action) {
      case CalendarVerificationAction.cancel:
        await settings.disableInitialCalChoice();
        return false;

      case CalendarVerificationAction.skip:
        return false;

      case CalendarVerificationAction.choose:
        await settings.disableInitialCalChoice();
        tabController.animateTo(3);
        return true;

      case null:
        return false;
    }
  }

  // Show calendar dialog (static version)
  static Future<bool> _showCalendarDialogStatic(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    if (!context.mounted) return false;

    final action = await CalendarVerificationDialog.show(context);

    switch (action) {
      case CalendarVerificationAction.cancel:
        await settings.disableInitialCalChoice();
        return false;

      case CalendarVerificationAction.skip:
        return false;

      case CalendarVerificationAction.choose:
        await settings.disableInitialCalChoice();
        return true;

      case null:
        return false;
    }
  }

  // UTILITY METHODS
  // =============================

  bool _isProviderLoggedIn(SettingsProvider settings) {
    final provider = settings.calendarProvider;

    switch (provider) {
      case CalendarProvider.caldav:
      case CalendarProvider.apple:
        return settings.caldavUrl != null &&
            settings.caldavUrl!.isNotEmpty &&
            settings.caldavUsername != null &&
            settings.caldavUsername!.isNotEmpty;

      case CalendarProvider.google:
        return settings.googleCalendarId != null &&
            settings.googleCalendarId!.isNotEmpty &&
            settings.googleUserEmail != null &&
            settings.googleUserEmail!.isNotEmpty;
    }
  }

  static bool _isServerConfigured(SettingsProvider settings) {
    final hasCalDAV =
        settings.caldavUrl != null && settings.caldavUrl!.isNotEmpty;
    final hasGoogle =
        settings.calendarProvider == CalendarProvider.google &&
        settings.googleCalendarId != null;
    return hasCalDAV || hasGoogle;
  }
}
