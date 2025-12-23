import '../constants/moods.dart';
import '../models/diary_entry.dart';
import '../services/logger_service.dart';

class ICalendarParser {
  // Parse a complete iCalendar string into a DiaryEntry
  static DiaryEntry? parse(String icalContent) {
    try {
      final lines = icalContent.split('\n').map((l) => l.trim()).toList();

      String? uid;
      String? summary;
      String? description;
      DateTime? dtstart;
      DateTime? dtstamp;
      String? mood;
      String? location;
      double? latitude;
      double? longitude;
      List<String> categories = [];
      List<String> attachments = [];
      String timezone = 'UTC'; // Default timezone

      // Temporary storage for grouping append data by index
      final appendData = <int, Map<String, dynamic>>{};

      bool inVEvent = false;
      bool inVTimezone = false;

      for (final line in lines) {
        // Parse VTIMEZONE component
        if (line == 'BEGIN:VTIMEZONE') {
          inVTimezone = true;
          continue;
        }

        if (line == 'END:VTIMEZONE') {
          inVTimezone = false;
          continue;
        }

        if (inVTimezone && line.startsWith('TZID:')) {
          timezone = line.substring(5).trim();
          continue;
        }

        if (line == 'BEGIN:VEVENT') {
          inVEvent = true;
          continue;
        }

        if (line == 'END:VEVENT') {
          inVEvent = false;
          break;
        }

        if (!inVEvent || !line.contains(':')) continue;

        final colonIndex = line.indexOf(':');
        final key = line.substring(0, colonIndex).trim();
        final value = line.substring(colonIndex + 1).trim();

        // Also check for TZID in properties like DTSTART;TZID=...
        if (timezone == 'UTC' && key.contains('TZID=')) {
          final tzidMatch = RegExp(r'TZID=([^:;]+)').firstMatch(key);
          if (tzidMatch != null) {
            timezone = tzidMatch.group(1)!;
          }
        }

        // Parse X-APPEND properties
        if (line.startsWith('X-APPENDDATE')) {
          final result = _parseAppendDate(key, value, timezone);
          if (result != null) {
            appendData.putIfAbsent(result.index, () => {});
            appendData[result.index]!['date'] = result.dateTime;
          }
          continue;
        }

        if (line.startsWith('X-APPENDMOOD')) {
          final result = _parseAppendMood(key, value);
          if (result != null) {
            appendData.putIfAbsent(result.index, () => {});
            appendData[result.index]!['mood'] = result.value;
          }
          continue;
        }

        if (line.startsWith('X-APPENDLOC')) {
          final result = _parseAppendLocation(key, value);
          if (result != null) {
            appendData.putIfAbsent(result.index, () => {});
            appendData[result.index]!['location'] = result.value;
          }
          continue;
        }

        if (line.startsWith('X-APPENDGEO')) {
          final result = _parseAppendGeo(key, value);
          if (result != null) {
            appendData.putIfAbsent(result.index, () => {});
            appendData[result.index]!['latitude'] = result.latitude;
            appendData[result.index]!['longitude'] = result.longitude;
          }
          continue;
        }

        // Parse standard properties
        switch (key.split(';').first) {
          // Remove parameters like TZID
          case 'UID':
            uid = value;
            break;
          case 'SUMMARY':
            summary = value;
            break;
          case 'DESCRIPTION':
            description = _unescapeText(value);
            break;
          case 'DTSTART':
            dtstart = parseDateTime(value, timezone: timezone);
            break;
          case 'DTSTAMP':
            dtstamp = parseDateTime(value, timezone: timezone);
            break;
          case 'X-MOOD':
            mood = value;
            break;
          case 'LOCATION':
            location = _unescapeText(value);
            break;
          case 'GEO':
            final parts = value.split(';');
            if (parts.length == 2) {
              latitude = double.tryParse(parts[0]);
              longitude = double.tryParse(parts[1]);
            }
            break;
          case 'CATEGORIES':
            categories = value.split(',').map((c) => c.trim()).toList();
            break;
          case 'ATTACH':
            if (value.isNotEmpty) {
              attachments.add(value);
            }
            break;
        }
      }

      // Convert grouped append data to lists, sorted by index
      final appendDates = <DateTime>[];
      final appendMoods = <String>[];
      final appendLocations = <String>[];
      final appendLatitudes = <double?>[];
      final appendLongitudes = <double?>[];

      final sortedIndices = appendData.keys.toList()..sort();
      for (final index in sortedIndices) {
        final data = appendData[index]!;
        appendDates.add(data['date'] ?? DateTime.now());
        appendMoods.add(data['mood'] ?? 'neutral');
        appendLocations.add(data['location'] ?? '');
        appendLatitudes.add(data['latitude']);
        appendLongitudes.add(data['longitude']);
      }

      // Validate required fields
      if (uid == null || summary == null || dtstart == null) {
        logger.error('Missing required fields in iCalendar data');
        return null;
      }

      // Extract mood from X-MOOD property (preferred) or fallback to categories
      if (mood == null && categories.isNotEmpty) {
        final knownMoods = MoodHelper.getAllMoods();
        for (final cat in categories) {
          if (knownMoods.contains(cat.toLowerCase())) {
            mood = cat.toLowerCase();
            categories.remove(cat);
            break;
          }
        }
      }

      return DiaryEntry(
        id: uid,
        title: summary,
        description: description ?? '',
        dtstart: dtstart,
        dtstamp: dtstamp ?? DateTime.now(),
        mood: mood ?? 'neutral',
        location: location,
        latitude: latitude,
        longitude: longitude,
        categories: categories,
        appendDates: appendDates,
        appendMoods: appendMoods,
        appendLocations: appendLocations,
        appendLatitudes: appendLatitudes,
        appendLongitudes: appendLongitudes,
        attachments: attachments,
        timezone: timezone,
      );
    } catch (e) {
      logger.error('Error parsing iCalendar data: $e');
      return null;
    }
  }

  // Parse X-APPENDDATE property
  // Format: X-APPENDDATE;INDEX=1;TZID=Asia/Kolkata:20251227T131608
  // or: X-APPENDDATE;INDEX=1:20251227T131608Z (for UTC)
  static _AppendDateResult? _parseAppendDate(
    String key,
    String value,
    String timezone,
  ) {
    // Extract INDEX parameter
    final indexMatch = RegExp(r'INDEX=(\d+)').firstMatch(key);
    if (indexMatch == null) return null;

    final index = int.tryParse(indexMatch.group(1)!);
    if (index == null) return null;

    final dateTime = parseDateTime(value, timezone: timezone);
    return _AppendDateResult(index, dateTime);
  }

  // Parse X-APPENDMOOD property
  // Format: X-APPENDMOOD;INDEX=1:happy
  static _AppendValueResult? _parseAppendMood(String key, String value) {
    // Extract INDEX parameter
    final indexMatch = RegExp(r'INDEX=(\d+)').firstMatch(key);
    if (indexMatch == null) return null;

    final index = int.tryParse(indexMatch.group(1)!);
    if (index == null || value.isEmpty) return null;

    return _AppendValueResult(index, value);
  }

  // Parse X-APPENDLOC property
  // Format: X-APPENDLOC;INDEX=1:Coffee Shop
  static _AppendValueResult? _parseAppendLocation(String key, String value) {
    // Extract INDEX parameter
    final indexMatch = RegExp(r'INDEX=(\d+)').firstMatch(key);
    if (indexMatch == null) return null;

    final index = int.tryParse(indexMatch.group(1)!);
    if (index == null || value.isEmpty) return null;

    return _AppendValueResult(index, value);
  }

  // Parse X-APPENDGEO property
  // Format: X-APPENDGEO;INDEX=1:40.712776;-74.005974
  static _AppendGeoResult? _parseAppendGeo(String key, String value) {
    // Extract INDEX parameter
    final indexMatch = RegExp(r'INDEX=(\d+)').firstMatch(key);
    if (indexMatch == null) return null;

    final index = int.tryParse(indexMatch.group(1)!);
    if (index == null) return null;

    // Parse coordinates from value
    final coords = value.split(';');
    if (coords.length == 2) {
      final lat = double.tryParse(coords[0]);
      final lng = double.tryParse(coords[1]);
      return _AppendGeoResult(index, lat, lng);
    }

    return _AppendGeoResult(index, null, null);
  }

  // Parse iCalendar DateTime format (YYYYMMDDTHHMMSSZ or YYYYMMDDTHHMMSS)
  // With TZID implementation, times are stored in local timezone
  static DateTime parseDateTime(String value, {String? timezone}) {
    try {
      // Remove the 'Z' at the end if present (UTC times)
      final cleanValue = value.replaceAll('Z', '');

      if (cleanValue.length >= 15) {
        final year = int.parse(cleanValue.substring(0, 4));
        final month = int.parse(cleanValue.substring(4, 6));
        final day = int.parse(cleanValue.substring(6, 8));
        final hour = int.parse(cleanValue.substring(9, 11));
        final minute = int.parse(cleanValue.substring(11, 13));
        final second = int.parse(cleanValue.substring(13, 15));

        if (value.endsWith('Z')) {
          // UTC format (used for UTC timezone and DTSTAMP)
          // Store as local DateTime since we treat all times as local
          return DateTime(year, month, day, hour, minute, second);
        } else {
          // Local time format (used with TZID)
          return DateTime(year, month, day, hour, minute, second);
        }
      }
    } catch (e) {
      logger.error('Error parsing iCal DateTime: $value - $e');
    }
    return DateTime.now();
  }

  // Unescape iCalendar text (reverse of escaping in generator)
  static String _unescapeText(String text) {
    return text
        .replaceAll('\\n', '\n')
        .replaceAll('\\,', ',')
        .replaceAll('\\;', ';')
        .replaceAll('\\\\', '\\');
  }
}

// Helper classes for parsing results
class _AppendDateResult {
  final int index;
  final DateTime dateTime;
  _AppendDateResult(this.index, this.dateTime);
}

class _AppendValueResult {
  final int index;
  final String value;
  _AppendValueResult(this.index, this.value);
}

class _AppendGeoResult {
  final int index;
  final double? latitude;
  final double? longitude;
  _AppendGeoResult(this.index, this.latitude, this.longitude);
}
