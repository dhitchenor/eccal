import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/settings_screen.dart';
import '../../providers/settings_provider.dart';
import '../../providers/diary_provider.dart';
import '../../utils/app_localizations.dart';
import '../../utils/error_snackbar.dart';

/// Actions user can take from timezone confirmation dialog
enum TimezoneAction {
  cancel, // Stay on server settings tab
  change, // Go to general tab to change timezone
  done, // Go to home screen and refresh
}

/// Dialog shown after saving CalDAV settings to confirm timezone
class TimezoneConfirmationDialog extends StatelessWidget {
  const TimezoneConfirmationDialog({super.key});

  /// Show timezone confirmation dialog
  static Future<TimezoneAction?> show(BuildContext context) async {
    return showDialog<TimezoneAction>(
      context: context,
      barrierDismissible: false, // Must choose an option
      builder: (context) => const TimezoneConfirmationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final currentTimezone = settings.timezone;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.public, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text('setup.timezone_confirmation'.tr())),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('setup.current_timezone_is'.tr()),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentTimezone,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'setup.timezone_question'.tr(),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, TimezoneAction.cancel);
          },
          child: Text('cancel'.tr()),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context, TimezoneAction.change);
          },
          icon: const Icon(Icons.edit),
          label: Text('setup.change_timezone'.tr()),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, TimezoneAction.done);
          },
          icon: const Icon(Icons.check),
          label: Text('done'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Handle server setup save with timezone confirmation
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

  // Reconfigure CalDAV in DiaryProvider
  diaryProvider.configureCalDAV(
    url: url,
    username: username,
    password: password,
    calendarName: calendarName,
    eventDurationMinutes: settings.eventDurationMinutes,
  );

  // Don't show timezone confirmation if setup prompts are disabled
  if (!settings.showInitialSetupPrompt) {
    return;
  }

  final navigator = Navigator.of(context);

  // Show timezone confirmation dialog
  final action = await TimezoneConfirmationDialog.show(context);

  // Disable the prompt - setup is complete
  await settings.disableInitialSetupPrompt();

  if (!context.mounted) return;

  switch (action) {
    case TimezoneAction.cancel:
      // Stay on server settings tab - do nothing
      break;

    case TimezoneAction.change:
      // Replace current settings screen with General tab
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(initialTabIndex: 0),
        ),
      );
      break;

    case TimezoneAction.done:
      // Sync with server, then go to home

      // Pop then wait briefly for navigation
      navigator.pop();
      await Future.delayed(const Duration(milliseconds: 100));

      if (!context.mounted) return;

      try {
        // Sync with server
        await diaryProvider.syncWithCalDAV();

        // Show success
        ErrorSnackbar.showSuccess(
          context,
          'server_settings.settings_saved_synced'.tr(),
          duration: const Duration(seconds: 3),
        );
      } catch (error) {
        // Show error
        ErrorSnackbar.showWarning(
          context,
          'server_settings.settings_saved_sync_failed'.tr([
            error.toString(),
          ]),
          duration: const Duration(seconds: 4),
        );
      }
      break;

    case null:
      // Dialog dismissed somehow - do nothing
      break;
  }
}
