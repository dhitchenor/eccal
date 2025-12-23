import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calendar_info.dart';
import '../services/caldav_service.dart';
import '../services/logger_service.dart';
import '../providers/settings_provider.dart';

// Apple Calendar (iCloud) service
// Handles iCloud-specific CalDAV URL discovery and operations
//
// iCloud uses a different URL structure than standard CalDAV:
// - Base: https://caldav.icloud.com
// - Calendar Home: https://caldav.icloud.com/<unique-id>/calendars/
class AppleCalendarService {
  final String baseUrl = 'https://caldav.icloud.com';
  final String username; // Apple ID email
  final String password; // App-specific password

  String? _calendarHomeUrl; // Discovered calendar home URL
  CalDAVService? _caldavService; // Underlying CalDAV service

  AppleCalendarService({required this.username, required this.password});

  // Test connection to iCloud CalDAV server
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final client = http.Client();
      final request = http.Request('PROPFIND', Uri.parse(baseUrl));
      request.headers['Authorization'] = _getAuthHeader();
      request.headers['Depth'] = '0';

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      client.close();

      if (response.statusCode == 207 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Connected to iCloud CalDAV successfully',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error':
              'Authentication failed - check Apple ID and app-specific password',
        };
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Discover the calendar home URL for this iCloud account
  Future<String?> discoverCalendarHomeUrl() async {
    if (_calendarHomeUrl != null) {
      return _calendarHomeUrl; // Already discovered
    }

    try {
      logger.debug('Apple Calendar: Discovering calendar home URL...');

      // Step 1: Get current-user-principal
      final principalUrl = await _discoverPrincipalUrl();
      if (principalUrl == null) {
        logger.error('Apple Calendar: Failed to discover principal URL');
        return null;
      }

      logger.debug('Apple Calendar: Principal URL: $principalUrl');

      // Step 2: Get calendar-home-set from principal
      final calendarHomeUrl = await _discoverCalendarHomeSet(principalUrl);
      if (calendarHomeUrl == null) {
        logger.error('Apple Calendar: Failed to discover calendar home URL');
        return null;
      }

      logger.info('Apple Calendar: Calendar home URL: $calendarHomeUrl');
      _calendarHomeUrl = calendarHomeUrl;

      // Create CalDAV service with the correct URL
      _caldavService = CalDAVService(
        url: calendarHomeUrl,
        username: username,
        password: password,
      );

      return _calendarHomeUrl;
    } catch (e) {
      logger.error('Apple Calendar: Error discovering calendar home: $e');
      return null;
    }
  }

  // Step 1: Discover the current-user-principal URL
  Future<String?> _discoverPrincipalUrl() async {
    try {
      final client = http.Client();
      final request = http.Request('PROPFIND', Uri.parse(baseUrl));
      request.headers['Authorization'] = _getAuthHeader();
      request.headers['Depth'] = '0';
      request.headers['Content-Type'] = 'application/xml; charset=utf-8';
      request.body = '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:current-user-principal/>
  </d:prop>
</d:propfind>''';

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      client.close();

      logger.debug(
        'Apple Calendar: Principal discovery status: ${response.statusCode}',
      );

      if (response.statusCode != 207) {
        logger.error(
          'Apple Calendar: Principal discovery failed: ${response.statusCode}',
        );
        logger.debug('Apple Calendar: Response body: ${response.body}');
        return null;
      }

      // Parse the principal URL from the response
      final principalUrl = _extractPrincipalUrl(response.body);

      if (principalUrl == null) {
        logger.error(
          'Apple Calendar: Could not extract principal URL from response',
        );
        logger.debug('Apple Calendar: Full response: ${response.body}');
      }

      return principalUrl;
    } catch (e) {
      logger.error('Apple Calendar: Error discovering principal: $e');
      return null;
    }
  }

  // Step 2: Discover the calendar-home-set from the principal URL
  Future<String?> _discoverCalendarHomeSet(String principalUrl) async {
    try {
      // Make sure the URL is absolute
      final fullPrincipalUrl = principalUrl.startsWith('http')
          ? principalUrl
          : '$baseUrl$principalUrl';

      final client = http.Client();
      final request = http.Request('PROPFIND', Uri.parse(fullPrincipalUrl));
      request.headers['Authorization'] = _getAuthHeader();
      request.headers['Depth'] = '0';
      request.headers['Content-Type'] = 'application/xml; charset=utf-8';
      request.body = '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop>
    <c:calendar-home-set/>
  </d:prop>
</d:propfind>''';

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      client.close();

      if (response.statusCode != 207) {
        logger.error(
          'Apple Calendar: Calendar home discovery failed: ${response.statusCode}',
        );
        return null;
      }

      // Parse the calendar home URL from the response
      final calendarHomeUrl = _extractCalendarHomeUrl(response.body);

      // Remove trailing slash to prevent double slashes in CalDAV service
      if (calendarHomeUrl != null && calendarHomeUrl.endsWith('/')) {
        return calendarHomeUrl.substring(0, calendarHomeUrl.length - 1);
      }

      return calendarHomeUrl;
    } catch (e) {
      logger.error('Apple Calendar: Error discovering calendar home: $e');
      return null;
    }
  }

  // Extract the current-user-principal URL from PROPFIND response
  String? _extractPrincipalUrl(String xmlResponse) {
    // iCloud returns <current-user-principal><href>/path/</href></current-user-principal>
    // Look for href tag with or without namespace prefix
    final patterns = [
      // With d: prefix
      RegExp(
        r'<d:current-user-principal[^>]*>.*?<d:href[^>]*>(.*?)</d:href>',
        caseSensitive: false,
        dotAll: true,
      ),
      // Without prefix (iCloud format)
      RegExp(
        r'<current-user-principal[^>]*>.*?<href[^>]*>(.*?)</href>',
        caseSensitive: false,
        dotAll: true,
      ),
    ];

    for (final regex in patterns) {
      final match = regex.firstMatch(xmlResponse);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }

  /// Extract the calendar-home-set URL from PROPFIND response
  String? _extractCalendarHomeUrl(String xmlResponse) {
    // Look for <c:calendar-home-set><d:href>URL</d:href></c:calendar-home-set>
    // Also try <calendar-home-set> without namespace prefix
    final patterns = [
      RegExp(
        r'<c:calendar-home-set[^>]*>.*?<d:href[^>]*>(.*?)</d:href>',
        caseSensitive: false,
        dotAll: true,
      ),
      RegExp(
        r'<calendar-home-set[^>]*>.*?<href[^>]*>(.*?)</href>',
        caseSensitive: false,
        dotAll: true,
      ),
    ];

    for (final regex in patterns) {
      final match = regex.firstMatch(xmlResponse);
      if (match != null) {
        final url = match.group(1)?.trim();
        if (url != null && url.isNotEmpty) {
          // Make sure URL is absolute
          return url.startsWith('http') ? url : '$baseUrl$url';
        }
      }
    }

    return null;
  }

  // List calendars from iCloud
  Future<List<CalendarInfo>> listCalendars() async {
    // Ensure calendar home URL is discovered
    final calendarHomeUrl = await discoverCalendarHomeUrl();
    if (calendarHomeUrl == null) {
      logger.error(
        'Apple Calendar: Cannot list calendars - home URL not discovered',
      );
      return [];
    }

    // For iCloud, we need to list directly from the calendar home URL
    // Don't use CalDAV service's listCalendars as it manipulates the URL
    try {
      logger.debug('Apple Calendar: Listing calendars from: $calendarHomeUrl/');

      final client = http.Client();
      final request = http.Request('PROPFIND', Uri.parse('$calendarHomeUrl/'));
      request.headers['Authorization'] = _getAuthHeader();
      request.headers['Depth'] = '1';
      request.headers['Content-Type'] = 'application/xml; charset=utf-8';
      request.body = '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop>
    <d:displayname/>
    <d:resourcetype/>
    <c:supported-calendar-component-set/>
  </d:prop>
</d:propfind>''';

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      client.close();

      if (response.statusCode != 207) {
        logger.error(
          'Apple Calendar: Failed to list calendars: ${response.statusCode}',
        );
        logger.debug('Apple Calendar: Response: ${response.body}');
        return [];
      }

      // Parse the calendar list
      final calendars = _parseCalendarList(response.body, calendarHomeUrl);
      logger.info('Apple Calendar: Found ${calendars.length} calendars');

      // Also create the CalDAV service for later use
      if (_caldavService == null) {
        _caldavService = CalDAVService(
          url: calendarHomeUrl,
          username: username,
          password: password,
        );
      }

      return calendars;
    } catch (e) {
      logger.error('Apple Calendar: Error listing calendars: $e');
      return [];
    }
  }

  // Parse calendar list from PROPFIND response
  List<CalendarInfo> _parseCalendarList(String xmlResponse, String baseUrl) {
    final calendars = <CalendarInfo>[];

    // Split by <response> tags
    final responsePattern = RegExp(
      r'<(?:d:)?response[^>]*>(.*?)</(?:d:)?response>',
      caseSensitive: false,
      dotAll: true,
    );

    final responses = responsePattern.allMatches(xmlResponse);

    for (final match in responses) {
      final responseXml = match.group(1) ?? '';

      // Extract href (calendar path)
      final hrefPattern = RegExp(
        r'<(?:d:)?href[^>]*>(.*?)</(?:d:)?href>',
        caseSensitive: false,
      );
      final hrefMatch = hrefPattern.firstMatch(responseXml);
      final href = hrefMatch?.group(1)?.trim();

      if (href == null ||
          href.isEmpty ||
          href == baseUrl ||
          href == '$baseUrl/' ||
          href.endsWith('/calendars/')) {
        continue; // Skip the base collection itself and calendars root
      }

      // Check for supported components
      final supportsVEVENT = responseXml.contains('VEVENT');

      // Check for special resource types (inbox, outbox, notification)
      final isInbox =
          responseXml.contains('schedule-inbox') ||
          responseXml.toLowerCase().contains('inbox');
      final isOutbox =
          responseXml.contains('schedule-outbox') ||
          responseXml.toLowerCase().contains('outbox');
      final isNotification =
          responseXml.contains('notification') ||
          responseXml.toLowerCase().contains('notification');

      // FILTER: Only include calendars that:
      // 1. Support VEVENT (events) - exclude task-only calendars
      // 2. Are NOT system calendars (inbox, outbox, notification)
      if (!supportsVEVENT || isInbox || isOutbox || isNotification) {
        continue; // Skip non-event calendars and system calendars
      }

      // Extract display name
      final namePattern = RegExp(
        r'<(?:d:)?displayname[^>]*>(.*?)</(?:d:)?displayname>',
        caseSensitive: false,
        dotAll: true,
      );
      final nameMatch = namePattern.firstMatch(responseXml);
      final displayName =
          nameMatch?.group(1)?.trim() ??
          href.split('/').where((s) => s.isNotEmpty).last;

      // Extract calendar name from href (last path segment)
      final calendarName = href.split('/').where((s) => s.isNotEmpty).last;

      logger.debug(
        'Apple Calendar: Found calendar - name: "$displayName", id: "$calendarName"',
      );

      calendars.add(
        CalendarInfo(
          id: calendarName,
          name: displayName,
          provider: CalendarProvider.apple,
        ),
      );
    }

    logger.debug('Apple Calendar: Found ${calendars.length} calendars');
    return calendars;
  }

  // Create a new calendar on iCloud
  Future<bool> createCalendar(String calendarName) async {
    // Ensure calendar home URL is discovered
    final calendarHomeUrl = await discoverCalendarHomeUrl();
    if (calendarHomeUrl == null || _caldavService == null) {
      logger.error(
        'Apple Calendar: Cannot create calendar - home URL not discovered',
      );
      return false;
    }

    // Use the underlying CalDAV service to create calendar
    try {
      final result = await _caldavService!.createCalendar(calendarName);
      if (result) {
        logger.info('Apple Calendar: Created calendar "$calendarName"');
      }
      return result;
    } catch (e) {
      logger.error('Apple Calendar: Error creating calendar: $e');
      return false;
    }
  }

  // Get the CalDAV service instance (after discovery)
  // This can be used for diary operations
  CalDAVService? getCalDAVService() {
    return _caldavService;
  }

  // Get the discovered calendar home URL
  String? getCalendarHomeUrl() {
    return _calendarHomeUrl;
  }

  // Generate Basic Auth header
  String _getAuthHeader() {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return 'Basic $credentials';
  }
}
