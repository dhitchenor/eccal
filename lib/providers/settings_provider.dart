import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/time_helper.dart';
import '../services/logger_service.dart';
import '../services/logger_service.dart';
import '../constants/timezones.dart';
import '../utils/app_localizations.dart';

enum FileFormat { ics, txt }

class SettingsProvider extends ChangeNotifier {
  String? _caldavUrl;
  String? _caldavUsername;
  String? _caldavPassword;
  String? _caldavCalendarName;
  int _eventDurationMinutes = 15;
  StorageType _storageType = StorageType.textFiles;
  String? _customStoragePath;
  bool _use24HourFormat = true; // Default to 24-hour format
  String _defaultEntryTitle = 'EcCal - {YYYY}{MM}{DD}';
  FileFormat _fileFormat = FileFormat.ics; // Default to .ics
  String _timezone = 'UTC'; // Default timezone
  bool _caldavSyncDisabled = false; // Default: sync enabled
  LogLevel _logLevel = LogLevel.none; // Default: no logging
  int _serverPollIntervalMinutes = 60; // Default: poll every hour
  bool _showCaldavSetupPrompt = true; // Default: show prompt
  bool _showAppendMoodInHeaders = true; // Default: show mood in append headers
  bool _showAppendLocationInHeaders = true; // Default: show location in append headers

  String? get caldavUrl => _caldavUrl;
  String? get caldavUsername => _caldavUsername;
  String? get caldavPassword => _caldavPassword;
  String? get caldavCalendarName => _caldavCalendarName;
  int get eventDurationMinutes => _eventDurationMinutes;
  StorageType get storageType => _storageType;
  String? get customStoragePath => _customStoragePath;
  bool get use24HourFormat => _use24HourFormat;
  String get defaultEntryTitle => _defaultEntryTitle;
  FileFormat get fileFormat => _fileFormat;
  String get timezone => _timezone;
  bool get caldavSyncDisabled => _caldavSyncDisabled;
  LogLevel get logLevel => _logLevel;
  int get serverPollIntervalMinutes => _serverPollIntervalMinutes;
  bool get showCaldavSetupPrompt => _showCaldavSetupPrompt;
  bool get showAppendMoodInHeaders => _showAppendMoodInHeaders;
  bool get showAppendLocationInHeaders => _showAppendLocationInHeaders;
  String _language = 'en';
  String get language => _language;

  SettingsProvider() {
    // Don't call _loadSettings() here - causes release mode crash
    // initialize() will be called from main() before runApp()
  }

  // Initialize settings - must be called after construction
  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _caldavUrl = prefs.getString('caldav_url');
    _caldavUsername = prefs.getString('caldav_username');
    _caldavPassword = prefs.getString('caldav_password');
    _caldavCalendarName = prefs.getString('caldav_calendar_name');
    _eventDurationMinutes = prefs.getInt('event_duration') ?? 15;
    _customStoragePath = prefs.getString('custom_storage_path');
    _use24HourFormat = prefs.getBool('use_24_hour_format') ?? true;
    _defaultEntryTitle = prefs.getString('default_entry_title') ?? 'EcCal - {YYYY}{MM}{DD}';
    _caldavSyncDisabled = prefs.getBool('caldav_sync_disabled') ?? false;
    _serverPollIntervalMinutes = prefs.getInt('server_poll_interval') ?? 60;
    _showCaldavSetupPrompt = prefs.getBool('show_caldav_setup_prompt') ?? true;
    _showAppendMoodInHeaders = prefs.getBool('show_append_mood_in_headers') ?? true;
    _showAppendLocationInHeaders = prefs.getBool('show_append_location_in_headers') ?? true;
    _language = prefs.getString('language') ?? 'en';

    final logLevelString = prefs.getString('log_level');
    if (logLevelString != null) {
      _logLevel = LogLevel.values.firstWhere(
        (e) => e.name == logLevelString,
        orElse: () => LogLevel.none,
      );
    }
    
    // Initialize logger with saved level
    await logger.initialize(_logLevel);
    
    // Auto-detect timezone on first run
    final savedTimezone = prefs.getString('timezone');
    if (savedTimezone != null) {
      _timezone = savedTimezone;
    } else {
      // First run - detect device timezone
      _timezone = _detectDeviceTimezone();
      // Save it for next time
      await prefs.setString('timezone', _timezone);
      logger.info('Auto-detected timezone: $_timezone');
    }
    
    final storageTypeString = prefs.getString('storage_type');
    if (storageTypeString != null) {
      _storageType = StorageType.values.firstWhere(
        (e) => e.toString() == storageTypeString,
        orElse: () => StorageType.textFiles,
      );
    }
    
    final fileFormatString = prefs.getString('file_format');
    if (fileFormatString != null) {
      _fileFormat = FileFormat.values.firstWhere(
        (e) => e.toString() == fileFormatString,
        orElse: () => FileFormat.ics,
      );
    }

    // Load localizations
    await AppLocalizations.load(_language);
    
    notifyListeners();
  }

  // Detect the device's timezone
  String _detectDeviceTimezone() {
    try {
      // Get the current offset
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;
      final minutes = (offset.inMinutes % 60).abs();
      
      // Format offset as +HHMM or -HHMM (like your TimezoneData format)
      final sign = hours >= 0 ? '+' : '-';
      final absHours = hours.abs();
      final offsetString = '$sign${absHours.toString().padLeft(2, '0')}${minutes.toString().padLeft(2, '0')}';
      
      // Find all timezones matching this offset
      final matchingTimezones = timezoneOffsets.entries
          .where((entry) => entry.value.standardOffset == offsetString)
          .toList();
      
      if (matchingTimezones.isEmpty) {
        return 'UTC';
      }
      
      // Return the first match
      return matchingTimezones.first.key;
      
    } catch (e) {
      logger.error('Error detecting timezone: $e');
      return 'UTC';
    }
  }

  Future<void> setLogLevel(LogLevel level) async {
    _logLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('log_level', level.name);
    
    // Update logger immediately
    logger.setLogLevel(level);
    
    notifyListeners();
  }

  void setCaldavSettings(String url, String username, String password, String calendarName) async {
    _caldavUrl = url;
    _caldavUsername = username;
    _caldavPassword = password;
    _caldavCalendarName = calendarName;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('caldav_url', url);
    await prefs.setString('caldav_username', username);
    await prefs.setString('caldav_password', password);
    await prefs.setString('caldav_calendar_name', calendarName);
    
    notifyListeners();
  }

  void setEventDuration(int minutes) async {
    if (minutes >= 1) {
      _eventDurationMinutes = minutes;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('event_duration', minutes);
      
      notifyListeners();
    }
  }

  void setStorageType(StorageType type) async {
    _storageType = type;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_type', type.toString());
    
    notifyListeners();
  }

  void setCustomStoragePath(String? path) async {
    _customStoragePath = path;
    
    final prefs = await SharedPreferences.getInstance();
    if (path != null && path.isNotEmpty) {
      await prefs.setString('custom_storage_path', path);
    } else {
      await prefs.remove('custom_storage_path');
    }
    
    notifyListeners();
  }

  void setTimeFormat(bool use24Hour) async {
    _use24HourFormat = use24Hour;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_24_hour_format', use24Hour);
    
    notifyListeners();
  }

  void setDefaultEntryTitle(String title) async {
    _defaultEntryTitle = title;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_entry_title', title);
    
    notifyListeners();
  }

  void setFileFormat(FileFormat format) async {
    _fileFormat = format;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('file_format', format.toString());
    
    notifyListeners();
  }

  void setTimezone(String timezone) async {
    _timezone = timezone;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timezone', timezone);
    
    notifyListeners();
  }

  void setCaldavSyncDisabled(bool disabled) async {
    _caldavSyncDisabled = disabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('caldav_sync_disabled', disabled);
    
    notifyListeners();
  }

  Future<void> setServerPollInterval(int minutes) async {
    _serverPollIntervalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('server_poll_interval', minutes);
    notifyListeners();
  }

  // Adds language setter
  void setLanguage(String language) async {
    _language = language;
    notifyListeners();
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    
    // Reload localizations
    await AppLocalizations.load(language);
  }

  // Generate entry title from template with placeholders
  String generateEntryTitle() {
    final now = DateTime.now();
    String title = _defaultEntryTitle;
    
    // Replace date placeholders
    title = title.replaceAll('{YYYY}', '${now.year}');
    title = title.replaceAll('{DD}', '${now.day.toString().padLeft(2, '0')}');
    title = title.replaceAll('{MM}', '${now.month.toString().padLeft(2, '0')}');
    
    // Replace day of week placeholders
    title = title.replaceAll('{WEEKDAY}', now.weekday.getFullWeekday());
    title = title.replaceAll('{WKD}', now.weekday.getAbbreviatedWeekday());
    
    // Replace month placeholders
    title = title.replaceAll('{MONTH}', now.month.getFullMonth());
    title = title.replaceAll('{MMM}', now.month.getAbbreviatedMonth());
    
    return title;
  }

  // Disable CalDAV setup prompt permanently
  Future<void> disableCaldavSetupPrompt() async {
    _showCaldavSetupPrompt = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_caldav_setup_prompt', false);
    notifyListeners();
  }

  // Toggle showing mood in append headers
  Future<void> setShowAppendMoodInHeaders(bool show) async {
    _showAppendMoodInHeaders = show;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_append_mood_in_headers', show);
    notifyListeners();
  }

  // Toggle showing location in append headers
  Future<void> setShowAppendLocationInHeaders(bool show) async {
    _showAppendLocationInHeaders = show;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_append_location_in_headers', show);
    notifyListeners();
  }
}

enum StorageType { sqlite, textFiles }