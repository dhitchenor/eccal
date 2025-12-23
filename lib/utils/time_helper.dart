import '../constants/timezones.dart';
import '../constants/times.dart';
import '../utils/app_localizations.dart';

// TIMEZONE HELPERS
// ============================================================================

// Common timezones for UI dropdown with category headers.
// AUTO-GENERATED from timezoneOffsets map in timezones.dart
// Headers are marked with '---' prefix and suffix for visual organization.
final List<String> commonTimezones = _generateTimezoneList();

// Generate UI timezone list from timezoneOffsets map
// Groups timezones by region and adds category headers
List<String> _generateTimezoneList() {
  final list = <String>[];
  
  // UTC first
  list.add('UTC');
  
  // Group by region
  final regions = {
    'timezones.africa'.tr(): <String>[],
    'timezones.americas'.tr(): <String>[],
    'timezones.asia'.tr(): <String>[],
    'timezones.atlantic'.tr(): <String>[],
    'timezones.australia'.tr(): <String>[],
    'timezones.europe'.tr(): <String>[],
    'timezones.pacific'.tr(): <String>[],
  };
  
  // Sort timezones into regions
  for (final tzid in timezoneOffsets.keys) {
    if (tzid == 'UTC') continue;
    
    if (tzid.startsWith('Africa/')) {
      regions['timezones.africa'.tr()]!.add(tzid);
    } else if (tzid.startsWith('America/')) {
      regions['timezones.americas'.tr()]!.add(tzid);
    } else if (tzid.startsWith('Asia/')) {
      regions['timezones.asia'.tr()]!.add(tzid);
    } else if (tzid.startsWith('Atlantic/')) {
      regions['timezones.atlantic'.tr()]!.add(tzid);
    } else if (tzid.startsWith('Australia/')) {
      regions['timezones.australia'.tr()]!.add(tzid);
    } else if (tzid.startsWith('Europe/')) {
      regions['timezones.europe'.tr()]!.add(tzid);
    } else if (tzid.startsWith('Pacific/')) {
      regions['timezones.pacific'.tr()]!.add(tzid);
    }
  }
  
  // Add regions with headers
  for (final entry in regions.entries) {
    if (entry.value.isNotEmpty) {
      list.add('--- ${entry.key} ---');
      entry.value.sort(); // Alphabetical WITHIN region
      list.addAll(entry.value);
    }
  }
  
  return list;
}

// TIME FORMATTING HELPERS
// ============================================================================
extension TimeNames on int {
  String getFullMonth() {
    if (this < 1 || this > 12) {
      throw ArgumentError('Month must be between 1 and 12');
    }
    return MonthNames.fullMonth[this - 1];
  }

  String getAbbreviatedMonth() {
    if (this < 1 || this > 12) {
      throw ArgumentError('Month must be between 1 and 12');
    }
    return MonthNames.abbreviatedMonth[this - 1];
  }

  String getFullWeekday() {
    if (this < 1 || this > 7) {
      throw ArgumentError('Weekday must be between 1 and 7');
    }
    return WeekdayNames.fullWeekday[this - 1];
  }

  String getAbbreviatedWeekday() {
    if (this < 1 || this > 7) {
      throw ArgumentError('Weekday must be between 1 and 7');
    }
    return WeekdayNames.abbreviatedWeekday[this - 1];
  }
}

String formatDuration(int count, String unit, {bool abbreviated = false}) {
  Map<String, String> unitMap;
  
  if (count == 1) {
    unitMap = abbreviated ? timeNames.abbreviatedTimeMap : timeNames.fullTimeMap;
  } else {
    unitMap = abbreviated ? timeNames.abbreviatedTimesMap : timeNames.fullTimesMap;
  }
  
  return '$count ${unitMap[unit] ?? unit}';
}