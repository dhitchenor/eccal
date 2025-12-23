import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/settings_screen.dart';
import '../../utils/app_localizations.dart';

class CaldavSetupDialog extends StatelessWidget {
  const CaldavSetupDialog({Key? key}) : super(key: key);

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
            context.read<SettingsProvider>().disableCaldavSetupPrompt();
            Navigator.pop(context);
          },
          child: Text('setup.donotshow'.tr()),
        ),
        TextButton(
          onPressed: () {
            // Do nothing, just close prompt
            Navigator.pop(context);
          },
          child: Text('setup.not_now'.tr()),
        ),
        ElevatedButton(
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
          child: Text('setup.caldav'.tr()),
        ),
      ],
    );
  }
}