import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/settings_screen.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_localizations.dart';

/// Dialog shown on first app launch to prompt CalDAV setup
class CaldavSetupDialog extends StatelessWidget {
  const CaldavSetupDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CaldavSetupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('setup.caldavnotice.title'.tr()),
      content: Text(
        '${'setup.caldavnotice.question'.tr()}\n\n${'setup.caldavnotice.explanation'.tr()}',
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Don't show again
            context.read<SettingsProvider>().disableInitialSetupPrompt();
            Navigator.pop(context);
          },
          child: Text('setup.donotshow'.tr()),
        ),
        TextButton(
          onPressed: () {
            // Do nothing, just close prompt
            Navigator.pop(context);
          },
          child: Text('skip'.tr()),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to settings screen, Server tab (index 3)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(initialTabIndex: 3),
              ),
            );
          },
          icon: const Icon(Icons.calendar_month_rounded),
          label: Text('setup.caldav'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
