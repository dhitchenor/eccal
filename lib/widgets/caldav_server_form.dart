import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dialogs/timezone_setup_dialogs.dart';
import '../models/calendar_info.dart';
import '../providers/settings_provider.dart';
import '../providers/diary_provider.dart';
import '../services/caldav_service.dart';
import '../utils/app_localizations.dart';
import '../utils/error_snackbar.dart';

class CalDAVServerForm extends StatefulWidget {
  final TextEditingController urlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController calendarNameController;
  final bool syncDisabled;
  final VoidCallback? onSignInSuccess; // Callback when setup succeeds

  const CalDAVServerForm({
    Key? key,
    required this.urlController,
    required this.usernameController,
    required this.passwordController,
    required this.calendarNameController,
    required this.syncDisabled,
    this.onSignInSuccess, // Optional callback
  }) : super(key: key);

  @override
  State<CalDAVServerForm> createState() => _CalDAVServerFormState();
}

class _CalDAVServerFormState extends State<CalDAVServerForm> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.urlController,
          enabled: !widget.syncDisabled,
          decoration: InputDecoration(
            labelText: 'server_settings.server_url'.tr(),
            hintText: 'https://cloud.example.com/remote.php/dav',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.usernameController,
          enabled: !widget.syncDisabled,
          decoration: InputDecoration(
            labelText: 'username'.tr(),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.passwordController,
          enabled: !widget.syncDisabled,
          decoration: InputDecoration(
            labelText: 'password'.tr(),
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: widget.syncDisabled
                  ? null
                  : () async {
                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      // Test connection and setup calendar
                      final caldavService = CalDAVService(
                        url: widget.urlController.text,
                        username: widget.usernameController.text,
                        password: widget.passwordController.text,
                      );

                      final result = await caldavService.setupCalendar(
                        widget.calendarNameController.text,
                      );

                      if (!context.mounted) return;
                      Navigator.pop(context); // Close loading

                      // Show result
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            result['success']
                                ? 'success'.tr()
                                : 'error'.tr(),
                          ),
                          content: Text(
                            result['success']
                                ? result['message']
                                : '${'step'.tr()}: ${result['step']}\n${result['error']}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('ok'.tr()),
                            ),
                            if (result['success'])
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context); // Close result dialog

                                  // Call the setup handler which manages everything
                                  await handleServerSetupSave(
                                    context: context,
                                    url: widget.urlController.text,
                                    username: widget.usernameController.text,
                                    password: widget.passwordController.text,
                                    calendarName: widget.calendarNameController.text,
                                  );

                                  // Notify parent that sign-in succeeded
                                  if (widget.onSignInSuccess != null) {
                                    widget.onSignInSuccess!();
                                  }
                                },
                                child: Text(
                                  'server_settings.save_settings'.tr(),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
              icon: const Icon(Icons.check_circle),
              label: Text('server_settings.test_setup'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: widget.syncDisabled
                  ? null
                  : () {
                      settings.setCaldavSettings(
                        widget.urlController.text,
                        widget.usernameController.text,
                        widget.passwordController.text,
                        widget.calendarNameController.text,
                      );

                      // Reconfigure CalDAV in DiaryProvider
                      final diaryProvider = context.read<DiaryProvider>();
                      diaryProvider.configureCalDAV(
                        url: widget.urlController.text,
                        username: widget.usernameController.text,
                        password: widget.passwordController.text,
                        calendarName: widget.calendarNameController.text,
                        eventDurationMinutes: settings.eventDurationMinutes,
                      );

                      // Don't sync - connection not tested
                      ErrorSnackbar.showInfo(
                        context,
                        'server_settings.settings_saved_no_sync'.tr(),
                      );
                    },
              child: Text('server_settings.save_without_testing'.tr()),
            ),
          ],
        ),
      ],
    );
  }
}
