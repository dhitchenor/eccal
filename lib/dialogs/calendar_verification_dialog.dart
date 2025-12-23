import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/settings_screen.dart';
import '../providers/settings_provider.dart';
import '../utils/app_localizations.dart';

/// Actions user can take from calendar verification dialog
enum CalendarVerificationAction {
  cancel, // disable flag permanently - stop showing this dialog
  skip, // skip - keep showing this dialog
  choose, // Go to server settings tab
}

/// Dialog shown after changing timezone to verify calendar selection
class CalendarVerificationDialog extends StatelessWidget {
  const CalendarVerificationDialog({super.key});

  /// Show calendar verification dialog
  static Future<CalendarVerificationAction?> show(BuildContext context) async {
    return showDialog<CalendarVerificationAction>(
      context: context,
      barrierDismissible: false, // Must choose an option
      builder: (context) => const CalendarVerificationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text('setup.calselect.verify_calendar'.tr())),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'setup.calselect.verify_calendar_message'.tr(),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'setup.calselect.verify_calendar_hint'.tr(),
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, CalendarVerificationAction.cancel);
          },
          child: Text('setup.donotshow'.tr()),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context, CalendarVerificationAction.skip);
          },
          child: Text('skip'.tr()),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, CalendarVerificationAction.choose);
          },
          icon: const Icon(Icons.settings),
          label: Text('setup.calselect.choose_calendar'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Handle navigation away from General tab with calendar verification
Future<bool> handleGeneralTabExit({
  required BuildContext context,
  required bool fromTimezoneChange,
}) async {
  final settings = context.read<SettingsProvider>();

  // Check if we should show the dialog
  final shouldShow =
      fromTimezoneChange &&
      settings.showCalendarVerificationPrompt &&
      _isProviderLoggedIn(settings);

  if (!shouldShow) {
    return true; // Allow navigation
  }

  // Show calendar verification dialog
  final action = await CalendarVerificationDialog.show(context);

  if (!context.mounted) return false;

  switch (action) {
    case CalendarVerificationAction.cancel:
      // Disable prompt permanently
      await settings.disableCalendarVerificationPrompt();
      return true; // Allow navigation

    case CalendarVerificationAction.skip:
      // Just allow navigation (flag stays true)
      return true;

    case CalendarVerificationAction.choose:
      // Navigate to Server Settings tab
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              const SettingsScreen(initialTabIndex: 3), // Server tab is index 3
        ),
      );
      return false; // Prevent default navigation

    case null:
      // Dialog dismissed somehow - allow navigation
      return true;
  }
}

/// Check if any calendar provider is logged in
bool _isProviderLoggedIn(SettingsProvider settings) {
  final provider = settings.calendarProvider;

  switch (provider) {
    case CalendarProvider.caldav:
    case CalendarProvider.apple:
      // Check CalDAV/Apple credentials
      return settings.caldavUrl != null &&
          settings.caldavUrl!.isNotEmpty &&
          settings.caldavUsername != null &&
          settings.caldavUsername!.isNotEmpty;

    case CalendarProvider.google:
      // Check Google credentials
      return settings.googleCalendarId != null &&
          settings.googleCalendarId!.isNotEmpty &&
          settings.googleUserEmail != null &&
          settings.googleUserEmail!.isNotEmpty;
  }
}
