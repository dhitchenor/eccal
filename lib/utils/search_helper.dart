import '../constants/times.dart';
import '../models/diary_entry.dart';
import '../utils/date_formatter.dart';

class SearchHelper {
  // Search entries by query string
  // searches title, description, location, and date (multiple formats)
  static List<DiaryEntry> searchEntries({
    required List<DiaryEntry> entries,
    required String query,
    required bool use24HourFormat,
  }) {
    final searchQuery = query.toLowerCase().trim();
    
    if (searchQuery.isEmpty) {
      return entries;
    }
    
    return entries.where((entry) {
      return _matchesSearchQuery(entry, searchQuery, use24HourFormat);
    }).toList();
  }
  
  // Check if a single entry matches the search query
  static bool _matchesSearchQuery(
    DiaryEntry entry,
    String searchQuery,
    bool use24HourFormat,
  ) {
    // Search in title
    if (entry.title.toLowerCase().contains(searchQuery)) {
      return true;
    }
    
    // Search in description
    if (entry.description.toLowerCase().contains(searchQuery)) {
      return true;
    }
    
    // Search in primary location
    if (entry.location != null && entry.location!.toLowerCase().contains(searchQuery)) {
      return true;
    }
    
    // Search in primary mood
    if (entry.mood.toLowerCase().contains(searchQuery)) {
      return true;
    }
    
    // Search in append locations
    for (final appendLocation in entry.appendLocations) {
      if (appendLocation.toLowerCase().contains(searchQuery)) {
        return true;
      }
    }
    
    // Search in append moods
    for (final appendMood in entry.appendMoods) {
      if (appendMood.toLowerCase().contains(searchQuery)) {
        return true;
      }
    }
    
    // Search in formatted date
    final formattedDate = DateFormatter.formatDateTime(
      entry.dtstart,
      use24Hour: use24HourFormat,
      timezone: entry.timezone,
    ).toLowerCase();
    
    if (formattedDate.contains(searchQuery)) {
      return true;
    }
    
    // Search in date components
    return _matchesDateSearch(entry, searchQuery);
  }
  
  // Check if entry matches date-specific search patterns
  static bool _matchesDateSearch(DiaryEntry entry, String searchQuery) {
    final year = entry.dtstart.year.toString();
    final month = entry.dtstart.month.toString().padLeft(2, '0');
    final day = entry.dtstart.day.toString().padLeft(2, '0');
    
    // Match ISO format parts: "2024", "2024-12", "2024-12-27", "27", "12-27"
    if (year.contains(searchQuery) ||
        '$year-$month'.contains(searchQuery) ||
        '$year-$month-$day'.contains(searchQuery) ||
        day.contains(searchQuery) ||
        '$month-$day'.contains(searchQuery) ||
        '$day-$month'.contains(searchQuery)) {
      return true;
    }
    
    // Match month names (full and abbreviated)
    final monthFull = MonthNames.fullMonthMap[entry.dtstart.month]?.toLowerCase() ?? '';
    final monthAbbr = MonthNames.abbreviatedMonthMap[entry.dtstart.month]?.toLowerCase() ?? '';
    
    // Match: "27 dec", "dec 27", "27 december", "december 27", "dec", "december"
    if (searchQuery.contains('$day $monthAbbr') ||
        searchQuery.contains('$monthAbbr $day') ||
        searchQuery.contains('$day $monthFull') ||
        searchQuery.contains('$monthFull $day') ||
        monthFull.contains(searchQuery) ||
        monthAbbr.contains(searchQuery)) {
      return true;
    }
    
    return false;
  }
}