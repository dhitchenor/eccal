import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../providers/diary_provider.dart';
import '../services/apple_calendar_service.dart';
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
  final bool isAppleMode; // for Apple iCloud setup
  final Future<void> Function({
    required BuildContext context,
    required String url,
    required String username,
    required String password,
    required String calendarName,
  })?
  onServerSetupSave; // Callback for server setup save flow

  const CalDAVServerForm({
    Key? key,
    required this.urlController,
    required this.usernameController,
    required this.passwordController,
    required this.calendarNameController,
    required this.syncDisabled,
    this.onSignInSuccess, // Optional callback
    this.isAppleMode = false, // Default to regular CalDAV
    this.onServerSetupSave, // Optional
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
        // Server URL field (hidden for Apple, shown for CalDAV)
        if (!widget.isAppleMode)
          TextField(
            controller: widget.urlController,
            enabled: !widget.syncDisabled,
            decoration: InputDecoration(
              labelText: 'server_settings.server_url'.tr(),
              hintText: 'https://cloud.example.com/remote.php/dav',
              border: OutlineInputBorder(),
            ),
          ),
        if (!widget.isAppleMode) const SizedBox(height: 16),

        // Username field
        TextField(
          controller: widget.usernameController,
          enabled: !widget.syncDisabled,
          decoration: InputDecoration(
            labelText: widget.isAppleMode
                ? 'server_settings.apple_id'.tr()
                : 'username'.tr(),
            hintText: widget.isAppleMode ? 'user@icloud.com' : null,
            border: OutlineInputBorder(),
          ),
          keyboardType: widget.isAppleMode
              ? TextInputType.emailAddress
              : TextInputType.text,
        ),
        const SizedBox(height: 16),

        // Password field
        TextField(
          controller: widget.passwordController,
          enabled: !widget.syncDisabled,
          decoration: InputDecoration(
            labelText: widget.isAppleMode
                ? 'server_settings.apple_password'.tr()
                : 'password'.tr(),
            hintText: widget.isAppleMode ? 'xxxx-xxxx-xxxx-xxxx' : null,
            helper: widget.isAppleMode
                ? RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: '${'server_settings.generate_at'.tr()} ',
                        ),
                        TextSpan(
                          text: 'account.apple.com',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final uri = Uri.parse(
                                'https://account.apple.com',
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                        ),
                        TextSpan(
                          text:
                              ' → ${'server_settings.signin_security'.tr()} → ${'server_settings.apple_password'.tr()}',
                        ),
                      ],
                    ),
                  )
                : null,
            helperMaxLines: 3,
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),

        // Buttons
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

                      Map<String, dynamic> result;

                      if (widget.isAppleMode) {
                        // Use Apple Calendar service for iCloud
                        final appleService = AppleCalendarService(
                          username: widget.usernameController.text,
                          password: widget.passwordController.text,
                        );

                        // Test connection
                        result = await appleService.testConnection();

                        if (result['success']) {
                          // Discover calendar home URL
                          final calendarHomeUrl = await appleService
                              .discoverCalendarHomeUrl();

                          if (calendarHomeUrl != null) {
                            // Save the discovered URL
                            widget.urlController.text = calendarHomeUrl;
                            result = {
                              'success': true,
                              'message': 'Connected to iCloud successfully!',
                            };
                          } else {
                            result = {
                              'success': false,
                              'step': 'discovery',
                              'error':
                                  'Failed to discover calendar URL. Check credentials.',
                            };
                          }
                        }
                      } else {
                        // Use regular CalDAV service
                        final caldavService = CalDAVService(
                          url: widget.urlController.text,
                          username: widget.usernameController.text,
                          password: widget.passwordController.text,
                        );

                        result = await caldavService.setupCalendar(
                          widget.calendarNameController.text,
                        );
                      }

                      if (!context.mounted) return;
                      Navigator.pop(context); // Close loading

                      // Show result
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            result['success'] ? 'success'.tr() : 'error'.tr(),
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

                                  // Call the setup handler callback if provided
                                  if (widget.onServerSetupSave != null) {
                                    await widget.onServerSetupSave!(
                                      context: context,
                                      url: widget.urlController.text,
                                      username: widget.usernameController.text,
                                      password: widget.passwordController.text,
                                      calendarName:
                                          widget.calendarNameController.text,
                                    );
                                  }

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
                  : () async {
                      if (widget.isAppleMode) {
                        // For Apple, we need to discover the URL first
                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        final appleService = AppleCalendarService(
                          username: widget.usernameController.text,
                          password: widget.passwordController.text,
                        );

                        final calendarHomeUrl = await appleService
                            .discoverCalendarHomeUrl();

                        if (!context.mounted) return;
                        Navigator.pop(context); // Close loading

                        if (calendarHomeUrl == null) {
                          ErrorSnackbar.showError(
                            context,
                            'Failed to discover iCloud calendar URL',
                          );
                          return;
                        }

                        widget.urlController.text = calendarHomeUrl;
                      }

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
