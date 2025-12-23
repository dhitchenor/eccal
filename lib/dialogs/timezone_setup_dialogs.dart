import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_localizations.dart';

// Actions user can take from timezone confirmation dialog
enum TimezoneAction {
  cancel, // disable flag permanently - stop showing this dialog
  skip, // skip - keep showing this dialog
  change, // Go to general tab to change timezone
}

// Dialog shown after saving CalDAV settings to confirm timezone
class TimezoneConfirmationDialog extends StatelessWidget {
  const TimezoneConfirmationDialog({super.key});

  // Show timezone confirmation dialog
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
          child: Text('setup.donotshow'.tr()),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, TimezoneAction.skip);
          },
          child: Text('skip'.tr()),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, TimezoneAction.change);
          },
          icon: const Icon(Icons.edit),
          label: Text('setup.change_timezone'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
