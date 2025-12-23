import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/timezones.dart';
import '../models/calendar_info.dart';
import '../services/logger_service.dart';
import '../utils/app_localizations.dart';
import '../utils/time_helper.dart';

enum FileFormat { ics, txt }

enum CalendarProvider { caldav, google, apple }

class SettingsProvider extends ChangeNotifier {
  // Secure storage for sensitive data
  final _secureStorage = const FlutterSecureStorage();

  String? _caldavUrl;
  String? _caldavUsername;
  String? _caldavCalendarName;
  CalendarProvider _calendarProvider = CalendarProvider.caldav;
  String? _googleCalendarId;
  String? _googleUserEmail;
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

  // Initial setup prompts - granular control for each dialog
  bool _initialServerSetup = true; // Show server setup dialog
  bool _initialTzChoice = true; // Show timezone confirmation dialog
  bool _initialCalChoice = true; // Show calendar verification dialog

  bool _showCalendarVerificationPrompt =
      true; // Default: show calendar verification after timezone change
  bool _showAppendMoodInHeaders = true; // Default: show mood in append headers
  bool _showAppendLocationInHeaders =
      true; // Default: show location in append headers

  // Encryption settings
  bool _encryptionEnabled = false; // Default: encryption disabled
  bool _biometricUnlockEnabled = false; // Default: biometric disabled
  String? _encryptionSalt; // Salt for key derivation (base64)
  int _encryptionIterations = 100000; // PBKDF2 iterations

  // Runtime flags (not persisted)
  bool _inTimezoneChangeFlow =
      false; // True when user is in timezone change flow
  bool _inInitialSetupFlow = false; // True when in initial setup flow

  // Calendar list cache
  List<Map<String, String>>? _cachedCalendarList;
  List<Map<String, String>>? get cachedCalendarList => _cachedCalendarList;

  String? get caldavUrl => _caldavUrl;
  String? get caldavUsername => _caldavUsername;

  // Async getter for password - retrieves from secure storage
  Future<String?> get caldavPassword async {
    if (_caldavUsername == null || _caldavUsername!.isEmpty) {
      return null;
    }

    try {
      return await _secureStorage.read(key: 'caldav_password_$_caldavUsername');
    } catch (e) {
      logger.error('Failed to read password from secure storage: $e');
      rethrow; // Re-throw so UI can handle it
    }
  }

  String? get caldavCalendarName => _caldavCalendarName;
  CalendarProvider get calendarProvider => _calendarProvider;
  String? get googleCalendarId => _googleCalendarId;
  String? get googleUserEmail => _googleUserEmail;
  bool get isGoogleCalendar => _calendarProvider == CalendarProvider.google;
  bool get isAppleCalendar => _calendarProvider == CalendarProvider.apple;
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

  // Granular initial setup flags
  bool get initialServerSetup => _initialServerSetup;
  bool get initialTzChoice => _initialTzChoice;
  bool get initialCalChoice => _initialCalChoice;

  bool get showCalendarVerificationPrompt => _showCalendarVerificationPrompt;
  bool get showAppendMoodInHeaders => _showAppendMoodInHeaders;
  bool get showAppendLocationInHeaders => _showAppendLocationInHeaders;

  // Encryption getters
  bool get encryptionEnabled => _encryptionEnabled;
  bool get biometricUnlockEnabled => _biometricUnlockEnabled;
  String? get encryptionSalt => _encryptionSalt;
  int get encryptionIterations => _encryptionIterations;

  // Runtime flags getters
  bool get inTimezoneChangeFlow => _inTimezoneChangeFlow;
  bool get inInitialSetupFlow => _inInitialSetupFlow;

  String _language = 'en';
  String get language => _language;

  // Check if an exception is a keyring/secure storage error
  static bool isKeyringError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('libsecret') ||
        errorString.contains('keyring') ||
        errorString.contains('dbus') ||
        errorString.contains('secret service') ||
        errorString.contains('kwallet');
  }

  // Get user-friendly error message for keyring errors
  static String getKeyringErrorMessage() {
    return 'Secure password storage is not available on your system. '
        'Please install a keyring service (see FAQ for details).';
  }

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
    _caldavCalendarName = prefs.getString('caldav_calendar_name');
    _googleCalendarId = prefs.getString('google_calendar_id');
    _googleUserEmail = prefs.getString('google_user_email');

    final providerStr = prefs.getString('calendar_provider');
    if (providerStr != null) {
      _calendarProvider = CalendarProvider.values.firstWhere(
        (e) => e.toString() == providerStr,
        orElse: () => CalendarProvider.caldav,
      );
    }
    _eventDurationMinutes = prefs.getInt('event_duration') ?? 15;
    _customStoragePath = prefs.getString('custom_storage_path');
    _use24HourFormat = prefs.getBool('use_24_hour_format') ?? true;
    _defaultEntryTitle =
        prefs.getString('default_entry_title') ?? 'EcCal - {YYYY}{MM}{DD}';
    _caldavSyncDisabled = prefs.getBool('caldav_sync_disabled') ?? false;
    _serverPollIntervalMinutes = prefs.getInt('server_poll_interval') ?? 60;

    // Load granular initial setup flags
    _initialServerSetup = prefs.getBool('initial_server_setup') ?? true;
    _initialTzChoice = prefs.getBool('initial_tz_choice') ?? true;
    _initialCalChoice = prefs.getBool('initial_cal_choice') ?? true;

    _showCalendarVerificationPrompt =
        prefs.getBool('show_calendar_verification_prompt') ?? true;
    _showAppendMoodInHeaders =
        prefs.getBool('show_append_mood_in_headers') ?? true;
    _showAppendLocationInHeaders =
        prefs.getBool('show_append_location_in_headers') ?? true;
    _language = prefs.getString('language') ?? 'en';

    // Load encryption settings
    _encryptionEnabled = prefs.getBool('encryption_enabled') ?? false;
    _biometricUnlockEnabled =
        prefs.getBool('biometric_unlock_enabled') ?? false;
    _encryptionSalt = prefs.getString('encryption_salt');
    _encryptionIterations = prefs.getInt('encryption_iterations') ?? 100000;

    final logLevelString = prefs.getString('log_level');
    if (logLevelString != null) {
      _logLevel = LogLevel.values.firstWhere(
        (e) => e.name == logLevelString,
        orElse: () => LogLevel.none,
      );
    }

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

    // Load cached calendar list
    final calendarListJson = prefs.getString('cached_calendar_list');
    if (calendarListJson != null) {
      try {
        final List<dynamic> decoded = json.decode(calendarListJson);
        _cachedCalendarList = decoded
            .map((item) => Map<String, String>.from(item as Map))
            .toList();
        logger.debug(
          'Loaded ${_cachedCalendarList?.length ?? 0} cached calendars',
        );
      } catch (e) {
        logger.error('Failed to load cached calendar list: $e');
        _cachedCalendarList = null;
      }
    }

    notifyListeners();
  }

  // Detect the device's timezone
  String _detectDeviceTimezone() {
    try {
      // Get the current offset
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;
      final minutes = (offset.inMinutes % 60).abs();

      // Format offset as +HHMM or -HHMM
      final sign = hours >= 0 ? '+' : '-';
      final absHours = hours.abs();
      final offsetString =
          '$sign${absHours.toString().padLeft(2, '0')}${minutes.toString().padLeft(2, '0')}';

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

  Future<void> setCaldavSettings(
    String url,
    String username,
    String password,
    String calendarName,
  ) async {
    _caldavUrl = url;
    _caldavUsername = username;
    _caldavCalendarName = calendarName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('caldav_url', url);
    await prefs.setString('caldav_username', username);
    await prefs.setString('caldav_calendar_name', calendarName);

    // Store password in secure storage using username as part of key
    try {
      await _secureStorage.write(
        key: 'caldav_password_$username',
        value: password,
      );
    } catch (e) {
      logger.error('Failed to save password to secure storage: $e');
      rethrow; // Re-throw so UI can handle it
    }

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

  // Disable individual initial setup prompts
  Future<void> disableInitialServerSetup() async {
    _initialServerSetup = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('initial_server_setup', false);
    notifyListeners();
  }

  Future<void> disableInitialTzChoice() async {
    _initialTzChoice = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('initial_tz_choice', false);
    notifyListeners();
  }

  Future<void> disableInitialCalChoice() async {
    _initialCalChoice = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('initial_cal_choice', false);
    notifyListeners();
  }

  // Disable calendar verification prompt (after timezone change)
  Future<void> disableCalendarVerificationPrompt() async {
    _showCalendarVerificationPrompt = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_calendar_verification_prompt', false);
    notifyListeners();
  }

  // Set timezone change flow flag (runtime only, not persisted)
  Future<void> setTimezoneChangeFlow(bool value) async {
    _inTimezoneChangeFlow = value;
    notifyListeners();
  }

  Future<void> setInitialSetupFlow(bool value) async {
    _inInitialSetupFlow = value;
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

  Future<void> setCalendarProvider(CalendarProvider provider) async {
    _calendarProvider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calendar_provider', provider.toString());
    notifyListeners();
  }

  Future<void> setGoogleCalendar({
    required String? calendarId,
    required String? userEmail,
  }) async {
    _googleCalendarId = calendarId;
    _googleUserEmail = userEmail;

    final prefs = await SharedPreferences.getInstance();
    if (calendarId != null) {
      await prefs.setString('google_calendar_id', calendarId);
    } else {
      await prefs.remove('google_calendar_id');
    }
    if (userEmail != null) {
      await prefs.setString('google_user_email', userEmail);
    } else {
      await prefs.remove('google_user_email');
    }

    notifyListeners();
  }

  // Clear all CalDAV settings (for sign out)
  Future<void> clearCalDAVSettings() async {
    // Delete password from secure storage before clearing username
    if (_caldavUsername != null && _caldavUsername!.isNotEmpty) {
      await _secureStorage.delete(key: 'caldav_password_$_caldavUsername');
    }

    _caldavUrl = null;
    _caldavUsername = null;
    _caldavCalendarName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('caldav_url');
    await prefs.remove('caldav_username');
    await prefs.remove('caldav_calendar_name');

    notifyListeners();
  }

  // Set CalDAV calendar name
  Future<void> setCalDAVCalendarName(String calendarName) async {
    _caldavCalendarName = calendarName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('caldav_calendar_name', calendarName);

    notifyListeners();
  }

  // Cache calendar list for faster server tab loading
  Future<void> setCachedCalendarList(List<CalendarInfo> calendars) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert CalendarInfo list to JSON-serializable format
    final calendarMaps = calendars
        .map(
          (cal) => {
            'id': cal.id,
            'name': cal.name,
            'provider': cal.provider.toString(),
          },
        )
        .toList();

    final jsonString = json.encode(calendarMaps);
    await prefs.setString('cached_calendar_list', jsonString);

    _cachedCalendarList = calendarMaps;
    notifyListeners();

    logger.debug('Cached ${calendars.length} calendars');
  }

  // Clear cached calendar list (call on sign out)
  Future<void> clearCachedCalendarList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_calendar_list');

    _cachedCalendarList = null;
    notifyListeners();

    logger.debug('Cleared cached calendar list');
  }

  // Get cached calendars as CalendarInfo objects
  List<CalendarInfo>? getCachedCalendarsAsCalendarInfo() {
    if (_cachedCalendarList == null) return null;

    return _cachedCalendarList!.map((map) {
      final providerStr = map['provider'] ?? 'CalendarProvider.caldav';
      final provider = providerStr.contains('google')
          ? CalendarProvider.google
          : providerStr.contains('apple')
          ? CalendarProvider.apple
          : CalendarProvider.caldav;

      return CalendarInfo(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        provider: provider,
      );
    }).toList();
  }

  // Encryption settings setters
  Future<void> setEncryptionEnabled(bool enabled) async {
    _encryptionEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('encryption_enabled', enabled);
    notifyListeners();
    logger.info('Encryption enabled: $enabled');
  }

  Future<void> setBiometricUnlockEnabled(bool enabled) async {
    _biometricUnlockEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_unlock_enabled', enabled);
    notifyListeners();
    logger.info('Biometric unlock enabled: $enabled');
  }

  Future<void> setEncryptionSalt(String? salt) async {
    _encryptionSalt = salt;
    final prefs = await SharedPreferences.getInstance();
    if (salt != null) {
      await prefs.setString('encryption_salt', salt);
    } else {
      await prefs.remove('encryption_salt');
    }
    notifyListeners();
    logger.debug('Encryption salt updated');
  }

  Future<void> setEncryptionIterations(int iterations) async {
    _encryptionIterations = iterations;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('encryption_iterations', iterations);
    notifyListeners();
    logger.debug('Encryption iterations: $iterations');
  }

  // Get encryption passphrase from secure storage
  Future<String?> getEncryptionPassphrase() async {
    try {
      return await _secureStorage.read(key: 'encryption_passphrase');
    } catch (e) {
      logger.error('Failed to read encryption passphrase: $e');
      return null;
    }
  }

  // Set encryption passphrase in secure storage
  Future<void> setEncryptionPassphrase(String? passphrase) async {
    try {
      if (passphrase != null) {
        await _secureStorage.write(
          key: 'encryption_passphrase',
          value: passphrase,
        );
        logger.debug('Encryption passphrase saved to secure storage');
      } else {
        await _secureStorage.delete(key: 'encryption_passphrase');
        logger.debug('Encryption passphrase removed from secure storage');
      }
    } catch (e) {
      logger.error('Failed to save encryption passphrase: $e');
      rethrow;
    }
  }
}

enum StorageType { sqlite, textFiles }
