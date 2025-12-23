import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/calendar_info.dart';
import '../models/diary_entry.dart';
import '../providers/settings_provider.dart';
import '../services/icalendar_generator.dart';
import '../services/icalendar_parser.dart';
import '../services/logger_service.dart';
import '../utils/app_localizations.dart';

class CalDAVService {
  final String url;
  final String username;
  final String password;
  final Map<String, String>? customAuthHeaders;
  final bool isGoogleCalendar; // Flag to identify Google Calendar provider

  // Cache for calendar existence checks (reduces redundant server requests)
  static final Map<String, bool> _calendarExistsCache = {};
  static DateTime? _cacheExpiry;
  static const _cacheDuration = Duration(minutes: 5);

  CalDAVService({
    required this.url,
    required this.username,
    required this.password,
  }) : customAuthHeaders = null,
       isGoogleCalendar = false;

  // Constructor for OAuth providers like Google Calendar
  CalDAVService.withCustomAuth({
    required this.url,
    required Map<String, String> authHeaders,
  }) : customAuthHeaders = authHeaders,
       username = '',
       password = '',
       isGoogleCalendar = true; // Mark as Google Calendar

  String get _authHeader {
    // Use custom auth headers if provided (for OAuth)
    if (customAuthHeaders != null) {
      return customAuthHeaders!['Authorization'] ?? '';
    }
    // Otherwise use basic auth
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return 'Basic $credentials';
  }

  Map<String, String> get _defaultHeaders {
    if (customAuthHeaders != null) {
      return customAuthHeaders!;
    }
    return {
      'Authorization': _authHeader,
      'Content-Type': 'text/calendar; charset=utf-8',
    };
  }

  // Test connection to CalDAV server
  Future<Map<String, dynamic>> testConnection() async {
    if (url.isEmpty) {
      return {'success': false, 'error': 'caldav.url_not_configured'.tr()};
    }

    try {
      // Test basic authentication with PROPFIND on base URL
      final client = http.Client();

      final request = http.Request('PROPFIND', Uri.parse(url));
      request.headers['Authorization'] = _authHeader;
      request.headers['Depth'] = '0';

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      client.close();

      if (response.statusCode == 207 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'caldav.connected_successfully'.tr(),
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'caldav.auth_failed'.tr()};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'caldav.url_not_found'.tr()};
      } else {
        return {
          'success': false,
          'error': 'caldav.server_status'.tr([response.statusCode.toString()]),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'caldav.connection_failed_'.tr([e.toString()]),
      };
    }
  }

  // Setup calendar: test connection only
  // Calendar will be created automatically during first sync if it doesn't exist
  Future<Map<String, dynamic>> setupCalendar(String calendarName) async {
    // Test connection
    logger.info('Testing connection to CalDAV server...');
    final connectionTest = await testConnection();

    if (!connectionTest['success']) {
      return {
        'success': false,
        'step': 'connection',
        'error': connectionTest['error'],
      };
    }

    logger.info('Connection successful!');

    // Return success - calendar will be checked/created during first sync
    return {
      'success': true,
      'step': 'complete',
      'message': connectionTest['message'],
    };
  }

  // Check if a calendar exists (with caching to reduce server requests)
  Future<bool> calendarExists(String calendarName) async {
    if (url.isEmpty) return false;

    // Check cache first
    final cacheKey = '$url/$calendarName';
    final now = DateTime.now();

    // Clear cache if expired
    if (_cacheExpiry != null && now.isAfter(_cacheExpiry!)) {
      _calendarExistsCache.clear();
      _cacheExpiry = null;
    }

    // Return cached result if available
    if (_calendarExistsCache.containsKey(cacheKey)) {
      logger.debug('CalDAV: Calendar "$calendarName" exists (cached)');
      return _calendarExistsCache[cacheKey]!;
    }

    try {
      // Check the server
      final calendarUrl = _getCalendarUrl(calendarName);
      final client = http.Client();

      final request = http.Request('PROPFIND', Uri.parse(calendarUrl));
      request.headers['Authorization'] = _authHeader;
      request.headers['Depth'] = '0';

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      client.close();

      final exists = response.statusCode == 207 || response.statusCode == 200;

      // Cache the result
      _calendarExistsCache[cacheKey] = exists;
      _cacheExpiry ??= now.add(_cacheDuration);

      if (exists) {
        logger.info('Calendar "$calendarName" already exists');
      }

      return exists;
    } catch (e) {
      logger.error('Error checking calendar: $e');
      return false;
    }
  }

  // Create a new calendar
  Future<bool> createCalendar(String calendarName) async {
    if (url.isEmpty) {
      logger.info('CalDAV URL not configured');
    }

    try {
      final calendarUrl = _getCalendarUrl(calendarName);

      // MKCALENDAR request body
      final body =
          '''<?xml version="1.0" encoding="utf-8"?>
<C:mkcalendar xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
  <D:set>
    <D:prop>
      <D:displayname>$calendarName</D:displayname>
      <C:calendar-description>${'caldav.calendar_description'.tr([AppConfig.appName])}</C:calendar-description>
      <C:supported-calendar-component-set>
        <C:comp name="VEVENT"/>
      </C:supported-calendar-component-set>
    </D:prop>
  </D:set>
</C:mkcalendar>''';

      final client = http.Client();

      final request = http.Request('MKCALENDAR', Uri.parse(calendarUrl));
      request.headers['Authorization'] = _authHeader;
      request.headers['Content-Type'] = 'application/xml; charset=utf-8';
      request.body = body;

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      client.close();

      if (response.statusCode == 201) {
        logger.info('Calendar "$calendarName" created successfully');
        return true;
      } else if (response.statusCode == 405) {
        // 405 means calendar already exists
        logger.info('Calendar "$calendarName" already exists');
        return true;
      } else {
        logger.info(
          'Failed to create calendar: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.error('Error creating calendar: $e');
      return false;
    }
  }

  // Ensure calendar exists, create if it doesn't
  Future<bool> ensureCalendar(String calendarName) async {
    final exists = await calendarExists(calendarName);
    if (exists) {
      logger.info('Calendar "$calendarName" already exists');
      return true;
    }
    logger.info('Calendar "$calendarName" does not exist, creating...');
    return await createCalendar(calendarName);
  }

  // Get the calendar URL for a given calendar name
  String _getCalendarUrl(String calendarName) {
    // For Google Calendar, URL is already complete - just ensure trailing slash
    if (isGoogleCalendar) {
      logger.debug('Google Calendar URL (no modification): $url');
      return url.endsWith('/') ? url : '$url/';
    }

    // For regular CalDAV: Remove trailing slash from URL if present
    final baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    // Encode calendar name for URL
    final encodedName = Uri.encodeComponent(calendarName);

    // Construct full path: base URL + /calendars/ + username + / + calendar name + /
    // Example: https://cloud.example.com/remote.php/dav/calendars/john/My%20Diary/
    return '$baseUrl/calendars/$username/$encodedName/';
  }

  Future<void> createEvent({
    required DiaryEntry entry,
    required int durationMinutes,
    required String calendarName,
  }) async {
    if (url.isEmpty) {
      logger.info('CalDAV URL not configured');
    }

    // Ensure calendar exists
    await ensureCalendar(calendarName);

    final icsContent = ICalendarGenerator.generate(
      entry,
      durationMinutes: durationMinutes,
    );

    try {
      final calendarUrl = _getCalendarUrl(calendarName);
      final eventUrl = '$calendarUrl${entry.id}.ics';

      final response = await http.put(
        Uri.parse(eventUrl),
        headers: {..._defaultHeaders, 'If-None-Match': '*'},
        body: icsContent,
      );

      if (response.statusCode != 201 && response.statusCode != 204) {
        logger.info(
          'Failed to create event: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      logger.error('CalDAV error: $e');
    }
  }

  Future<void> updateEvent({
    required DiaryEntry entry,
    required int durationMinutes,
    required String calendarName,
  }) async {
    if (url.isEmpty) {
      logger.info('CalDAV URL not configured');
    }

    // Ensure calendar exists
    await ensureCalendar(calendarName);

    final icsContent = ICalendarGenerator.generate(
      entry,
      durationMinutes: durationMinutes,
    );

    try {
      final calendarUrl = _getCalendarUrl(calendarName);
      final eventUrl = '$calendarUrl${entry.id}.ics';
      final response = await http.put(
        Uri.parse(eventUrl),
        headers: _defaultHeaders,
        body: icsContent,
      );

      if (response.statusCode != 204 && response.statusCode != 201) {
        logger.info('Failed to update event: ${response.statusCode}');
      }
    } catch (e) {
      logger.error('CalDAV error: $e');
    }
  }

  Future<void> deleteEvent(String entryId, String calendarName) async {
    if (url.isEmpty) {
      logger.info('CalDAV URL not configured');
    }

    try {
      final calendarUrl = _getCalendarUrl(calendarName);
      final eventUrl = '$calendarUrl$entryId.ics';
      final response = await http.delete(
        Uri.parse(eventUrl),
        headers: {'Authorization': _authHeader},
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        logger.info('Failed to delete event: ${response.statusCode}');
      }
    } catch (e) {
      logger.error('CalDAV error: $e');
    }
  }

  Future<List<CalendarEvent>> fetchEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? calendarName,
  }) async {
    if (url.isEmpty) {
      throw Exception('caldav.url_not_configured'.tr());
    }

    // For Google Calendar, calendar name can be empty (it's in the URL)
    if (!isGoogleCalendar) {
      // Regular CalDAV - calendar name is required
      if (calendarName == null || calendarName.isEmpty) {
        throw Exception('caldav.no_calendar_name'.tr());
      }

      // Check if calendar exists first
      final exists = await calendarExists(calendarName);
      if (!exists) {
        throw Exception('caldav.calendar_not_exist'.tr([calendarName]));
      }
    }

    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 365));
    final end = endDate ?? DateTime.now().add(const Duration(days: 365));

    // For Google Calendar, use simpler query without time-range
    final reportBody = isGoogleCalendar
        ? '''<?xml version="1.0" encoding="utf-8"?>
<C:calendar-query xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
  <D:prop>
    <D:getetag/>
    <C:calendar-data/>
  </D:prop>
  <C:filter>
    <C:comp-filter name="VCALENDAR">
      <C:comp-filter name="VEVENT"/>
    </C:comp-filter>
  </C:filter>
</C:calendar-query>'''
        : '''<?xml version="1.0" encoding="utf-8" ?>
<C:calendar-query xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
  <D:prop>
    <D:getetag/>
    <C:calendar-data/>
  </D:prop>
  <C:filter>
    <C:comp-filter name="VCALENDAR">
      <C:comp-filter name="VEVENT">
        <C:time-range start="${ICalendarGenerator.formatDateTimeForQuery(start.toUtc())}" end="${ICalendarGenerator.formatDateTimeForQuery(end.toUtc())}"/>
      </C:comp-filter>
    </C:comp-filter>
  </C:filter>
</C:calendar-query>''';

    try {
      final calendarUrl = _getCalendarUrl(calendarName ?? '');

      final client = http.Client();

      final request = http.Request('REPORT', Uri.parse(calendarUrl));
      request.headers['Authorization'] = _authHeader;

      // For Google Calendar, add all custom headers
      if (customAuthHeaders != null) {
        request.headers.addAll(customAuthHeaders!);
      }

      request.headers['Content-Type'] = 'application/xml; charset=utf-8';
      request.headers['Depth'] = '1';
      request.body = reportBody;

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      client.close();

      if (response.statusCode == 207) {
        return _parseCalendarEvents(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('caldav.auth_failed'.tr());
      } else if (response.statusCode == 404) {
        throw Exception('caldav.calendar_not_found'.tr());
      } else {
        throw Exception(
          'caldav.failed_to_fetch_events'.tr([response.statusCode.toString()]),
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('caldav.connection_error_'.tr([e.toString()]));
    }
  }

  List<CalendarEvent> _parseCalendarEvents(String xmlResponse) {
    final events = <CalendarEvent>[];

    // Split by BEGIN:VCALENDAR to get individual calendar entries
    final calendarBlocks = xmlResponse.split('BEGIN:VCALENDAR');

    for (var i = 1; i < calendarBlocks.length; i++) {
      // Reconstruct full iCalendar content
      final icalContent =
          'BEGIN:VCALENDAR${calendarBlocks[i].split('END:VCALENDAR')[0]}END:VCALENDAR';

      // Use ICalendarParser to parse
      final entry = ICalendarParser.parse(icalContent);

      if (entry != null) {
        // Convert DiaryEntry to CalendarEvent
        events.add(
          CalendarEvent(
            uid: entry.id,
            summary: entry.title,
            description: entry.description,
            dtstart: entry.dtstart,
            dtstamp: entry.dtstamp,
            mood: entry.mood,
            location: entry.location,
            timezone: entry.timezone,
            appendDates: entry.appendDates,
            appendMoods: entry.appendMoods,
            appendLocations: entry.appendLocations,
            appendLatitudes: entry.appendLatitudes,
            appendLongitudes: entry.appendLongitudes,
          ),
        );
      }
    }

    return events;
  }

  /// List all available calendars on the CalDAV server
  Future<List<CalendarInfo>> listCalendars() async {
    // Validate URL exists and is not empty
    if (url.isEmpty) {
      logger.debug('CalDAV: Cannot list calendars - URL is empty');
      return [];
    }

    if (username.isEmpty) {
      logger.debug('CalDAV: Cannot list calendars - username is empty');
      return [];
    }

    try {
      // Parse and validate URL
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        logger.debug(
          'CalDAV: Cannot list calendars - invalid URL format: $url',
        );
        return [];
      }

      // Construct the calendar list URL
      // Two possible formats:
      // 1. Full URL: https://server/remote.php/dav/calendars/username/calendarname/
      // 2. Base URL: https://server/remote.php/dav (we add /calendars/username/)

      String userCalendarsUrl;
      final pathSegments = uri.pathSegments;
      final calendarsIndex = pathSegments.indexOf('calendars');

      if (calendarsIndex != -1 && calendarsIndex + 1 < pathSegments.length) {
        userCalendarsUrl =
            '${uri.scheme}://${uri.host}${uri.port != 0 && uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}/${pathSegments.take(calendarsIndex + 2).join('/')}/';
      } else {
        // Base URL - construct the full path with username
        final basePath = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
        userCalendarsUrl =
            '${uri.scheme}://${uri.host}${uri.port != 0 && uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}${basePath}calendars/$username/';
      }

      logger.debug('CalDAV: Listing calendars from: $userCalendarsUrl');

      final client = http.Client();
      final request = http.Request('PROPFIND', Uri.parse(userCalendarsUrl));
      request.headers['Authorization'] = _authHeader;
      request.headers['Depth'] = '1';
      request.headers['Content-Type'] = 'application/xml; charset=utf-8';
      request.body = '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop>
    <d:displayname/>
    <d:resourcetype/>
  </d:prop>
</d:propfind>''';

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      client.close();

      //logger.debug('CalDAV: PROPFIND status code: ${response.statusCode}');
      //logger.debug('CalDAV: Response length: ${response.body.length} bytes');

      if (response.statusCode != 207) {
        logger.error(
          'CalDAV: Failed to list calendars: ${response.statusCode}',
        );
        logger.debug('CalDAV: Response body: ${response.body}');
        return [];
      }

      // Log first 500 chars of response for debugging
      //final preview = response.body.length > 500
      //    ? response.body.substring(0, 500)
      //    : response.body;
      //logger.debug('CalDAV: Response preview: $preview');

      // Simple XML parsing for calendar names
      final calendars = <CalendarInfo>[];
      final displayNameRegex = RegExp(
        r'<d:displayname>(.*?)</d:displayname>',
        caseSensitive: false,
      );
      final hrefRegex = RegExp(r'<d:href>(.*?)</d:href>', caseSensitive: false);

      final body = response.body;
      final responses = body.split('<d:response>');

      logger.debug(
        'CalDAV: Found ${responses.length - 1} response blocks in XML',
      );

      for (final responseBlock in responses.skip(1)) {
        logger.debug('CalDAV: Processing response block...');

        // Check if this is a calendar - be flexible with namespace prefixes
        // Common formats: <c:calendar/>, <C:calendar/>, <cal:calendar/>, <calendar/>
        final hasCalendarType =
            responseBlock.contains(
              RegExp(r'<[^>]*:?calendar\s*/>', caseSensitive: false),
            ) ||
            responseBlock.contains(
              RegExp(r'<[^>]*:?calendar>', caseSensitive: false),
            );

        logger.debug('CalDAV: Has calendar type: $hasCalendarType');

        if (!hasCalendarType) {
          // This might be the parent folder or another resource type
          logger.debug('CalDAV: Skipping non-calendar resource');
          continue;
        }

        final displayNameMatch = displayNameRegex.firstMatch(responseBlock);
        final hrefMatch = hrefRegex.firstMatch(responseBlock);

        if (displayNameMatch != null && hrefMatch != null) {
          final name = displayNameMatch.group(1) ?? '';
          final href = hrefMatch.group(1) ?? '';
          final calendarName = href.split('/').where((s) => s.isNotEmpty).last;

          logger.debug(
            'CalDAV: Found calendar - name: "$name", id: "$calendarName"',
          );

          if (name.isNotEmpty && calendarName.isNotEmpty) {
            calendars.add(
              CalendarInfo(
                id: calendarName,
                name: name,
                provider: CalendarProvider.caldav,
              ),
            );
          }
        }
      }

      logger.debug('CalDAV: Found ${calendars.length} calendars');
      return calendars;
    } catch (e) {
      logger.debug('CalDAV: Error listing calendars: $e');
      return [];
    }
  }
}

class CalendarEvent {
  final String uid;
  final String summary;
  final String? description;
  final DateTime dtstart;
  final DateTime? dtstamp;
  final String? mood;
  final String? location;
  final String timezone;
  final List<DateTime> appendDates;
  final List<String> appendMoods;
  final List<String> appendLocations;
  final List<double?> appendLatitudes;
  final List<double?> appendLongitudes;

  CalendarEvent({
    required this.uid,
    required this.summary,
    this.description,
    required this.dtstart,
    this.dtstamp,
    this.mood,
    this.location,
    this.timezone = 'UTC',
    List<DateTime>? appendDates,
    List<String>? appendMoods,
    List<String>? appendLocations,
    List<double?>? appendLatitudes,
    List<double?>? appendLongitudes,
  }) : appendDates = appendDates ?? [],
       appendMoods = appendMoods ?? [],
       appendLocations = appendLocations ?? [],
       appendLatitudes = appendLatitudes ?? [],
       appendLongitudes = appendLongitudes ?? [];
}
