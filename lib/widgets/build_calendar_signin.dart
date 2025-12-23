import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_info.dart';
import '../providers/settings_provider.dart';
import '../providers/diary_provider.dart';
import '../services/apple_calendar_service.dart';
import '../services/caldav_service.dart';
import '../services/google_calendar_service.dart';
import '../services/logger_service.dart';
import '../utils/app_localizations.dart';
import '../utils/error_snackbar.dart';

/// Reusable widget for calendar provider sign-in and calendar selection
/// Handles both Google Calendar and CalDAV with a unified interface
class CalendarSignInWidget extends StatefulWidget {
  final CalendarProvider provider;
  final bool syncDisabled;
  final VoidCallback? onSignOut;
  final VoidCallback? onCalendarSelected; // Callback when calendar is selected

  // CalDAV-specific
  final String? caldavUrl;
  final String? caldavUsername;
  final String? caldavPassword;

  // Google-specific
  final GoogleCalendarService? googleService;

  const CalendarSignInWidget({
    Key? key,
    required this.provider,
    required this.syncDisabled,
    this.onSignOut,
    this.onCalendarSelected,
    this.caldavUrl,
    this.caldavUsername,
    this.caldavPassword,
    this.googleService,
  }) : super(key: key);

  @override
  State<CalendarSignInWidget> createState() => _CalendarSignInWidgetState();
}

class _CalendarSignInWidgetState extends State<CalendarSignInWidget> {
  late Future<List<CalendarInfo>> _calendarsFuture;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _calendarsFuture = _loadCalendars(settings);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return FutureBuilder<List<CalendarInfo>>(
      future: _calendarsFuture,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Signed in status
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(
                'server_settings.signed_in_as'.tr([
                  _getUserIdentifier(settings),
                ]),
              ),
              subtitle: Text(_getProviderName()),
              trailing: TextButton(
                onPressed: widget.syncDisabled
                    ? null
                    : () => _handleSignOut(context, settings),
                child: Text('sign_out'.tr()),
              ),
            ),
            const SizedBox(height: 16),

            // Calendar selection
            if (snapshot.connectionState == ConnectionState.waiting)
              const CircularProgressIndicator()
            else if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'error_'.tr([snapshot.error.toString()]),
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (!snapshot.hasData || snapshot.data!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('server_settings.no_calendars_found'.tr()),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildCalendarComboBox(
                  snapshot.data!,
                  settings,
                  context,
                ),
              ),
          ],
        );
      },
    );
  }

  String _getUserIdentifier(SettingsProvider settings) {
    switch (widget.provider) {
      case CalendarProvider.google:
        return widget.googleService?.userEmail ?? 'unknown'.tr();
      case CalendarProvider.caldav:
        return widget.caldavUsername ?? 'unknown'.tr();
      case CalendarProvider.apple:
        // Apple uses CalDAV credentials (iCloud), so show the Apple ID
        return widget.caldavUsername ?? 'unknown'.tr();
    }
  }

  String _getProviderName() {
    switch (widget.provider) {
      case CalendarProvider.google:
        return 'Google Calendar';
      case CalendarProvider.caldav:
        return 'CalDAV Server';
      case CalendarProvider.apple:
        return 'Apple Calendar';
    }
  }

  Future<List<CalendarInfo>> _loadCalendars(SettingsProvider settings) async {
    // Try cache first for instant loading
    final cached = settings.getCachedCalendarsAsCalendarInfo();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // No cache - fetch from server
    logger.debug('No cache found, fetching calendars from server');
    return await _fetchCalendarsFromServer(settings);
  }

  // Fetch calendars from server and update cache
  Future<List<CalendarInfo>> _fetchCalendarsFromServer(
    SettingsProvider settings,
  ) async {
    List<CalendarInfo> calendars;

    switch (widget.provider) {
      case CalendarProvider.google:
        if (widget.googleService == null)
          throw Exception('Google service not provided');
        calendars = await widget.googleService!.listCalendars();
        break;

      case CalendarProvider.caldav:
        if (widget.caldavUrl == null || widget.caldavUsername == null) {
          throw Exception('CalDAV credentials not provided');
        }

        // Get password from secure storage
        String? password;
        try {
          password = await settings.caldavPassword;
        } catch (e) {
          logger.error('Failed to retrieve password: $e');

          if (SettingsProvider.isKeyringError(e)) {
            throw Exception(
              'Keyring service not available. '
              'See FAQ for more details.',
            );
          }
          rethrow;
        }

        if (password == null || password.isEmpty) {
          throw Exception('CalDAV password not found');
        }

        final caldavService = CalDAVService(
          url: widget.caldavUrl!,
          username: widget.caldavUsername!,
          password: password,
        );
        calendars = await caldavService.listCalendars();
        break;

      case CalendarProvider.apple:
        // Apple uses AppleCalendarService for URL discovery
        if (widget.caldavUrl == null || widget.caldavUsername == null) {
          throw Exception('Apple Calendar credentials not provided');
        }

        // Get password from secure storage
        String? password;
        try {
          password = await settings.caldavPassword;
        } catch (e) {
          logger.error('Failed to retrieve password: $e');

          if (SettingsProvider.isKeyringError(e)) {
            throw Exception(
              'Keyring service not available. '
              'See FAQ for more details.',
            );
          }
          rethrow;
        }

        if (password == null || password.isEmpty) {
          throw Exception('Apple Calendar password not found');
        }

        final appleService = AppleCalendarService(
          username: widget.caldavUsername!,
          password: password,
        );

        // Discover calendar home URL (this also creates the CalDAV service)
        final calendarHomeUrl = await appleService.discoverCalendarHomeUrl();
        if (calendarHomeUrl == null) {
          throw Exception('Failed to discover iCloud calendar URL');
        }

        calendars = await appleService.listCalendars();
        break;
    }

    // Update cache
    if (calendars.isNotEmpty) {
      await settings.setCachedCalendarList(calendars);
    }

    return calendars;
  }

  Widget _buildCalendarComboBox(
    List<CalendarInfo> calendars,
    SettingsProvider settings,
    BuildContext context,
  ) {
    final currentCalendarId = _getCurrentCalendarId(settings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'server_settings.select_calendar'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        // Use LayoutBuilder to get actual available width
        LayoutBuilder(
          builder: (context, constraints) {
            // On narrow screens (< 600px), use full width
            // On wider screens, use 80% with minimum 200px
            final isNarrow = constraints.maxWidth < 600;
            final dropdownWidth = isNarrow
                ? constraints.maxWidth
                : constraints.maxWidth * 0.8;
            final finalWidth = dropdownWidth > 200 ? dropdownWidth : 200.0;

            return DropdownMenu<CalendarInfo>(
              width: finalWidth,
              menuHeight:
                  300, // Limit height to show ~5 entries (60px per entry)
              initialSelection: calendars.firstWhere(
                (cal) => cal.id == currentCalendarId,
                orElse: () => calendars.first,
              ),
              dropdownMenuEntries: calendars.map((cal) {
                return DropdownMenuEntry<CalendarInfo>(
                  value: cal,
                  label: cal.name,
                );
              }).toList(),
              label: Text('server_settings.calendar_name'.tr()),
              hintText: 'server_settings.calendar_hint'.tr(),
              enableFilter: true,
              enableSearch: true,
              requestFocusOnTap: true,
              onSelected: (CalendarInfo? selection) async {
                if (selection != null) {
                  await _onCalendarSelected(
                    context,
                    selection.id,
                    selection.name,
                    calendars,
                    settings,
                  );
                }
              },
            );
          },
        ),

        const SizedBox(height: 8),

        Text(
          'server_settings.calendar_help'.tr(),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String? _getCurrentCalendarId(SettingsProvider settings) {
    switch (widget.provider) {
      case CalendarProvider.google:
        return settings.googleCalendarId;
      case CalendarProvider.caldav:
        return settings.caldavCalendarName;
      case CalendarProvider.apple:
        // Apple uses CalDAV calendar name
        return settings.caldavCalendarName;
    }
  }

  Future<void> _onCalendarSelected(
    BuildContext context,
    String calendarIdOrName,
    String calendarName,
    List<CalendarInfo> existingCalendars,
    SettingsProvider settings,
  ) async {
    // Check if calendar exists
    final existing = existingCalendars.firstWhere(
      (cal) => cal.id == calendarIdOrName || cal.name == calendarIdOrName,
      orElse: () => CalendarInfo(id: '', name: '', provider: widget.provider),
    );

    String calendarId;

    if (existing.id.isEmpty) {
      // Calendar doesn't exist - ask to create
      final create = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('server_settings.create_calendar_title'.tr()),
          content: Text(
            'server_settings.create_calendar_message'.tr([calendarName]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('server_settings.create'.tr()),
            ),
          ],
        ),
      );

      if (create != true) return;

      // Create the calendar
      try {
        calendarId = await _createCalendar(calendarName, settings);
        logger.info('Created calendar: $calendarName (ID: $calendarId)');

        if (context.mounted) {
          ErrorSnackbar.showSuccess(
            context,
            'caldav.calendar_created'.tr([calendarName]),
          );
        }
      } catch (e) {
        logger.error('Failed to create calendar: $e');
        if (context.mounted) {
          ErrorSnackbar.showError(context, 'error_'.tr([e.toString()]));
        }
        return;
      }
    } else {
      calendarId = existing.id;
    }

    // Save calendar selection
    await _saveCalendarSelection(calendarId, settings);

    // Refresh diary provider
    if (context.mounted) {
      final diaryProvider = context.read<DiaryProvider>();
      await _refreshDiaryProvider(diaryProvider, settings, calendarId);

      // Trigger callback to notify parent (for auto sign-out of previous provider)
      if (widget.onCalendarSelected != null) {
        widget.onCalendarSelected!();
      }

      ErrorSnackbar.showSuccess(
        context,
        'server_settings.using_calendar'.tr([calendarName]),
      );
    }
  }

  Future<String> _createCalendar(
    String calendarName,
    SettingsProvider settings,
  ) async {
    switch (widget.provider) {
      case CalendarProvider.google:
        if (widget.googleService == null)
          throw Exception('Google service not available');
        return await widget.googleService!.createCalendar(calendarName);

      case CalendarProvider.caldav:
        if (widget.caldavUrl == null || widget.caldavUsername == null) {
          throw Exception('CalDAV credentials not available');
        }

        // Get password from secure storage
        String? password;
        try {
          password = await settings.caldavPassword;
        } catch (e) {
          logger.error('Failed to retrieve password: $e');

          if (SettingsProvider.isKeyringError(e)) {
            throw Exception(
              'Keyring service not available. '
              'Please install gnome-keyring or kwalletmanager. '
              'See FAQ for more details.',
            );
          }
          rethrow;
        }

        if (password == null || password.isEmpty) {
          throw Exception('CalDAV password not found');
        }

        final caldavService = CalDAVService(
          url: widget.caldavUrl!,
          username: widget.caldavUsername!,
          password: password,
        );
        await caldavService.createCalendar(calendarName);
        return calendarName; // CalDAV uses name as ID

      case CalendarProvider.apple:
        // Apple uses AppleCalendarService
        if (widget.caldavUrl == null || widget.caldavUsername == null) {
          throw Exception('Apple Calendar credentials not available');
        }

        // Get password from secure storage
        String? password;
        try {
          password = await settings.caldavPassword;
        } catch (e) {
          logger.error('Failed to retrieve password: $e');

          if (SettingsProvider.isKeyringError(e)) {
            throw Exception(
              'Keyring service not available. '
              'Please install gnome-keyring or kwalletmanager. '
              'See FAQ for more details.',
            );
          }
          rethrow;
        }

        if (password == null || password.isEmpty) {
          throw Exception('Apple Calendar password not found');
        }

        final appleService = AppleCalendarService(
          username: widget.caldavUsername!,
          password: password,
        );

        // Discover URL and create calendar
        await appleService.discoverCalendarHomeUrl();
        await appleService.createCalendar(calendarName);
        return calendarName; // Uses name as ID
    }
  }

  Future<void> _saveCalendarSelection(
    String calendarId,
    SettingsProvider settings,
  ) async {
    switch (widget.provider) {
      case CalendarProvider.google:
        await widget.googleService?.setCalendarId(calendarId);
        await settings.setGoogleCalendar(
          calendarId: calendarId,
          userEmail: widget.googleService?.userEmail,
        );
        break;

      case CalendarProvider.caldav:
        await settings.setCalDAVCalendarName(calendarId);
        break;

      case CalendarProvider.apple:
        // Apple uses CalDAV settings
        await settings.setCalDAVCalendarName(calendarId);
        break;
    }
  }

  Future<void> _refreshDiaryProvider(
    DiaryProvider diaryProvider,
    SettingsProvider settings,
    String calendarId,
  ) async {
    switch (widget.provider) {
      case CalendarProvider.google:
        diaryProvider.refreshCalendarAdapter();
        break;

      case CalendarProvider.caldav:
        // Get password from secure storage
        String? password;
        try {
          password = await settings.caldavPassword;
        } catch (e) {
          logger.error('Failed to retrieve password: $e');

          if (SettingsProvider.isKeyringError(e)) {
            throw Exception(
              'Keyring service not available. '
              'See FAQ for more details.',
            );
          }
          rethrow;
        }

        if (password == null || password.isEmpty) {
          throw Exception('CalDAV password not found');
        }

        diaryProvider.configureCalDAV(
          url: widget.caldavUrl!,
          username: widget.caldavUsername!,
          password: password,
          calendarName: calendarId,
          eventDurationMinutes: settings.eventDurationMinutes,
        );
        break;

      case CalendarProvider.apple:
        // Apple uses CalDAV configuration
        // Get password from secure storage
        String? password;
        try {
          password = await settings.caldavPassword;
        } catch (e) {
          logger.error('Failed to retrieve password: $e');

          if (SettingsProvider.isKeyringError(e)) {
            throw Exception(
              'Keyring service not available. '
              'See FAQ for more details.',
            );
          }
          rethrow;
        }

        if (password == null || password.isEmpty) {
          throw Exception('Apple Calendar password not found');
        }

        diaryProvider.configureCalDAV(
          url: widget.caldavUrl!,
          username: widget.caldavUsername!,
          password: password,
          calendarName: calendarId,
          eventDurationMinutes: settings.eventDurationMinutes,
        );
        break;
    }
  }

  Future<void> _handleSignOut(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    switch (widget.provider) {
      case CalendarProvider.google:
        await widget.googleService?.signOut();
        await settings.setGoogleCalendar(calendarId: null, userEmail: null);
        break;

      case CalendarProvider.caldav:
        await settings.clearCalDAVSettings();
        break;

      case CalendarProvider.apple:
        // Apple uses CalDAV settings
        await settings.clearCalDAVSettings();
        break;
    }

    if (widget.onSignOut != null) {
      widget.onSignOut!();
    }

    if (context.mounted) {
      ErrorSnackbar.showWarning(
        context,
        'server_settings.signed_out_from'.tr([_getProviderName()]),
      );
    }
  }
}
