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
import '../utils/saf_helper.dart';

// Manages all initial setup dialogs and navigation flows
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

  /// Check and show storage setup dialog (Android only)
  static Future<void> checkAndShowStorageSetup({
    required BuildContext context,
    required DiaryProvider diaryProvider,
  }) async {
    if (!Platform.isAndroid) return;

    final fileStorage = FileStorageService();
    if (!await fileStorage.shouldShowStorageSetupDialog()) return;
    if (!context.mounted) return;

    final action = await StorageSetupDialog.show(context);

    switch (action) {
      case StorageSetupAction.cancel:
        await fileStorage.markStorageSetupDialogShown();
      case StorageSetupAction.choose:
        await fileStorage.markStorageSetupDialogShown();
        if (context.mounted) {
          await SafHelper.openStoragePicker(context, diaryProvider);
        }
      case StorageSetupAction.skip:
      case null:
        break;
    }
  }

  // SERVER SETUP
  // =============================

  static Future<void> checkAndShowInitialServerSetup({
    required BuildContext context,
    required SettingsProvider settingsProvider,
    GoogleCalendarService? googleCalendarService,
  }) async {
    // Skip if flag disabled or server already configured
    if (!settingsProvider.initialServerSetup) {
      await _showRemainingDialogsStatic(context, settingsProvider);
      return;
    }

    if (_isServerConfigured(settingsProvider, googleCalendarService)) {
      await settingsProvider.disableInitialServerSetup();
      await _showRemainingDialogsStatic(context, settingsProvider);
      return;
    }

    // Show server setup dialog
    if (!context.mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;

    await settingsProvider.setInitialSetupFlow(true);
    final action = await CaldavSetupDialog.show(context);
    if (!context.mounted) return;

    // Handle user's choice
    switch (action) {
      case ServerSetupAction.cancel:
        await settingsProvider.disableInitialServerSetup();
        await settingsProvider.setInitialSetupFlow(false);
        await _showRemainingDialogsStatic(context, settingsProvider);

      case ServerSetupAction.skip:
        await settingsProvider.setInitialSetupFlow(false);
        await _showRemainingDialogsStatic(context, settingsProvider);

      case ServerSetupAction.setup:
        // Navigate to Settings - flow stays active until tab change
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SettingsScreen(initialTabIndex: 3),
          ),
        );

      case null:
        await settingsProvider.setInitialSetupFlow(false);
    }
  }

  /// Show remaining dialogs (timezone & calendar) from home screen
  static Future<void> _showRemainingDialogsStatic(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    // Timezone dialog
    if (settings.initialTzChoice) {
      if (!await _waitAndCheckContext(context, 300)) return;

      final action = await TimezoneConfirmationDialog.show(context);

      switch (action) {
        case TimezoneAction.cancel:
          await settings.disableInitialTzChoice();
        case TimezoneAction.change:
          await settings.disableInitialTzChoice();
          // Navigate to Settings General tab
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(initialTabIndex: 0),
              ),
            );
          }
          return; // Don't continue to calendar
        case TimezoneAction.skip:
        case null:
          break;
      }
    }

    // 2. Calendar dialog (only if server is configured)
    if (settings.initialCalChoice && _isServerConfigured(settings)) {
      if (!await _waitAndCheckContext(context, 300)) return;

      final action = await CalendarVerificationDialog.show(context);

      switch (action) {
        case CalendarVerificationAction.cancel:
          await settings.disableInitialCalChoice();
        case CalendarVerificationAction.choose:
          await settings.disableInitialCalChoice();
          // Navigate to Settings Server tab
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(initialTabIndex: 3),
              ),
            );
          }
        case CalendarVerificationAction.skip:
        case null:
          break;
      }
    }
  }

  void _onTabChanged() async {
    final context = getContext();
    if (!context.mounted) return;

    final settings = context.read<SettingsProvider>();
    final prevIdx = tabController.previousIndex;
    final currIdx = tabController.index;

    // Leaving General tab after timezone change
    if (settings.inTimezoneChangeFlow &&
        prevIdx == 0 &&
        currIdx != 0 &&
        !_hasShownVerificationDialog) {
      _hasShownVerificationDialog = true;
      await settings.setTimezoneChangeFlow(false);

      // Show calendar dialog if flag enabled and logged in
      if (settings.initialCalChoice && _isProviderLoggedIn(settings)) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!context.mounted) return;
        await _showCalendarDialog(context, settings);
      }
    }

    // Leaving Server tab during initial setup
    if (settings.inInitialSetupFlow && prevIdx == 3 && currIdx != 3) {
      await settings.setInitialSetupFlow(false);
      await Future.delayed(const Duration(milliseconds: 200));
      if (!context.mounted) return;

      await _showRemainingDialogsInSettings(context, settings);
    }
  }

  // SETTINGS SCREEN
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

    _hasShownVerificationDialog = true;
    await settings.setTimezoneChangeFlow(false);

    // Show calendar dialog if conditions met
    if (settings.initialCalChoice && _isProviderLoggedIn(settings)) {
      if (!context.mounted) return;
      final shouldNavigate = await _showCalendarDialog(context, settings);
      if (!shouldNavigate && context.mounted) {
        Navigator.of(context).pop();
      }
    } else if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  // SERVER SETUP SAVE FLOW
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

    // Show timezone dialog if enabled
    if (settings.initialTzChoice) {
      final action = await TimezoneConfirmationDialog.show(context);

      switch (action) {
        case TimezoneAction.cancel:
          await settings.disableInitialTzChoice();
        case TimezoneAction.change:
          await settings.disableInitialTzChoice();
          await settings.setTimezoneChangeFlow(true);
          tabController.animateTo(0);
          return; // Calendar dialog will show when leaving General tab
        case TimezoneAction.skip:
        case null:
          break;
      }
    }

    // Show calendar dialog
    await _showCalendarDialogIfNeeded(context, settings);
  }

  // DIALOG HELPERS
  // =============================

  // Show remaining dialogs when leaving Server tab in Settings
  Future<void> _showRemainingDialogsInSettings(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    // Timezone dialog
    if (settings.initialTzChoice) {
      if (!context.mounted) return;

      final action = await TimezoneConfirmationDialog.show(context);

      switch (action) {
        case TimezoneAction.cancel:
          await settings.disableInitialTzChoice();
        case TimezoneAction.change:
          await settings.disableInitialTzChoice();
          await settings.setTimezoneChangeFlow(true);
          tabController.animateTo(0);
          return; // Calendar dialog will show when leaving General tab
        case TimezoneAction.skip:
        case null:
          break;
      }
    }

    // Calendar dialog - skip if timezone change flow active
    if (settings.inTimezoneChangeFlow) return;

    await _showCalendarDialogIfNeeded(context, settings);
  }

  // Show calendar dialog if conditions are met
  Future<void> _showCalendarDialogIfNeeded(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    if (!settings.initialCalChoice || !_isProviderLoggedIn(settings)) return;
    if (!await _waitAndCheckContext(context, 300)) return;

    await _showCalendarDialog(context, settings);
  }

  // Show calendar dialog and return whether user wants to navigate
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
      case CalendarVerificationAction.choose:
        await settings.disableInitialCalChoice();
        tabController.animateTo(3);
        return true;
      case CalendarVerificationAction.skip:
      case null:
        return false;
    }
  }

  // Wait for delay and check if context is still mounted
  static Future<bool> _waitAndCheckContext(
    BuildContext context,
    int milliseconds,
  ) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
    return context.mounted;
  }

  // Check if user is logged into any calendar provider
  bool _isProviderLoggedIn(SettingsProvider settings) {
    return switch (settings.calendarProvider) {
      CalendarProvider.caldav || CalendarProvider.apple =>
        settings.caldavUrl?.isNotEmpty == true &&
            settings.caldavUsername?.isNotEmpty == true,
      CalendarProvider.google =>
        settings.googleCalendarId?.isNotEmpty == true &&
            settings.googleUserEmail?.isNotEmpty == true,
    };
  }

  // Check if server is configured (static version for initialization)
  static bool _isServerConfigured(
    SettingsProvider settings, [
    GoogleCalendarService? googleService,
  ]) {
    final hasCalDAV = settings.caldavUrl?.isNotEmpty == true;
    final hasGoogle =
        settings.calendarProvider == CalendarProvider.google &&
        (googleService?.isSignedIn ?? false) &&
        settings.googleCalendarId != null;
    return hasCalDAV || hasGoogle;
  }
}
