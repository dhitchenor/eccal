import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';

/// Actions user can take from server setup dialog
enum ServerSetupAction {
  cancel, // disable flag permanently - stop showing this dialog
  skip, // skip - keep showing this dialog
  setup, // Go to server settings tab
}

// Dialog shown on first app launch to prompt CalDAV setup
class CaldavSetupDialog extends StatelessWidget {
  const CaldavSetupDialog({super.key});

  static Future<ServerSetupAction?> show(BuildContext context) async {
    return showDialog<ServerSetupAction>(
      context: context,
      barrierDismissible: false,
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
            Navigator.pop(context, ServerSetupAction.cancel);
          },
          child: Text('setup.donotshow'.tr()),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, ServerSetupAction.skip);
          },
          child: Text('skip'.tr()),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, ServerSetupAction.setup);
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
