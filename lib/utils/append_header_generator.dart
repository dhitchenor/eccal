// Append Header Generator
import '../providers/settings_provider.dart';
import '../constants/moods.dart';
import '../constants/times.dart';
import '../utils/app_localizations.dart';

class AppendHeaderGenerator {
  // Generate an append header with date, time, and optional mood/location
  // 
  // Format:
  // ───── Appended on: 27 December, 2024, 13:45 ─────
  // Mood: 😊 happy
  // Location: Coffee Shop
  
  static String generate({
    required DateTime appendDate,
    required bool use24HourFormat,
    required String mood,
    String? location,
    required bool showMood,
    required bool showLocation,
  }) {
    final buffer = StringBuffer();
    
    // Date formatting using MonthNames utility
    final monthName = MonthNames.abbreviatedMonthMap[appendDate.month] ?? '';
    final dateStr = '${appendDate.day} $monthName, ${appendDate.year}';
    
    // Time formatting based on preference
    String timeStr;
    if (use24HourFormat) {
      timeStr = '${appendDate.hour.toString().padLeft(2, '0')}:${appendDate.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = appendDate.hour == 0 ? 12 : (appendDate.hour > 12 ? appendDate.hour - 12 : appendDate.hour);
      final period = appendDate.hour >= 12 ? 'pm'.tr() : 'am'.tr();
      timeStr = '$hour:${appendDate.minute.toString().padLeft(2, '0')} $period';
    }
    
    // Main header line
    buffer.writeln('───── ${'home_screen.added_on'.tr()}: $dateStr, $timeStr ─────');
    
    // Add mood line if enabled
    if (showMood) {
      final moodEmoji = MoodHelper.getMoodEmoji(mood);
      buffer.writeln('Mood: $moodEmoji $mood');
    }
    
    // Add location line if enabled and location exists
    if (showLocation && location != null && location.isNotEmpty) {
      buffer.writeln('Location: $location');
    }
    
    return buffer.toString();
  }
  
  // Generate append header from SettingsProvider
  static String generateFromSettings({
    required DateTime appendDate,
    required SettingsProvider settings,
    required String mood,
    String? location,
  }) {
    return generate(
      appendDate: appendDate,
      use24HourFormat: settings.use24HourFormat,
      mood: mood,
      location: location,
      showMood: settings.showAppendMoodInHeaders,
      showLocation: settings.showAppendLocationInHeaders,
    );
  }
}