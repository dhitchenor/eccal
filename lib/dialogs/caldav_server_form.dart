import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/diary_provider.dart';
import '../services/caldav_service.dart';
import '../utils/app_localizations.dart';
import 'timezone_setup_dialogs.dart';

class CalDAVServerForm extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController calendarNameController;
  final bool syncDisabled;

  const CalDAVServerForm({
    Key? key,
    required this.urlController,
    required this.usernameController,
    required this.passwordController,
    required this.calendarNameController,
    required this.syncDisabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final fieldWidth = MediaQuery.of(context).size.width * 0.85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: fieldWidth,
          child: TextField(
            controller: urlController,
            enabled: !syncDisabled,
            decoration: InputDecoration(
              labelText: 'server_settings.server_url'.tr(),
              hintText: 'https://cloud.example.com/remote.php/dav',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: fieldWidth,
          child: TextField(
            controller: usernameController,
            enabled: !syncDisabled,
            decoration: InputDecoration(
              labelText: 'server_settings.username'.tr(),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: fieldWidth,
          child: TextField(
            controller: passwordController,
            enabled: !syncDisabled,
            decoration: InputDecoration(
              labelText: 'server_settings.password'.tr(),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: fieldWidth,
          child: TextField(
            controller: calendarNameController,
            enabled: !syncDisabled,
            decoration: InputDecoration(
              labelText: 'server_settings.calendar_name'.tr(),
              hintText: 'server_settings.my_diary'.tr(),
              border: OutlineInputBorder(),
              helperText: 'server_settings.calendar_helper'.tr(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: syncDisabled
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
                        url: urlController.text,
                        username: usernameController.text,
                        password: passwordController.text,
                      );

                      final result = await caldavService.setupCalendar(
                        calendarNameController.text,
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
                                : 'server_settings.error'.tr(),
                          ),
                          content: Text(
                            result['success']
                                ? result['message']
                                : '${'server_settings.step'.tr()}: ${result['step']}\n${result['error']}',
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
                                    url: urlController.text,
                                    username: usernameController.text,
                                    password: passwordController.text,
                                    calendarName: calendarNameController.text,
                                  );
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
              onPressed: syncDisabled
                  ? null
                  : () {
                      settings.setCaldavSettings(
                        urlController.text,
                        usernameController.text,
                        passwordController.text,
                        calendarNameController.text,
                      );

                      // Reconfigure CalDAV in DiaryProvider
                      final diaryProvider = context.read<DiaryProvider>();
                      diaryProvider.configureCalDAV(
                        url: urlController.text,
                        username: usernameController.text,
                        password: passwordController.text,
                        calendarName: calendarNameController.text,
                        eventDurationMinutes: settings.eventDurationMinutes,
                      );

                      // Don't sync - connection not tested
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'server_settings.settings_saved_no_sync'.tr(),
                          ),
                          backgroundColor: Colors.blue,
                        ),
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
