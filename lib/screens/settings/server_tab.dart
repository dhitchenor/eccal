import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../models/calendar_info.dart';
import '../../providers/settings_provider.dart';
import '../../providers/diary_provider.dart';
import '../../services/google_calendar_service.dart';
import '../../services/logger_service.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/calendar_provider_widget.dart';

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
  late GoogleCalendarService _googleService;
  bool _isGoogleInitialized = false;
  CalendarProvider _selectedProvider = CalendarProvider.caldav;
  CalendarProvider? _previousProvider; // Track old provider for sign-out
  String? _previousCalDAVUrl; // Track CalDAV URL to detect server changes
  String? _previousGoogleEmail; // Track Google email to detect account changes

  @override
  void initState() {
    super.initState();
    // Load current provider from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      setState(() {
        _selectedProvider = settings.calendarProvider;
        _previousProvider = settings.calendarProvider;
        _previousCalDAVUrl = settings.caldavUrl;
        _previousGoogleEmail = settings.googleUserEmail;
      });
    });
  }

  /// Sign out from the previous provider when switching
  Future<void> _signOutPreviousProvider() async {
    if (_previousProvider == null) {
      return; // No previous provider
    }

    final settings = context.read<SettingsProvider>();

    // Check if we're switching from CalDAV to the same CalDAV server
    final currentCalDAVUrl = settings.caldavUrl;
    final isSameCalDAVServer = _previousProvider == CalendarProvider.caldav &&
                                _selectedProvider == CalendarProvider.caldav &&
                                _previousCalDAVUrl == currentCalDAVUrl;

    // Check if we're switching from Google to the same Google account
    final currentGoogleEmail = settings.googleUserEmail;
    final isSameGoogleAccount = _previousProvider == CalendarProvider.google &&
                                 _selectedProvider == CalendarProvider.google &&
                                 _previousGoogleEmail == currentGoogleEmail;

    if (_previousProvider == _selectedProvider && (isSameCalDAVServer || isSameGoogleAccount)) {
      return; // Same provider and same account/server - no sign out needed
    }

    switch (_previousProvider!) {
      case CalendarProvider.google:
        if (_isGoogleInitialized) {
          await _googleService.signOut();
          logger.info('Signed out from Google Calendar');
        }
        await settings.setGoogleCalendar(calendarId: null, userEmail: null);
        await settings.clearCachedCalendarList();
        break;

      case CalendarProvider.caldav:
        await settings.clearCalDAVSettings();
        await settings.clearCachedCalendarList();
        widget.urlController.clear();
        widget.usernameController.clear();
        widget.passwordController.clear();
        widget.calendarNameController.clear();
        logger.info('Signed out from CalDAV');
        break;

      case CalendarProvider.apple:
        // TODO: Implement Apple sign out
        break;
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_isGoogleInitialized) return;

    _googleService = GoogleCalendarService();

    try {
      // Get platform-specific client ID and secret
      String clientId;
      String clientSecret = ''; // Empty for mobile (OAuth)

      if (Platform.isAndroid) {
        clientId = AppConfig.googleCalendarClientID_Android;
      } else if (Platform.isIOS) {
        clientId = AppConfig.googleCalendarClientID_iOS;
      } else {
        // Desktop (Linux, macOS, Windows)
        clientId = AppConfig.googleCalendarClientID_Desktop;
        clientSecret = AppConfig.googleCalendarClientSecret_Desktop;
      }

      await _googleService.initialize(
        clientId: clientId,
        clientSecret: clientSecret,
      );

      if (mounted) {
        setState(() {
          _isGoogleInitialized = true;
        });
      }

      logger.info('Google Calendar: Initialized successfully');
    } catch (e) {
      logger.error('Google Calendar: Failed to initialize: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final syncDisabled = settings.caldavSyncDisabled;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider selector dropdown
            Row(
              children: [
                Text(
                  'server_settings.caldav_provider'.tr(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                DropdownButton<CalendarProvider>(
                  value: _selectedProvider,
                  items: [
                    DropdownMenuItem(
                      value: CalendarProvider.caldav,
                      child: Text('caldav_calendar'.tr()),
                    ),
                    DropdownMenuItem(
                      value: CalendarProvider.google,
                      child: Text('google_calendar'.tr()),
                    ),
                    DropdownMenuItem(
                      value: CalendarProvider.apple,
                      child: Text('apple_calendar'.tr()),
                    ),
                  ],
                  onChanged: syncDisabled
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedProvider = value;
                          });
                        }
                      },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Sync disable switch
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final leftPadding = isMobile ? 16.0 : 0.0;
                final rowWidth = constraints.maxWidth * 0.8;

                return Padding(
                  padding: EdgeInsets.only(left: leftPadding),
                  child: SizedBox(
                    width: rowWidth,
                    child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'server_settings.disable_sync'.tr(),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'server_settings.disable_sync_description'.tr(),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: syncDisabled,
                        onChanged: (value) {
                          settings.setCaldavSyncDisabled(value);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
            const SizedBox(height: 20),

            // Provider-specific UI (ONE widget for all!)
            if (_selectedProvider == CalendarProvider.caldav)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final leftPadding = isMobile ? 16.0 : 0.0;
                  final formWidth = constraints.maxWidth * 0.8;

                  return Padding(
                    padding: EdgeInsets.only(left: leftPadding),
                    child: SizedBox(
                      width: formWidth,
                      child: CalendarProviderWidget(
                    provider: CalendarProvider.caldav,
                    syncDisabled: syncDisabled,
                    caldavUrlController: widget.urlController,
                    caldavUsernameController: widget.usernameController,
                    caldavPasswordController: widget.passwordController,
                    caldavCalendarNameController: widget.calendarNameController,
                    onSignInSuccess: () async {
                      // Only sign out from previous provider if we're switching providers
                      final settings = context.read<SettingsProvider>();
                      final isInitialSetup = _previousProvider == null ||
                                            (_previousProvider == CalendarProvider.caldav &&
                                             _previousCalDAVUrl == null);

                      if (!isInitialSetup) {
                        await _signOutPreviousProvider();
                      }

                      await settings.setCalendarProvider(CalendarProvider.caldav);

                      setState(() {
                        _previousProvider = _selectedProvider;
                        _previousCalDAVUrl = settings.caldavUrl; // Track new URL
                        _selectedProvider = CalendarProvider.caldav;
                      });
                    },
                    onSignOut: () {
                      widget.urlController.clear();
                      widget.usernameController.clear();
                      widget.passwordController.clear();
                      widget.calendarNameController.clear();
                      setState(() {});
                    },
                  ),
                    ),
                  );
                },
              )
            else if (_selectedProvider == CalendarProvider.google)
              FutureBuilder(
                future: _ensureGoogleInitialized(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return CalendarProviderWidget(
                    provider: CalendarProvider.google,
                    syncDisabled: syncDisabled,
                    googleService: _googleService,
                    googleIsInitialized: _isGoogleInitialized,
                    onSignInSuccess: () async {
                      // Sign out from previous provider before switching
                      await _signOutPreviousProvider();

                      final settings = context.read<SettingsProvider>();
                      await settings.setCalendarProvider(CalendarProvider.google);

                      setState(() {
                        _previousProvider = _selectedProvider;
                        _previousGoogleEmail = settings.googleUserEmail; // Track new email
                        _selectedProvider = CalendarProvider.google;
                      });
                    },
                    onSignOut: () async {
                      final settings = context.read<SettingsProvider>();
                      await settings.setCalendarProvider(CalendarProvider.caldav);
                      setState(() {
                        _selectedProvider = CalendarProvider.caldav;
                      });
                    },
                  );
                },
              )
            else if (_selectedProvider == CalendarProvider.apple)
              CalendarProviderWidget(
                provider: CalendarProvider.apple,
                syncDisabled: syncDisabled,
                onSignOut: () => setState(() {}),
              ),

            const SizedBox(height: 24),

            // Background polling interval settings
            if (!syncDisabled)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final leftPadding = isMobile ? 16.0 : 0.0;

                  return Padding(
                    padding: EdgeInsets.only(left: leftPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      'server_settings.background_sync'.tr(),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'server_settings.background_sync_description'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final dropdownWidth = constraints.maxWidth * 0.8;

                        return SizedBox(
                          width: dropdownWidth,
                          child: DropdownButtonFormField<int>(
                            value: settings.serverPollIntervalMinutes,
                            decoration: InputDecoration(
                              labelText: 'server_settings.sync_interval'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('server_settings.sync_disabled'.tr()),
                              ),
                              DropdownMenuItem(
                                value: 15,
                                child: Text('server_settings.sync_15min'.tr()),
                              ),
                              DropdownMenuItem(
                                value: 30,
                                child: Text('server_settings.sync_30min'.tr()),
                              ),
                              DropdownMenuItem(
                                value: 60,
                                child: Text('server_settings.sync_1hour'.tr()),
                              ),
                              DropdownMenuItem(
                                value: 120,
                                child: Text('server_settings.sync_2hours'.tr()),
                              ),
                              DropdownMenuItem(
                                value: 240,
                                child: Text('server_settings.sync_4hours'.tr()),
                              ),
                            ],
                            onChanged: (value) async {
                              if (value != null) {
                                await settings.setServerPollInterval(value);
                                // Restart polling with new interval
                                final diaryProvider = context.read<DiaryProvider>();
                                diaryProvider.stopServerPolling();
                                if (value > 0) {
                                  diaryProvider.startServerPolling();
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                );
              },
            ),
            const SizedBox(height: 32)
          ],
        ),
      ),
    );
  }
}
