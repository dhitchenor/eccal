import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/diary_provider.dart';
import '../../services/caldav_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/time_helper.dart';

class ServerTab extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController calendarNameController;

  const ServerTab({
    Key? key,
    required this.urlController,
    required this.usernameController,
    required this.passwordController,
    required this.calendarNameController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final syncDisabled = settings.caldavSyncDisabled;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        
        // CalDAV Server Section with Disable Sync checkbox
        Row(
          children: [
            Text(
              'server_settings.caldav_server'.tr(['CalDAV']),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: syncDisabled,
                  onChanged: (value) {
                    if (value != null) {
                      settings.setCaldavSyncDisabled(value);
                    }
                  },
                ),
                Text('server_settings.disable_sync'.tr()),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: urlController,
          enabled: !syncDisabled,
          decoration: InputDecoration(
            labelText: 'server_settings.server_url'.tr(),
            hintText: 'https://cloud.example.com/remote.php/dav',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: usernameController,
          enabled: !syncDisabled,
          decoration: InputDecoration(
            labelText: 'server_settings.username'.tr(),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          enabled: !syncDisabled,
          decoration: InputDecoration(
            labelText: 'server_settings.password'.tr(),
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: calendarNameController,
          enabled: !syncDisabled,
          decoration: InputDecoration(
            labelText: 'server_settings.calendar_name'.tr(),
            hintText: 'server_settings.my_diary'.tr(),
            border: OutlineInputBorder(),
            helperText: 'server_settings.calendar_helper'.tr(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: syncDisabled ? null : () async {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
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
                    title: Text(result['success'] ? 'success'.tr() : 'server_settings.error'.tr()),
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
                          onPressed: () {
                            Navigator.pop(context);
                            // Save settings
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
                            
                            // Sync with server immediately after saving
                            diaryProvider.syncWithCalDAV().then((_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('server_settings.settings_saved_synced'.tr()),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }).catchError((error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('server_settings.settings_saved_sync_failed'.tr([error.toString()])),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            });
                          },
                          child: Text('server_settings.save_settings'.tr()),
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
              onPressed: syncDisabled ? null : () {
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
                    content: Text('server_settings.settings_saved_no_sync'.tr()),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: Text('server_settings.save_without_testing'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        // Server Poll Interval Section
        Text(
          'server_settings.background_sync'.tr(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'server_settings.poll_question'.tr(),
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'server_settings.check_server_every'.tr(),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: settings.serverPollIntervalMinutes,
                      items: [
                        DropdownMenuItem(value: 0, child: Text('server_settings.disabled'.tr())),
                        DropdownMenuItem(value: 5, child: Text(formatDuration(5, 'min'))),
                        DropdownMenuItem(value: 15, child: Text(formatDuration(15, 'min'))),
                        DropdownMenuItem(value: 30, child: Text(formatDuration(30, 'min'))),
                        DropdownMenuItem(value: 60, child: Text(formatDuration(1, 'hr'))),
                        DropdownMenuItem(value: 120, child: Text(formatDuration(2, 'hr'))),
                        DropdownMenuItem(value: 240, child: Text(formatDuration(4, 'hr'))),
                      ],
                      onChanged: syncDisabled ? null : (value) {
                        if (value != null) {
                          settings.setServerPollInterval(value);
                          
                          // Restart polling in DiaryProvider
                          final diaryProvider = context.read<DiaryProvider>();
                          diaryProvider.startServerPolling();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value == 0 
                                    ? 'server_settings.background_sync_disabled'.tr()
                                    : 'server_settings.checking_server_every'.tr([value.toString()]),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'server_settings.poll_explanation'.tr(),
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}