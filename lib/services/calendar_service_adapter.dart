import 'caldav_service.dart';
import 'google_calendar_service.dart';
import 'logger_service.dart';
import '../providers/settings_provider.dart';
import '../models/diary_entry.dart';
import '../utils/app_localizations.dart';

// Adapter that routes calendar operations to the correct service
// based on the selected provider (CalDAV or Google Calendar)
class CalendarServiceAdapter {
  final SettingsProvider settings;
  final GoogleCalendarService? googleService;

  CalendarServiceAdapter({required this.settings, this.googleService});

  // Get the appropriate CalDAVService instance
  //
  // For Google Calendar: Uses OAuth token authentication
  // For CalDAV: Uses basic authentication
  // For Apple: Not yet implemented
  Future<CalDAVService?> getCalDAVService() async {
    logger.debug('Provider type: ${settings.calendarProvider}');

    switch (settings.calendarProvider) {
      case CalendarProvider.google:
        logger.debug('Using Google Calendar provider');

        if (googleService == null) {
          logger.debug('Google Calendar service not initialized');
          throw Exception('Google Calendar service not initialized');
        }

        // Get Google Calendar CalDAV endpoint and auth headers
        final caldavUrl = await googleService!.getCalDAVUrl();
        logger.debug('CalDAV URL from service: $caldavUrl');

        final authHeaders = await googleService!.getAuthHeaders();
        logger.debug('Auth headers from service: ${authHeaders != null}');
        if (authHeaders != null) {
          logger.debug('Auth headers keys: ${authHeaders.keys.toList()}');
        }

        if (caldavUrl == null || authHeaders == null) {
          logger.error('Missing caldavUrl or authHeaders!');
          throw Exception('Google Calendar not authenticated');
        }

        // Create CalDAVService with OAuth authentication
        return CalDAVService.withCustomAuth(
          url: caldavUrl,
          authHeaders: authHeaders,
        );

      case CalendarProvider.apple:
        logger.error('Apple Calendar - not implemented');
        throw Exception('Apple Calendar not yet implemented');

      case CalendarProvider.caldav:
        logger.info('Using regular CalDAV');
        // Use regular CalDAV with basic auth
        if (settings.caldavUrl == null || settings.caldavUrl!.isEmpty) {
          logger.error('CalDAV URL not configured');
          return null;
        }

        // Get password from secure storage
        String? password;
        try {
          password = await settings.caldavPassword;
        } catch (e) {
          logger.error('Failed to retrieve CalDAV password from secure storage: $e');

          if (SettingsProvider.isKeyringError(e)) {
            throw Exception('Keyring service not available. '
                          'See FAQ for more details.');
          }
          rethrow;
        }

        if (password == null || password.isEmpty) {
          logger.error('CalDAV password not found in secure storage');
          return null;
        }

        return CalDAVService(
          url: settings.caldavUrl!,
          username: settings.caldavUsername ?? '',
          password: password,
        );
    }
  }

  // Get the calendar name based on provider
  String? getCalendarName() {
    switch (settings.calendarProvider) {
      case CalendarProvider.google:
        // For Google Calendar, return empty string - calendar ID is in the URL
        return '';
      case CalendarProvider.apple:
        return null; // Not yet implemented
      case CalendarProvider.caldav:
        return settings.caldavCalendarName;
    }
  }

  // Create an event (works for all providers)
  Future<void> createEvent(DiaryEntry entry) async {
    final caldavService = await getCalDAVService();
    if (caldavService == null) return;

    final calendarName = getCalendarName();
    if (calendarName == null) return;

    await caldavService.createEvent(
      entry: entry,
      durationMinutes: settings.eventDurationMinutes,
      calendarName: calendarName,
    );
  }

  // Update an event (works for all providers)
  Future<void> updateEvent(DiaryEntry entry) async {
    final caldavService = await getCalDAVService();
    if (caldavService == null) return;

    final calendarName = getCalendarName();
    if (calendarName == null) return;

    await caldavService.updateEvent(
      entry: entry,
      durationMinutes: settings.eventDurationMinutes,
      calendarName: calendarName,
    );
  }

  // Delete an event (works for all providers)
  Future<void> deleteEvent(String entryId) async {
    final caldavService = await getCalDAVService();
    if (caldavService == null) return;

    final calendarName = getCalendarName();
    if (calendarName == null) return;

    await caldavService.deleteEvent(entryId, calendarName);
  }

  // Fetch events from server (works for all providers)
  Future<List<CalendarEvent>> fetchEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final caldavService = await getCalDAVService();
    if (caldavService == null) return [];

    final calendarName = getCalendarName();
    if (calendarName == null) return [];

    return await caldavService.fetchEvents(
      startDate: startDate,
      endDate: endDate,
      calendarName: calendarName,
    );
  }

  // Test connection (works for all providers)
  Future<Map<String, dynamic>> testConnection() async {
    if (settings.calendarProvider == CalendarProvider.google) {
      if (googleService == null) {
        return {
          'success': false,
          'error': 'setup.gcal_service_not_initialized'.tr(),
        };
      }
      return await googleService!.testConnection();
    }

    final caldavService = await getCalDAVService();
    if (caldavService == null) {
      return {'success': false, 'error': 'setup.caldav_not_configured'.tr()};
    }

    return await caldavService.testConnection();
  }
}
