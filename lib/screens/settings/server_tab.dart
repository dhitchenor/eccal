import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_components.dart';
import '../../config/app_config.dart';
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
  final Future<void> Function({
    required BuildContext context,
    required String url,
    required String username,
    required String password,
    required String calendarName,
  })?
  onServerSetupSave; // Callback for server setup save flow

  const ServerTab({
    Key? key,
    required this.urlController,
    required this.usernameController,
    required this.passwordController,
    required this.calendarNameController,
    this.onServerSetupSave, // Optional
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsProvider>();

      // Check if user is actually signed in to the saved provider
      bool isSignedIn = false;

      switch (settings.calendarProvider) {
        case CalendarProvider.google:
          isSignedIn =
              settings.googleUserEmail != null &&
              settings.googleUserEmail!.isNotEmpty;
          break;

        case CalendarProvider.caldav:
        case CalendarProvider.apple:
          isSignedIn =
              settings.caldavUrl != null &&
              settings.caldavUrl!.isNotEmpty &&
              settings.caldavUsername != null &&
              settings.caldavUsername!.isNotEmpty;
          break;
      }

      setState(() {
        // If not signed in, default to CalDAV regardless of saved provider
        if (!isSignedIn) {
          _selectedProvider = CalendarProvider.caldav;
          _previousProvider = null;
          // Also update settings to reflect CalDAV default
          settings.setCalendarProvider(CalendarProvider.caldav);
        } else {
          // User is signed in, use their provider
          _selectedProvider = settings.calendarProvider;
          _previousProvider = settings.calendarProvider;
        }

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
    final isSameCalDAVServer =
        _previousProvider == CalendarProvider.caldav &&
        _selectedProvider == CalendarProvider.caldav &&
        _previousCalDAVUrl == currentCalDAVUrl;

    // Check if we're switching from Google to the same Google account
    final currentGoogleEmail = settings.googleUserEmail;
    final isSameGoogleAccount =
        _previousProvider == CalendarProvider.google &&
        _selectedProvider == CalendarProvider.google &&
        _previousGoogleEmail == currentGoogleEmail;

    if (_previousProvider == _selectedProvider &&
        (isSameCalDAVServer || isSameGoogleAccount)) {
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
        await settings.setCalendarProvider(CalendarProvider.caldav);
        break;

      case CalendarProvider.caldav:
        await settings.clearCalDAVSettings();
        await settings.clearCachedCalendarList();
        await settings.setCalendarProvider(CalendarProvider.caldav);
        widget.urlController.clear();
        widget.usernameController.clear();
        widget.passwordController.clear();
        widget.calendarNameController.clear();
        logger.info('Signed out from CalDAV');
        break;

      case CalendarProvider.apple:
        // Apple uses CalDAV (iCloud), so clear CalDAV settings
        await settings.clearCalDAVSettings();
        await settings.clearCachedCalendarList();
        await settings.setCalendarProvider(CalendarProvider.caldav);
        widget.urlController.clear();
        widget.usernameController.clear();
        widget.passwordController.clear();
        widget.calendarNameController.clear();
        logger.info('Signed out from Apple Calendar');
        break;
    }
  }

  bool _shouldSignOutPreviousProvider(CalendarProvider newProvider) {
    if (_previousProvider == null) return false;

    // Always sign out when switching providers (even CalDAV <-> Apple)
    // This ensures credentials are cleared for the next provider
    return _previousProvider != newProvider;
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

    // Check if any provider is signed in
    bool isSignedIn = false;

    switch (settings.calendarProvider) {
      case CalendarProvider.google:
        // Google is signed in if we have a user email
        isSignedIn =
            settings.googleUserEmail != null &&
            settings.googleUserEmail!.isNotEmpty;
        break;

      case CalendarProvider.caldav:
      case CalendarProvider.apple:
        // CalDAV/Apple are signed in if we have credentials
        isSignedIn =
            settings.caldavUrl != null &&
            settings.caldavUrl!.isNotEmpty &&
            settings.caldavUsername != null &&
            settings.caldavUsername!.isNotEmpty;
        break;
    }

    // Shared dropdown items for both mobile and desktop layouts
    final providerDropdownItems = [
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
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSpacing.item(),

            // Provider selector dropdown and Disable Sync switch
            SettingsTitleWithAction<CalendarProvider>(
              title: 'server_settings.caldav_provider'.tr(),
              switchValue: syncDisabled,
              onSwitchChanged: (value) {
                settings.setCaldavSyncDisabled(value);
              },
              switchLabel: 'server_settings.disable_sync'.tr(),
              dropdownLabel: '', // No label before the provider dropdown
              dropdownValue: isSignedIn
                  ? settings.calendarProvider
                  : _selectedProvider,
              dropdownItems: providerDropdownItems,
              onDropdownChanged: (syncDisabled || isSignedIn)
                  ? null // Disable dropdown if sync is disabled OR if signed in
                  : (value) {
                      if (value != null) {
                        // Clear iCloud URL when switching from Apple to CalDAV
                        if (_selectedProvider == CalendarProvider.apple &&
                            value == CalendarProvider.caldav &&
                            widget.urlController.text ==
                                'https://caldav.icloud.com') {
                          widget.urlController.clear();
                        }

                        setState(() {
                          _selectedProvider = value;
                        });
                      }
                    },
            ),

            SettingsSpacing.section(),

            // Provider-specific UI
            // Show UI based on _selectedProvider when not signed in
            // Show UI based on actual provider when signed in
            if ((isSignedIn ? settings.calendarProvider : _selectedProvider) ==
                CalendarProvider.caldav)
              IndentedContent(
                child: CalendarProviderWidget(
                  provider: CalendarProvider.caldav,
                  syncDisabled: syncDisabled,
                  caldavUrlController: widget.urlController,
                  caldavUsernameController: widget.usernameController,
                  caldavPasswordController: widget.passwordController,
                  caldavCalendarNameController: widget.calendarNameController,
                  onServerSetupSave:
                      widget.onServerSetupSave, // Pass for server setup flow
                  onSignInSuccess: () async {
                    final settings = context.read<SettingsProvider>();

                    // Sign out from previous provider if switching providers
                    if (_shouldSignOutPreviousProvider(
                      CalendarProvider.caldav,
                    )) {
                      await _signOutPreviousProvider();
                    }

                    await settings.setCalendarProvider(CalendarProvider.caldav);

                    setState(() {
                      _previousProvider = CalendarProvider.caldav;
                      _previousCalDAVUrl = settings.caldavUrl; // Track new URL
                      _selectedProvider = CalendarProvider.caldav;
                    });
                  },
                  onSignOut: () {
                    widget.urlController.clear();
                    widget.usernameController.clear();
                    widget.passwordController.clear();
                    widget.calendarNameController.clear();
                    setState(() {
                      _selectedProvider = CalendarProvider.caldav;
                      _previousProvider = null;
                      _previousCalDAVUrl = null;
                    });
                  },
                ),
              )
            else if ((isSignedIn
                    ? settings.calendarProvider
                    : _selectedProvider) ==
                CalendarProvider.google)
              IndentedContent(
                child: FutureBuilder(
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
                      onServerSetupSave: widget
                          .onServerSetupSave, // Pass for server setup flow
                      onSignInSuccess: () async {
                        // Sign out from previous provider before switching
                        await _signOutPreviousProvider();

                        final settings = context.read<SettingsProvider>();
                        await settings.setCalendarProvider(
                          CalendarProvider.google,
                        );

                        setState(() {
                          _previousProvider = _selectedProvider;
                          _previousGoogleEmail =
                              settings.googleUserEmail; // Track new email
                          _selectedProvider = CalendarProvider.google;
                        });
                      },
                      onSignOut: () async {
                        final settings = context.read<SettingsProvider>();
                        await settings.setCalendarProvider(
                          CalendarProvider.caldav,
                        );
                        setState(() {
                          _selectedProvider = CalendarProvider.caldav;
                          _previousProvider = null;
                          _previousGoogleEmail = null;
                        });
                      },
                    );
                  },
                ),
              )
            else if ((isSignedIn
                    ? settings.calendarProvider
                    : _selectedProvider) ==
                CalendarProvider.apple)
              IndentedContent(
                child: CalendarProviderWidget(
                  provider: CalendarProvider.apple,
                  syncDisabled: syncDisabled,
                  caldavUrlController: widget.urlController,
                  caldavUsernameController: widget.usernameController,
                  caldavPasswordController: widget.passwordController,
                  caldavCalendarNameController: widget.calendarNameController,
                  onServerSetupSave:
                      widget.onServerSetupSave, // Pass for server setup flow
                  onSignInSuccess: () async {
                    final settings = context.read<SettingsProvider>();

                    // Only sign out if switching between providers with different credentials
                    if (_shouldSignOutPreviousProvider(
                      CalendarProvider.apple,
                    )) {
                      await _signOutPreviousProvider();
                    }

                    await settings.setCalendarProvider(CalendarProvider.apple);

                    setState(() {
                      _previousProvider = CalendarProvider.apple;
                      _previousCalDAVUrl =
                          settings.caldavUrl; // Track iCloud URL
                      _selectedProvider = CalendarProvider.apple;
                    });
                  },
                  onSignOut: () async {
                    final settings = context.read<SettingsProvider>();
                    await settings.clearCalDAVSettings();
                    await settings.clearCachedCalendarList();
                    widget.urlController.clear();
                    widget.usernameController.clear();
                    widget.passwordController.clear();
                    widget.calendarNameController.clear();
                    setState(() {
                      _selectedProvider = CalendarProvider.caldav;
                      _previousProvider = null;
                      _previousCalDAVUrl = null;
                    });
                  },
                ),
              ),
            const SizedBox(height: 24),
            // Background polling interval settings
            if (!syncDisabled) ...[
              SettingsTitleWithAction<int>(
                title: 'server_settings.background_sync'.tr(),
                helperText: 'server_settings.background_sync_description'.tr(),
                dropdownLabel: 'server_settings.sync_interval'.tr(),
                dropdownValue: settings.serverPollIntervalMinutes,
                dropdownItems: [
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
                onDropdownChanged: (value) async {
                  if (value != null) {
                    await settings.setServerPollInterval(value);
                    final diaryProvider = context.read<DiaryProvider>();
                    diaryProvider.stopServerPolling();
                    if (value > 0) {
                      diaryProvider.startServerPolling();
                    }
                  }
                },
              ),
            ],
            SettingsSpacing.section(),
          ],
        ),
      ),
    );
  }
}
