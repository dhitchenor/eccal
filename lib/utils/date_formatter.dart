import '../constants/timezones.dart';
import '../utils/app_localizations.dart';
import '../utils/time_helper.dart';

class DateFormatter {
  // Format datetime showing the time in its stored timezone with abbreviation
  // Shows: "Dec 18, 2025 at 15:44 (AST)"
  static String formatDateTime(DateTime dateTime, {bool use24Hour = true, String? timezone}) {
    // Convert to specified timezone
    final localTime = _convertToTimezone(dateTime, timezone);
    
    final month = localTime.month.getAbbreviatedMonth();
    final day = localTime.day;
    final year = localTime.year;
    
    final hour = use24Hour
        ? localTime.hour.toString().padLeft(2, '0')
        : (localTime.hour % 12 == 0 ? 12 : localTime.hour % 12).toString();
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = use24Hour ? '' : (localTime.hour >= 12 ? ' ${'pm'.tr().toUpperCase()}' : ' ${'am'.tr().toUpperCase()}');
    
    // Get timezone abbreviation
    String tzAbbr = '';
    if (timezone != null && timezone != 'UTC') {
      final tzData = timezoneOffsets[timezone];
      if (tzData != null) {
        tzAbbr = ' (${tzData.standardName})';
      }
    } else if (timezone == 'UTC') {
      tzAbbr = ' (UTC)';
    }
    
    return '$month $day, $year ${'at'.tr()} $hour:$minute$period$tzAbbr';
  }
  
  // Format date only
  // Shows: "Dec 18, 2025"
  static String formatDate(DateTime dateTime, {String? timezone}) {
    // Convert to specified timezone
    final localTime = _convertToTimezone(dateTime, timezone);
    
    final month = localTime.month.getAbbreviatedMonth();
    final day = localTime.day;
    final year = localTime.year;
    
    return '$month $day, $year';
  }
  
  // Format datetime with timezone for tooltip/subtitle
  // Shows: "Dec 18, 2025 at 15:44 AST" (without parentheses)
  static String formatDateTimeWithTZ(DateTime dateTime, {bool use24Hour = true, String? timezone}) {
    // Convert to specified timezone
    final localTime = _convertToTimezone(dateTime, timezone);
    
    final month = localTime.month.getAbbreviatedMonth();
    final day = localTime.day;
    final year = localTime.year;
    
    final hour = use24Hour
        ? localTime.hour.toString().padLeft(2, '0')
        : (localTime.hour % 12 == 0 ? 12 : localTime.hour % 12).toString();
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = use24Hour ? '' : (localTime.hour >= 12 ? ' ${'pm'.tr().toUpperCase()}' : ' ${'am'.tr().toUpperCase()}');
    
    // Get timezone abbreviation
    String tzAbbr = '';
    if (timezone != null && timezone != 'UTC') {
      final tzData = timezoneOffsets[timezone];
      if (tzData != null) {
        tzAbbr = ' ${tzData.standardName}';
      }
    } else if (timezone == 'UTC') {
      tzAbbr = ' UTC';
    }
    
    return '$month $day, $year ${'at'.tr()} $hour:$minute$period$tzAbbr';
  }
  
  // Helper method - now just returns time as-is since we store in local timezone
  static DateTime _convertToTimezone(DateTime localTime, String? timezone) {
    // Times are now stored in local timezone, so just return as-is
    // The timezone parameter is used only for displaying the abbreviation
    return localTime;
  }
}