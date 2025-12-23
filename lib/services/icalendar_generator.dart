import '../models/diary_entry.dart';
import '../constants/timezones.dart';

class ICalendarGenerator {
  // Generate iCalendar format for a diary entry
  // This is the ONLY place where iCalendar format is defined
  static String generate(DiaryEntry entry, {int durationMinutes = 15}) {
    final timezone = entry.timezone;
    final tzData = timezoneOffsets[timezone];

    final buffer = StringBuffer();

    // ========== VCALENDAR HEADER ==========
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('PRODID:-//ec_com//EcCal 1.0//EN');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('CALSCALE:GREGORIAN');

    // ========== VTIMEZONE COMPONENT ==========
    // Include timezone definition - required for TZID references
    if (timezone != 'UTC') {
      buffer.writeln('BEGIN:VTIMEZONE');
      buffer.writeln('TZID:$timezone');

      // STANDARD time component
      buffer.writeln('BEGIN:STANDARD');
      buffer.writeln('DTSTART:19700101T000000');
      buffer.writeln('TZOFFSETFROM:${tzData?.standardOffset ?? '+0000'}');
      buffer.writeln('TZOFFSETTO:${tzData?.standardOffset ?? '+0000'}');
      if (tzData?.standardName != null) {
        buffer.writeln('TZNAME:${tzData!.standardName}');
      }
      buffer.writeln('END:STANDARD');

      // DAYLIGHT time component (if exists)
      if (tzData?.daylightOffset != null) {
        buffer.writeln('BEGIN:DAYLIGHT');
        buffer.writeln('DTSTART:19700101T000000');
        buffer.writeln('TZOFFSETFROM:${tzData!.standardOffset}');
        buffer.writeln('TZOFFSETTO:${tzData.daylightOffset}');
        if (tzData.daylightName != null) {
          buffer.writeln('TZNAME:${tzData.daylightName}');
        }
        buffer.writeln('END:DAYLIGHT');
      }

      buffer.writeln('END:VTIMEZONE');
    }

    // ========== VEVENT ==========
    buffer.writeln('BEGIN:VEVENT');

    // UID
    buffer.writeln('UID:${entry.id}');

    // CLASS
    buffer.writeln('CLASS:CONFIDENTIAL');

    // STATUS
    buffer.writeln('STATUS:CONFIRMED');

    // TRANSP
    buffer.writeln('TRANSP:TRANSPARENT');

    // DTSTAMP (last modified) - Always UTC with Z suffix per RFC 5545
    buffer.writeln('DTSTAMP:${formatICalDateTime(entry.dtstamp)}');

    // DTSTART (event creation) - Use local time with TZID
    if (timezone == 'UTC') {
      // For UTC timezone, use Z suffix
      buffer.writeln('DTSTART:${formatICalDateTime(entry.dtstart)}');
    } else {
      // For non-UTC timezones, use TZID parameter
      buffer.writeln(
        'DTSTART;TZID=$timezone:${formatICalDateTime(entry.dtstart, useLocal: true)}',
      );
    }

    // DURATION
    buffer.writeln('DURATION:PT${durationMinutes}M');

    // X-MOOD (primary mood)
    buffer.writeln('X-MOOD:${entry.mood}');

    // LOCATION (primary location)
    if (entry.location != null && entry.location!.isNotEmpty) {
      buffer.writeln('LOCATION:${entry.location}');
    }

    // GEO (primary GPS coordinates - right after location)
    if (entry.latitude != null && entry.longitude != null) {
      buffer.writeln('GEO:${entry.latitude};${entry.longitude}');
    }

    // Append data - grouped together (X-APPENDDATE, X-APPENDMOOD, X-APPENDLOC, X-APPENDGEO)
    for (int i = 0; i < entry.appendDates.length; i++) {
      final appendIndex = i + 1; // 1-based indexing for readability

      // X-APPENDDATE with TZID
      if (timezone == 'UTC') {
        // For UTC timezone, use Z suffix
        buffer.writeln(
          'X-APPENDDATE;INDEX=$appendIndex:${formatICalDateTime(entry.appendDates[i])}',
        );
      } else {
        // For non-UTC timezones, use TZID parameter
        buffer.writeln(
          'X-APPENDDATE;INDEX=$appendIndex;TZID=$timezone:${formatICalDateTime(entry.appendDates[i], useLocal: true)}',
        );
      }

      // X-APPENDMOOD for this append (use index to match)
      if (i < entry.appendMoods.length) {
        buffer.writeln(
          'X-APPENDMOOD;INDEX=$appendIndex:${entry.appendMoods[i]}',
        );
      } else {
        buffer.writeln(
          'X-APPENDMOOD;INDEX=$appendIndex:neutral',
        ); // Default if missing
      }

      // X-APPENDLOC for this append - only if location provided
      if (i < entry.appendLocations.length &&
          entry.appendLocations[i].isNotEmpty) {
        buffer.writeln(
          'X-APPENDLOC;INDEX=$appendIndex:${entry.appendLocations[i]}',
        );
      }

      // X-APPENDGEO for this append - only if both lat/lng provided
      if (i < entry.appendLatitudes.length &&
          i < entry.appendLongitudes.length &&
          entry.appendLatitudes[i] != null &&
          entry.appendLongitudes[i] != null) {
        buffer.writeln(
          'X-APPENDGEO;INDEX=$appendIndex:${entry.appendLatitudes[i]};${entry.appendLongitudes[i]}',
        );
      }
    }

    // CATEGORIES
    final allCategories = [...entry.categories];
    if (allCategories.isNotEmpty) {
      buffer.writeln('CATEGORIES:${allCategories.join(',')}');
    }

    // SUMMARY
    buffer.writeln('SUMMARY:${entry.title}');

    // DESCRIPTION
    // Escape special characters - must escape backslashes first, then use those escaped backslashes in other escapes
    final escapedDescription = entry.description
        .replaceAll('\\', '\\\\') // Escape existing backslashes first
        .replaceAll(
          '\n',
          '\\n',
        ) // Then escape newlines (this creates a backslash from us, not user)
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;');
    buffer.writeln('DESCRIPTION:$escapedDescription');

    // ATTACH
    if (entry.attachments.isNotEmpty) {
      for (final attachment in entry.attachments) {
        buffer.writeln('ATTACH:$attachment');
      }
    }

    buffer.writeln('END:VEVENT');
    buffer.writeln('END:VCALENDAR');

    return buffer.toString();
  }

  // Format DateTime to iCalendar format
  // If useLocal is false (default), converts to UTC with Z suffix
  // If useLocal is true, keeps the time as-is without Z (for use with TZID)
  static String formatICalDateTime(DateTime dt, {bool useLocal = false}) {
    final time = useLocal ? dt : dt.toUtc();
    final formatted =
        '${time.year.toString().padLeft(4, '0')}'
        '${time.month.toString().padLeft(2, '0')}'
        '${time.day.toString().padLeft(2, '0')}'
        'T'
        '${time.hour.toString().padLeft(2, '0')}'
        '${time.minute.toString().padLeft(2, '0')}'
        '${time.second.toString().padLeft(2, '0')}';
    return useLocal ? formatted : '${formatted}Z'; // Only append Z for UTC
  }

  // Format DateTime for CalDAV XML queries (YYYYMMDDTHHMMSS)
  // Always UTC, no Z suffix
  static String formatDateTimeForQuery(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year}${utc.month.toString().padLeft(2, '0')}${utc.day.toString().padLeft(2, '0')}'
        'T${utc.hour.toString().padLeft(2, '0')}${utc.minute.toString().padLeft(2, '0')}${utc.second.toString().padLeft(2, '0')}';
  }
}
