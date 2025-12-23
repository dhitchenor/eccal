import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../providers/settings_provider.dart';
import '../../providers/diary_provider.dart';
import '../../services/google_calendar_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/time_helper.dart';
import '../../dialogs/caldav_server_form.dart';

class ServerTab extends StatefulWidget {
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
  State<ServerTab> createState() => _ServerTabState();
}

class _ServerTabState extends State<ServerTab> {
  CalendarProvider _selectedProvider = CalendarProvider.caldav;
  final GoogleCalendarService _googleService = GoogleCalendarService();
  bool _isGoogleInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = context.read<SettingsProvider>();
    setState(() {
      _selectedProvider = settings.calendarProvider;
    });

    // Initialize Google Calendar service if needed
    if (_selectedProvider == CalendarProvider.google) {
      // Get platform-specific client ID
      String? clientId;
      String? clientSecret;

      if (Platform.isAndroid) {
        clientId = AppConfig.googleCalendarClientID_Android;
      } else if (Platform.isIOS) {
        clientId = AppConfig.googleCalendarClientID_iOS;
      } else {
        clientId = AppConfig.googleCalendarClientID_Desktop;
        clientSecret = AppConfig.googleCalendarClientSecret_Desktop;
      }

      await _googleService.initialize(
        clientId: clientId,
        clientSecret: clientSecret ?? '', // Desktop needs this
      );
      setState(() {
        _isGoogleInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final syncDisabled = settings.caldavSyncDisabled;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),

        // CalDAV Server Section with Provider dropdown
        Row(
          children: [
            Text(
              'server_settings.caldav_server'.tr(['CalDAV']),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            DropdownButton<CalendarProvider>(
              value: _selectedProvider,
              items: [
                DropdownMenuItem(
                  value: CalendarProvider.caldav,
                  child: Text('CalDAV Calendar'),
                ),
                DropdownMenuItem(
                  value: CalendarProvider.google,
                  child: Text('Google Calendar'),
                ),
                DropdownMenuItem(
                  value: CalendarProvider.apple,
                  child: Text('Apple Calendar'),
                ),
              ],
              onChanged: (value) async {
                if (value != null) {
                  setState(() {
                    _selectedProvider = value;
                  });

                  // Save to settings
                  final settings = context.read<SettingsProvider>();
                  await settings.setCalendarProvider(value);

                  // Initialize Google service if switching to Google
                  if (value == CalendarProvider.google &&
                      !_isGoogleInitialized) {
                    String? clientId;
                    String? clientSecret;

                    if (Platform.isAndroid) {
                      clientId = AppConfig.googleCalendarClientID_Android;
                    } else if (Platform.isIOS) {
                      clientId = AppConfig.googleCalendarClientID_iOS;
                    } else {
                      clientId = AppConfig.googleCalendarClientID_Desktop;
                      clientSecret =
                          AppConfig.googleCalendarClientSecret_Desktop;
                    }

                    await _googleService.initialize(
                      clientId: clientId,
                      clientSecret: clientSecret ?? '', // Desktop needs this
                    );
                    setState(() {
                      _isGoogleInitialized = true;
                    });
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Disable Sync checkbox underneath title
        Row(
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
        const SizedBox(height: 16),

        // Conditional UI based on selected provider
        if (_selectedProvider == CalendarProvider.caldav) ...[
          CalDAVServerForm(
            urlController: widget.urlController,
            usernameController: widget.usernameController,
            passwordController: widget.passwordController,
            calendarNameController: widget.calendarNameController,
            syncDisabled: syncDisabled,
          ),
        ] else if (_selectedProvider == CalendarProvider.google) ...[
          _buildGoogleSignIn(context, syncDisabled),
        ] else if (_selectedProvider == CalendarProvider.apple) ...[
          _buildAppleSignIn(context, syncDisabled),
        ],

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
                        DropdownMenuItem(
                          value: 0,
                          child: Text('server_settings.disabled'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text(formatDuration(5, 'min')),
                        ),
                        DropdownMenuItem(
                          value: 15,
                          child: Text(formatDuration(15, 'min')),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text(formatDuration(30, 'min')),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text(formatDuration(1, 'hr')),
                        ),
                        DropdownMenuItem(
                          value: 120,
                          child: Text(formatDuration(2, 'hr')),
                        ),
                        DropdownMenuItem(
                          value: 240,
                          child: Text(formatDuration(4, 'hr')),
                        ),
                      ],
                      onChanged: syncDisabled
                          ? null
                          : (value) {
                              if (value != null) {
                                settings.setServerPollInterval(value);

                                // Restart polling in DiaryProvider
                                final diaryProvider = context
                                    .read<DiaryProvider>();
                                diaryProvider.startServerPolling();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      value == 0
                                          ? 'server_settings.background_sync_disabled'
                                                .tr()
                                          : 'server_settings.checking_server_every'
                                                .tr([value.toString()]),
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

  Widget _buildGoogleSignIn(BuildContext context, bool syncDisabled) {
    if (!_isGoogleInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSignedIn = _googleService.isSignedIn;

    if (isSignedIn) {
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text('Signed in as ${_googleService.userEmail}'),
            trailing: TextButton(
              onPressed: () async {
                await _googleService.signOut();
                final settings = context.read<SettingsProvider>();
                await settings.setGoogleCalendar(
                  calendarId: null,
                  userEmail: null,
                );
                await settings.setCalendarProvider(CalendarProvider.caldav);
                setState(() {
                  _selectedProvider = CalendarProvider.caldav;
                });
              },
              child: const Text('Sign Out'),
            ),
          ),
          const SizedBox(height: 16),
          // Calendar selection dropdown
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _googleService.listCalendars(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No calendars found');
              }

              final calendars = snapshot.data!;
              final settings = context.watch<SettingsProvider>();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Calendar:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select a calendar'),
                    value: settings.googleCalendarId,
                    items: calendars.map((cal) {
                      return DropdownMenuItem<String>(
                        value: cal['id'] as String,
                        child: Text(cal['summary'] as String),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        await _googleService.setCalendarId(value);
                        await settings.setGoogleCalendar(
                          calendarId: value,
                          userEmail: _googleService.userEmail,
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      );
    }

    return Center(
      child: ElevatedButton.icon(
        onPressed: syncDisabled
            ? null
            : () async {
                final success = await _googleService.signIn();
                if (success) {
                  final settings = context.read<SettingsProvider>();

                  // Get primary calendar
                  final calendarId = await _googleService
                      .getPrimaryCalendarId();
                  await _googleService.setCalendarId(calendarId);

                  await settings.setGoogleCalendar(
                    calendarId: calendarId,
                    userEmail: _googleService.userEmail,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Signed in as ${_googleService.userEmail}',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {});
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sign-in cancelled or failed'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
        icon: const Icon(Icons.g_mobiledata_rounded),
        label: const Text('Sign in with Google'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildAppleSignIn(BuildContext context, bool syncDisabled) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: syncDisabled
            ? null
            : () {
                // TODO: Implement Apple sign-in
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Apple Calendar sign-in coming soon'),
                  ),
                );
              },
        icon: const Icon(Icons.apple),
        label: const Text('Sign in with Apple'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
