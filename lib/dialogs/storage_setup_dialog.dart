import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';

class StorageSetupDialog extends StatelessWidget {
  const StorageSetupDialog({Key? key}) : super(key: key);

  static Future<StorageSetupAction?> show(BuildContext context) {
    return showDialog<StorageSetupAction>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (context) => const StorageSetupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.folder_open, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text('setup.storage_title'.tr())),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'setup.storage_description'.tr(),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'setup.storage_info_title'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'setup.storage_info_description'.tr(),
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'setup.storage_optional_note'.tr(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(StorageSetupAction.dontShowAgain),
          child: Text('setup.donotshow'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(StorageSetupAction.notNow),
          child: Text('setup.not_now'.tr()),
        ),
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(StorageSetupAction.chooseLocation),
          icon: const Icon(Icons.folder_open_rounded),
          label: Text('setup.choose_location'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// Action enum for storage setup dialog
enum StorageSetupAction {
  dontShowAgain, // Don't show again, use hidden storage
  notNow, // Skip for now, show again next launch
  chooseLocation, // Choose accessible location via SAF
}

/// Dialog shown when user selects Downloads folder which is not allowed
class DownloadsWarningDialog {
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(child: Text('setup.storage_downloads_blocked_title'.tr())),
          ],
        ),
        content: Text('setup.storage_downloads_blocked'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('setup.storage_try_again'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog shown when user changes storage location with existing entries
class MoveEntriesDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String newLocation,
    required int entryCount,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('local_settings.change_storage_question'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('local_settings.moveentries_to'.tr()),
            const SizedBox(height: 8),
            Text(
              newLocation,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'All $entryCount ${entryCount == 1 ? 'entry' : 'entries'} will be copied to the new location.',
              style: const TextStyle(fontSize: 14),
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
            child: Text('local_settings.move_entries'.tr()),
          ),
        ],
      ),
    );
  }
}
