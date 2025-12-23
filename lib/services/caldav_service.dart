import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/diary_entry.dart';
import '../services/icalendar_generator.dart';
import '../services/logger_service.dart';
import '../utils/app_localizations.dart';

class CalDAVService {
  final String url;
  final String username;
  final String password;

  CalDAVService({
    required this.url,
    required this.username,
    required this.password,
  });

  String get _authHeader {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return 'Basic $credentials';
  }

  // Test connection to CalDAV server
  Future<Map<String, dynamic>> testConnection() async {
    if (url.isEmpty) {
      return {
        'success': false,
        'error': 'caldav.url_not_configured'.tr(),
      };
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
        return {
          'success': false,
          'error': 'caldav.auth_failed'.tr(),
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'caldav.url_not_found'.tr(),
        };
      } else {
        return {
          'success': false,
          'error': 'caldav.server_status'.tr([response.statusCode.toString()]),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'caldav.connection_failed'.tr([e.toString()]),
      };
    }
  }

  // Setup calendar: test connection, check if calendar exists, create if needed
  Future<Map<String, dynamic>> setupCalendar(String calendarName) async {
    // Step 1: Test connection
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

    // Step 2: Check if calendar exists
    logger.info('Checking if calendar "$calendarName" exists...');
    final exists = await calendarExists(calendarName);
    
    if (exists) {
      logger.info('Calendar "$calendarName" already exists');
      return {
        'success': true,
        'step': 'complete',
        'message': 'caldav.calendar_ready'.tr([calendarName]),
        'created': false,
      };
    }

    // Step 3: Create calendar
    logger.info('Calendar does not exist, creating...');
    final created = await createCalendar(calendarName);
    
    if (created) {
      logger.info('Calendar "$calendarName" created successfully');
      return {
        'success': true,
        'step': 'complete',
        'message': 'caldav.calendar_created'.tr([calendarName]),
        'created': true,
      };
    } else {
      return {
        'success': false,
        'step': 'creation',
        'error': 'caldav.failed_to_create_calendar'.tr(),
      };
    }
  }

  // Check if a calendar exists
  Future<bool> calendarExists(String calendarName) async {
    if (url.isEmpty) return false;
    
    try {
      // Try to access the calendar
      final calendarUrl = _getCalendarUrl(calendarName);
      final client = http.Client();
      
      final request = http.Request('PROPFIND', Uri.parse(calendarUrl));
      request.headers['Authorization'] = _authHeader;
      request.headers['Depth'] = '0';
      
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      client.close();
      
      return response.statusCode == 207 || response.statusCode == 200;
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
      final body = '''<?xml version="1.0" encoding="utf-8"?>
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
        logger.info('Failed to create calendar: ${response.statusCode} ${response.body}');
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
    // Remove trailing slash from URL if present
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

    final icsContent = ICalendarGenerator.generate(entry, durationMinutes: durationMinutes);

    try {
      final calendarUrl = _getCalendarUrl(calendarName);
      final eventUrl = '$calendarUrl${entry.id}.ics';
      final response = await http.put(
        Uri.parse(eventUrl),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'text/calendar; charset=utf-8',
          'If-None-Match': '*',
        },
        body: icsContent,
      );

      if (response.statusCode != 201 && response.statusCode != 204) {
        logger.info('Failed to create event: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      logger.info('CalDAV error: $e');
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

    final icsContent = ICalendarGenerator.generate(entry, durationMinutes: durationMinutes);

    try {
      final calendarUrl = _getCalendarUrl(calendarName);
      final eventUrl = '$calendarUrl${entry.id}.ics';
      final response = await http.put(
        Uri.parse(eventUrl),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'text/calendar; charset=utf-8',
        },
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
        headers: {
          'Authorization': _authHeader,
        },
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

    // If no calendar name provided, throw error
    if (calendarName == null || calendarName.isEmpty) {
      throw Exception('caldav.no_calendar_name'.tr());
    }

    // Check if calendar exists first
    final exists = await calendarExists(calendarName);
    if (!exists) {
      throw Exception('caldav.calendar_not_exist'.tr([calendarName]));
    }

    final start = startDate ?? DateTime.now().subtract(const Duration(days: 365));
    final end = endDate ?? DateTime.now().add(const Duration(days: 365));

    final reportBody = '''<?xml version="1.0" encoding="utf-8" ?>
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
      final calendarUrl = _getCalendarUrl(calendarName);
      final client = http.Client();
      
      final request = http.Request('REPORT', Uri.parse(calendarUrl));
      request.headers['Authorization'] = _authHeader;
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
        throw Exception('caldav.failed_to_fetch_events'.tr([response.statusCode.toString()]));
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('caldav.connection_error'.tr([e.toString()]));
    }
  }

  List<CalendarEvent> _parseCalendarEvents(String xmlResponse) {
    final events = <CalendarEvent>[];
    final eventBlocks = xmlResponse.split('BEGIN:VEVENT');
    
    for (var i = 1; i < eventBlocks.length; i++) {
      final block = eventBlocks[i].split('END:VEVENT')[0];
      events.add(_parseEventBlock(block));
    }
    
    return events;
  }

  CalendarEvent _parseEventBlock(String block) {
    String? uid, summary, description, mood, location;
    DateTime? dtstart, dtstamp;
    final appendDates = <DateTime>[];
    final appendMoods = <String>[];
    final appendLocations = <String>[];
    final appendLatitudes = <double?>[];
    final appendLongitudes = <double?>[];
    
    // Temporary storage for grouping by index
    final appendData = <int, Map<String, dynamic>>{};
    
    final lines = block.split('\n');
    for (final line in lines) {
      if (line.startsWith('UID:')) {
        uid = line.substring(4).trim();
      } else if (line.startsWith('SUMMARY:')) {
        summary = _unescapeText(line.substring(8).trim());
      } else if (line.startsWith('DESCRIPTION:')) {
        description = _unescapeText(line.substring(12).trim());
      } else if (line.startsWith('DTSTAMP:') || line.contains('DTSTAMP;')) {
        // Extract DTSTAMP (last modified timestamp)
        final parts = line.split(':');
        if (parts.length >= 2) {
          dtstamp = _parseDateTime(parts.last.trim());
        }
      } else if (line.startsWith('X-MOOD:')) {
        mood = line.substring(7).trim();
      } else if (line.startsWith('LOCATION:')) {
        location = _unescapeText(line.substring(9).trim());
      } else if (line.startsWith('DTSTART:')) {
        dtstart = _parseDateTime(line.substring(8).trim());
      } else if (line.startsWith('X-APPENDDATE:')) {
        // Format: X-APPENDDATE:1;20251227T131608Z
        final content = line.substring(13).trim();
        final parts = content.split(';');
        if (parts.length == 2) {
          final index = int.tryParse(parts[0]);
          final dateTime = _parseDateTime(parts[1]);
          if (index != null) {
            appendData.putIfAbsent(index, () => {});
            appendData[index]!['date'] = dateTime;
          }
        }
      } else if (line.startsWith('X-APPENDMOOD:')) {
        // Format: X-APPENDMOOD:1;happy
        final content = line.substring(13).trim();
        final parts = content.split(';');
        if (parts.length == 2) {
          final index = int.tryParse(parts[0]);
          if (index != null) {
            appendData.putIfAbsent(index, () => {});
            appendData[index]!['mood'] = parts[1];
          }
        }
      } else if (line.startsWith('X-APPENDLOC:')) {
        // Format: X-APPENDLOC:1;Coffee Shop
        final content = line.substring(12).trim();
        final parts = content.split(';');
        if (parts.length >= 2) {
          final index = int.tryParse(parts[0]);
          if (index != null) {
            appendData.putIfAbsent(index, () => {});
            // Join back in case location had semicolons
            appendData[index]!['location'] = parts.sublist(1).join(';');
          }
        }
      } else if (line.startsWith('X-APPENDGEO:')) {
        // Format: X-APPENDGEO:1;40.712776;-74.005974
        final content = line.substring(12).trim();
        final parts = content.split(';');
        if (parts.length == 3) {
          final index = int.tryParse(parts[0]);
          final lat = double.tryParse(parts[1]);
          final lng = double.tryParse(parts[2]);
          if (index != null) {
            appendData.putIfAbsent(index, () => {});
            appendData[index]!['latitude'] = lat;
            appendData[index]!['longitude'] = lng;
          }
        }
      }
    }
    
    // Convert grouped data to lists, sorted by index
    final sortedIndices = appendData.keys.toList()..sort();
    for (final index in sortedIndices) {
      final data = appendData[index]!;
      appendDates.add(data['date'] ?? DateTime.now());
      appendMoods.add(data['mood'] ?? 'neutral');
      appendLocations.add(data['location'] ?? '');
      appendLatitudes.add(data['latitude']);
      appendLongitudes.add(data['longitude']);
    }
    
    return CalendarEvent(
      uid: uid ?? '',
      summary: summary ?? 'caldav.untitled'.tr(),
      description: description,
      dtstart: dtstart ?? DateTime.now(),
      dtstamp: dtstamp,
      mood: mood,
      location: location,
      appendDates: appendDates,
      appendMoods: appendMoods,
      appendLocations: appendLocations,
      appendLatitudes: appendLatitudes,
      appendLongitudes: appendLongitudes,
    );
  }

  DateTime _parseDateTime(String icsDate) {
    if (icsDate.length < 15) return DateTime.now();
    
    try {
      final year = int.parse(icsDate.substring(0, 4));
      final month = int.parse(icsDate.substring(4, 6));
      final day = int.parse(icsDate.substring(6, 8));
      final hour = int.parse(icsDate.substring(9, 11));
      final minute = int.parse(icsDate.substring(11, 13));
      final second = int.parse(icsDate.substring(13, 15));
      
      return DateTime.utc(year, month, day, hour, minute, second);
    } catch (e) {
      return DateTime.now();
    }
  }

  String _unescapeText(String text) {
    return text
        .replaceAll('\\n', '\n')
        .replaceAll('\\,', ',')
        .replaceAll('\\;', ';')
        .replaceAll('\\\\', '\\');
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
    List<DateTime>? appendDates,
    List<String>? appendMoods,
    List<String>? appendLocations,
    List<double?>? appendLatitudes,
    List<double?>? appendLongitudes,
  })  : appendDates = appendDates ?? [],
        appendMoods = appendMoods ?? [],
        appendLocations = appendLocations ?? [],
        appendLatitudes = appendLatitudes ?? [],
        appendLongitudes = appendLongitudes ?? [];
}