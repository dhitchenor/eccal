import 'caldav_service.dart';
import 'google_calendar_service.dart';
import '../providers/settings_provider.dart';
import '../models/diary_entry.dart';

// Adapter that routes calendar operations to the correct service
// based on the selected provider (CalDAV or Google Calendar)
class CalendarServiceAdapter {
  final SettingsProvider settings;
  final GoogleCalendarService? googleService;

  CalendarServiceAdapter({required this.settings, this.googleService});

  /// Get the appropriate CalDAVService instance
  ///
  /// For Google Calendar: Uses OAuth token authentication
  /// For CalDAV: Uses basic authentication
  /// For Apple: Not yet implemented
  Future<CalDAVService?> getCalDAVService() async {
    switch (settings.calendarProvider) {
      case CalendarProvider.google:
        if (googleService == null) {
          throw Exception('Google Calendar service not initialized');
        }

        // Get Google Calendar CalDAV endpoint and auth headers
        final caldavUrl = await googleService!.getCalDAVUrl();
        final authHeaders = await googleService!.getAuthHeaders();

        if (caldavUrl == null || authHeaders == null) {
          throw Exception('Google Calendar not authenticated');
        }

        // Create CalDAVService with OAuth authentication
        return CalDAVService.withCustomAuth(
          url: caldavUrl,
          authHeaders: authHeaders,
        );

      case CalendarProvider.apple:
        throw Exception('Apple Calendar not yet implemented');

      case CalendarProvider.caldav:
        // Use regular CalDAV with basic auth
        if (settings.caldavUrl == null || settings.caldavUrl!.isEmpty) {
          return null;
        }

        return CalDAVService(
          url: settings.caldavUrl!,
          username: settings.caldavUsername ?? '',
          password: settings.caldavPassword ?? '',
        );
    }
  }

  // Get the calendar name based on provider
  String? getCalendarName() {
    switch (settings.calendarProvider) {
      case CalendarProvider.google:
        return settings.googleCalendarId ?? 'primary';
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
          'error': 'Google Calendar service not initialized',
        };
      }
      return await googleService!.testConnection();
    }

    final caldavService = await getCalDAVService();
    if (caldavService == null) {
      return {'success': false, 'error': 'CalDAV not configured'};
    }

    return await caldavService.testConnection();
  }
}
