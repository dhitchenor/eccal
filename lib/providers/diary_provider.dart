import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/diary_entry.dart';
import '../providers/settings_provider.dart';
import '../services/caldav_service.dart';
import '../services/calendar_service_adapter.dart';
import '../services/google_calendar_service.dart';
import '../services/file_storage_service.dart';
import '../services/logger_service.dart';
import '../utils/app_localizations.dart';

class DiaryProvider with ChangeNotifier {
  List<DiaryEntry> _entries = [];
  final FileStorageService _fileStorage = FileStorageService();
  bool _isLoading = false;

  // Calendar service adapter (routes to CalDAV or Google Calendar)
  CalendarServiceAdapter? _calendarAdapter;
  final GoogleCalendarService _googleService = GoogleCalendarService();

  // Settings provider reference
  SettingsProvider? _settingsProvider;

  // Server status cache
  Map<String, bool> _serverStatusCache = {};
  Timer? _serverPollTimer;
  bool _isPolling = false;

  List<DiaryEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get isPolling => _isPolling;
  GoogleCalendarService get googleCalendarService => _googleService;

  DiaryProvider() {
    // Don't call loadEntriesFromStorage() here - causes release mode crash
    // initialize() will be called from main() before runApp()
  }

  /// Get file format from settings (ics or txt)
  String _getFileFormat() {
    return _settingsProvider?.fileFormat == FileFormat.txt ? 'txt' : 'ics';
  }

  /// Check if server sync should be attempted
  bool _shouldSyncToServer() {
    return isCalDAVConfigured &&
        !(_settingsProvider?.caldavSyncDisabled ?? false);
  }

  /// Log why server sync was skipped
  void _logServerSyncSkipped() {
    if (_settingsProvider?.caldavSyncDisabled ?? false) {
      logger.info('CalDAV sync disabled, skipping sync');
    } else {
      logger.info('CalDAV not configured, skipping sync');
    }
  }

  /// Save entry to file storage using settings format and entry timezone
  Future<void> _saveEntryToFile(DiaryEntry entry) async {
    final fileFormat = _getFileFormat();
    await _fileStorage.saveEntry(
      entry,
      fileFormat: fileFormat,
      timezone: entry.timezone,
    );
  }

  /// Create DiaryEntry from CalendarEvent
  DiaryEntry _createEntryFromCalendarEvent(CalendarEvent event) {
    final entryId = event.uid.split('@')[0];
    return DiaryEntry(
      id: entryId,
      title: event.summary,
      description: event.description ?? '',
      dtstart: event.dtstart,
      dtstamp: event.dtstamp ?? event.dtstart,
      mood: event.mood ?? 'neutral',
      location: event.location,
      appendDates: event.appendDates,
      appendMoods: event.appendMoods,
      appendLocations: event.appendLocations,
      appendLatitudes: event.appendLatitudes,
      appendLongitudes: event.appendLongitudes,
      timezone: event.timezone,
    );
  }

  /// Update existing entry with data from CalendarEvent
  DiaryEntry _updateEntryFromCalendarEvent(
    DiaryEntry existingEntry,
    CalendarEvent event,
  ) {
    final entryId = event.uid.split('@')[0];
    return DiaryEntry(
      id: entryId,
      title: event.summary,
      description: event.description ?? '',
      dtstart: existingEntry.dtstart,
      dtstamp: event.dtstamp ?? event.dtstart,
      mood: event.mood ?? existingEntry.mood,
      location: event.location ?? existingEntry.location,
      latitude: existingEntry.latitude,
      longitude: existingEntry.longitude,
      categories: existingEntry.categories,
      appendDates: event.appendDates,
      appendMoods: event.appendMoods,
      appendLocations: event.appendLocations,
      appendLatitudes: event.appendLatitudes,
      appendLongitudes: event.appendLongitudes,
      attachments: existingEntry.attachments,
      timezone: event.timezone,
    );
  }

  // Initialize provider - must be called after construction
  Future<void> initialize() async {
    await loadEntriesFromStorage();
    // initialize is kept here, just in case
    // something else that is 'local' needs to be
    // initialized!
  }

  Future<void> initializeGoogleCalendar() async {
    // Initialize Google Calendar service with platform-specific client ID
    String? clientId;
    String? clientSecret;

    if (Platform.isAndroid) {
      clientId = AppConfig.googleCalendarClientID_Android;
    } else if (Platform.isIOS) {
      clientId = AppConfig.googleCalendarClientID_iOS;
    } else {
      clientId = AppConfig.googleCalendarClientID_Desktop;
      clientSecret = AppConfig.googleCalendarClientSecret_Desktop;
    }

    await _googleService.initialize(
      clientId: clientId,
      clientSecret: clientSecret ?? '', // Desktop needs this
    );
  }

  // Sync with calendar server (CalDAV or Google Calendar)
  Future<void> syncWithCalDAV() async {
    if (!isCalDAVConfigured) {
      logger.error('isCalDAVConfigured returned false');
      if (_settingsProvider != null) {
        logger.debug('Provider: ${_settingsProvider!.calendarProvider}');
        logger.debug('Google signed in: ${_googleService.isSignedIn}');
        logger.debug(
          'Google calendar ID: ${_settingsProvider!.googleCalendarId}',
        );
      }
      logger.info('Server not configured');
      return;
    }

    logger.info('Server is configured, proceeding with sync');

    if (_settingsProvider?.caldavSyncDisabled ?? false) {
      logger.info('Sync disabled in settings');
      return;
    }

    logger.info('Starting calendar sync');

    // Set polling state to show UI feedback
    _isPolling = true;
    notifyListeners();

    try {
      // Fetch calendar events using adapter
      final calendarEvents = await _calendarAdapter!.fetchEvents();
      logger.info('Fetched ${calendarEvents.length} events from server');

      // Convert calendar events to diary entries
      final caldavEntries = <DiaryEntry>[];
      int updatedCount = 0;

      for (final event in calendarEvents) {
        final entryId = event.uid.split('@')[0];
        final existingEntry = _entries
            .where((e) => e.id == entryId)
            .firstOrNull;

        if (existingEntry == null) {
          // New entry from server - add it
          final entry = _createEntryFromCalendarEvent(event);
          caldavEntries.add(entry);

          // Save to local file storage
          await _saveEntryToFile(entry);
        } else {
          // Entry exists locally - check if server version is newer
          final serverModified = event.dtstamp ?? event.dtstart;
          final localModified = existingEntry.dtstamp;

          if (serverModified.isAfter(localModified)) {
            // Server version is newer - update local entry
            logger.info(
              'Server version of "${event.summary}" is newer, updating local copy',
            );
            final updatedEntry = _updateEntryFromCalendarEvent(
              existingEntry,
              event,
            );

            // Update in memory
            final index = _entries.indexWhere((e) => e.id == entryId);
            if (index != -1) {
              _entries[index] = updatedEntry;
            }

            // Save to local file storage
            await _saveEntryToFile(updatedEntry);

            updatedCount++;
          } else if (localModified.isAfter(serverModified)) {
            // Local version is newer - upload to server
            logger.info(
              'Local version of "${existingEntry.title}" is newer, uploading to server',
            );
            try {
              await _calendarAdapter!.updateEvent(existingEntry);
              updatedCount++;
            } catch (e) {
              logger.error(
                'Error uploading updated entry ${existingEntry.id} to server: $e',
              );
              // Continue with other entries even if one fails
            }
          }
        }
      }

      if (caldavEntries.isNotEmpty || updatedCount > 0) {
        logger.info('Added ${caldavEntries.length} new entries from server');
        logger.info('Updated $updatedCount existing entries from server');
        // Reload from storage to get the complete list
        await loadEntriesFromStorage();
      } else {
        logger.info('No new or updated entries from server');
      }

      // Upload local entries that don't exist on server
      final serverEventIds = calendarEvents
          .map((e) => e.uid.split('@')[0])
          .toSet();
      int uploadedCount = 0;

      for (final localEntry in _entries) {
        if (!serverEventIds.contains(localEntry.id)) {
          logger.info('Uploading local entry to server: ${localEntry.title}');
          try {
            await _calendarAdapter!.createEvent(localEntry);
            uploadedCount++;
          } catch (e) {
            logger.error(
              'Error uploading entry ${localEntry.id} to server: $e',
            );
            // Continue with other entries even if one fails
          }
        }
      }

      if (uploadedCount > 0) {
        logger.info('Uploaded $uploadedCount local entries to server');
      }

      // Update server status from sync results
      final serverIds = calendarEvents.map((e) => e.uid.split('@')[0]).toSet();
      _serverStatusCache.clear();
      for (final entry in _entries) {
        _serverStatusCache[entry.id] = serverIds.contains(entry.id);
      }
      logger.info('Updated server status cache for ${_entries.length} entries');
      notifyListeners();
    } catch (e) {
      logger.error('Error syncing with server: $e');
      // Rethrow with user-friendly message
      if (e.toString().contains('401') ||
          e.toString().contains('Authentication')) {
        logger.info('Authentication failed');
      } else if (e.toString().contains('404') ||
          e.toString().contains('not found')) {
        logger.info('Calendar not found');
      } else if (e.toString().contains('Connection') ||
          e.toString().contains('SocketException')) {
        logger.info('Connection failed');
      } else {
        logger.info('Sync failed');
      }
      rethrow;
    } finally {
      // Reset polling state
      _isPolling = false;
      notifyListeners();
    }
  }

  // Check if an entry exists on calendar server
  Future<bool> isEntryOnServer(String entryId) async {
    if (!isCalDAVConfigured) {
      return false;
    }

    try {
      final calendarEvents = await _calendarAdapter!.fetchEvents();

      return calendarEvents.any((event) => event.uid.split('@')[0] == entryId);
    } catch (e) {
      logger.error('Error checking server status: $e');
      return false;
    }
  }

  // Get server status for all entries (called on app start and poll)
  Future<Map<String, bool>> getServerStatusForAllEntries() async {
    final Map<String, bool> serverStatus = {};

    if (!isCalDAVConfigured ||
        (_settingsProvider?.caldavSyncDisabled ?? false)) {
      // If CalDAV not configured or disabled, all entries are local-only
      for (final entry in _entries) {
        serverStatus[entry.id] = false;
      }
      _serverStatusCache = serverStatus;
      return serverStatus;
    }

    try {
      final calendarEvents = await _calendarAdapter!.fetchEvents();

      // Create a set of server entry IDs for quick lookup
      final serverIds = calendarEvents.map((e) => e.uid.split('@')[0]).toSet();

      // Check each entry
      for (final entry in _entries) {
        serverStatus[entry.id] = serverIds.contains(entry.id);
      }

      _serverStatusCache = serverStatus;
      notifyListeners(); // Update UI
      return serverStatus;
    } catch (e) {
      logger.error('Error getting server status: $e');
      // On error, return cache if available, otherwise assume all local
      if (_serverStatusCache.isNotEmpty) {
        return Map.from(_serverStatusCache);
      }
      for (final entry in _entries) {
        serverStatus[entry.id] = false;
      }
      return serverStatus;
    }
  }

  // Check server status for a single entry (after save/update)
  Future<void> checkServerStatusForEntry(String entryId) async {
    if (!isCalDAVConfigured ||
        (_settingsProvider?.caldavSyncDisabled ?? false)) {
      _serverStatusCache[entryId] = false;
      notifyListeners();
      return;
    }

    try {
      final calendarEvents = await _calendarAdapter!.fetchEvents();

      final serverIds = calendarEvents.map((e) => e.uid.split('@')[0]).toSet();
      _serverStatusCache[entryId] = serverIds.contains(entryId);
      notifyListeners(); // Update UI
    } catch (e) {
      logger.error('Error checking server status for entry: $e');
      // Keep existing cache value on error
    }
  }

  // Get cached server status for an entry
  bool isOnServer(String entryId) {
    return _serverStatusCache[entryId] ?? false;
  }

  // Start background server polling
  void startServerPolling() {
    stopServerPolling(); // Cancel any existing timer

    final pollMinutes = _settingsProvider?.serverPollIntervalMinutes ?? 60;
    if (pollMinutes <= 0) return; // Polling disabled

    _serverPollTimer = Timer.periodic(Duration(minutes: pollMinutes), (
      timer,
    ) async {
      logger.info('Background server poll started');
      _isPolling = true;
      notifyListeners();

      await getServerStatusForAllEntries();

      _isPolling = false;
      notifyListeners();
    });
  }

  // Stop background server polling
  void stopServerPolling() {
    _serverPollTimer?.cancel();
    _serverPollTimer = null;
  }

  // Set settings provider reference
  void setSettingsProvider(SettingsProvider provider) {
    _settingsProvider = provider;

    // Create calendar adapter whenever settings provider changes
    _calendarAdapter = CalendarServiceAdapter(
      settings: _settingsProvider!,
      googleService: _googleService,
    );
    logger.info('Calendar adapter configured');

    startServerPolling();
  }

  // Configure CalDAV service
  void configureCalDAV({
    required String? url,
    required String? username,
    required String? password,
    required String? calendarName,
    required int eventDurationMinutes,
  }) {
    // Create calendar adapter if settings are available
    if (_settingsProvider != null) {
      _calendarAdapter = CalendarServiceAdapter(
        settings: _settingsProvider!,
        googleService: _googleService,
      );
      logger.info('Calendar adapter configured');
    }
  }

  // Refresh calendar adapter (call this when provider type changes or after Google sign-in)
  void refreshCalendarAdapter() {
    if (_settingsProvider != null) {
      _calendarAdapter = CalendarServiceAdapter(
        settings: _settingsProvider!,
        googleService: _googleService,
      );
      logger.info('Calendar adapter refreshed');
      notifyListeners();
    }
  }

  // Check if calendar service is configured
  bool get isCalDAVConfigured {
    if (_calendarAdapter == null || _settingsProvider == null) {
      logger.debug(
        'isCalDAVConfigured issue, something is null: adapter (${_calendarAdapter != null}), or settings (${_settingsProvider != null})',
      );
      return false;
    }

    logger.info(
      'Checking provider type: ${_settingsProvider!.calendarProvider}',
    );

    switch (_settingsProvider!.calendarProvider) {
      case CalendarProvider.google:
        final isSignedIn = _googleService.isSignedIn;
        final hasCalendarId = _settingsProvider!.googleCalendarId != null;
        logger.info(
          'Google - signed in: $isSignedIn, has calendar ID: $hasCalendarId',
        );
        return isSignedIn && hasCalendarId;
      case CalendarProvider.apple:
        logger.debug('Apple Calendar - not implemented');
        return false; // Not yet implemented
      case CalendarProvider.caldav:
        final hasUrl =
            _settingsProvider!.caldavUrl != null &&
            _settingsProvider!.caldavUrl!.isNotEmpty;
        final hasCalendar = _settingsProvider!.caldavCalendarName != null;
        logger.info('CalDAV - has URL: $hasUrl, has calendar: $hasCalendar');
        return hasUrl && hasCalendar;
    }
  }

  // Load all entries from file storage
  Future<void> loadEntriesFromStorage() async {
    _isLoading = true;
    notifyListeners();

    // Start a timer, for the refresh animation
    final startTime = DateTime.now();
    const minLoadTime = Duration(milliseconds: 500);

    try {
      _entries = await _fileStorage.loadAllEntries();
      logger.info('Loaded ${_entries.length} entries from storage');
    } catch (e) {
      logger.error('Error loading entries from storage: $e');
      _entries = [];
    }

    // Ensure minimum time for refreshanimation visibility
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < minLoadTime) {
      await Future.delayed(minLoadTime - elapsed);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Re-sync: Reload entries from storage and refresh UI
  Future<void> resync() async {
    logger.info('Re-syncing entries...');
    await loadEntriesFromStorage();
    logger.info('Re-sync complete');
  }

  // Refresh UI without reloading from storage
  void refreshUI() {
    _entries.sort((a, b) => b.dtstart.compareTo(a.dtstart));
    notifyListeners();
    logger.debug('UI refreshed');
  }

  // Add a new entry and save to file
  Future<void> addEntry(
    DiaryEntry entry, {
    Function(String message)? onProgress,
  }) async {
    _entries.add(entry);
    _entries.sort((a, b) => b.dtstart.compareTo(a.dtstart));
    notifyListeners();

    // Save to file storage with format from settings and entry's timezone
    try {
      onProgress?.call('save_dialog.saving_local'.tr());
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Small delay so user can see the message
      await _saveEntryToFile(entry);
      logger.info('Entry saved to file: ${entry.title}');
    } catch (e) {
      logger.error('Error saving entry to file: $e');
      rethrow;
    }

    // Sync to CalDAV if configured and not disabled
    if (_shouldSyncToServer()) {
      try {
        onProgress?.call('setup.syncing_server'.tr());
        logger.info('Syncing entry to calendar: ${entry.title}');
        await _calendarAdapter!.createEvent(entry);
        logger.info('Entry synced to calendar successfully: ${entry.title}');
        // Check server status for this entry only
        await checkServerStatusForEntry(entry.id);
      } catch (e) {
        logger.error('Error syncing entry to calendar: $e');
        // Don't rethrow - local save succeeded, server sync failed is ok
      }
    } else {
      _logServerSyncSkipped();
    }

    // Refresh UI (no need to reload from storage - we just saved)
    refreshUI();
  }

  // Update an existing entry and save to file
  Future<void> updateEntry(
    DiaryEntry updatedEntry, {
    Function(String message)? onProgress,
  }) async {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _entries[index] = updatedEntry;
      _entries.sort((a, b) => b.dtstart.compareTo(a.dtstart));
      notifyListeners();

      // Save to file storage with format from settings and entry's timezone
      try {
        onProgress?.call('save_dialog.saving_local'.tr());
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Small delay so user can see the message
        await _saveEntryToFile(updatedEntry);
        logger.info('Entry updated in file: ${updatedEntry.title}');
      } catch (e) {
        logger.error('Error updating entry in file: $e');
        rethrow;
      }

      // Sync to CalDAV if configured and not disabled
      if (_shouldSyncToServer()) {
        try {
          onProgress?.call('setup.syncing_server'.tr());
          logger.info('Updating entry in CalDAV: ${updatedEntry.title}');
          await _calendarAdapter!.updateEvent(updatedEntry);
          logger.info(
            'Entry updated in calendar successfully: ${updatedEntry.title}',
          );
          // Check server status for this entry only
          await checkServerStatusForEntry(updatedEntry.id);
        } catch (e) {
          logger.error('Error updating entry in calendar: $e');
          // Don't rethrow - local save succeeded, server sync failed is ok
        }
      } else {
        _logServerSyncSkipped();
      }

      // Refresh UI (no need to reload from storage - we just saved)
      refreshUI();
    }
  }

  // Delete an entry and remove its file
  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    notifyListeners();

    // Delete from file storage
    try {
      await _fileStorage.deleteEntry(entryId);
      logger.info('Entry deleted from file: $entryId');
      // Remove from cache
      _serverStatusCache.remove(entryId);
    } catch (e) {
      logger.error('Error deleting entry from file: $e');
    }

    // Delete from CalDAV if configured and not disabled
    if (_shouldSyncToServer()) {
      try {
        logger.info('Deleting entry from calendar: $entryId');
        await _calendarAdapter!.deleteEvent(entryId);
        logger.info('Entry deleted from calendar successfully: $entryId');
      } catch (e) {
        logger.error('Error deleting entry from calendar: $e');
      }
    } else {
      _logServerSyncSkipped();
    }

    // Refresh UI (no need to reload from storage - we just deleted)
    refreshUI();
  }

  // Delete entry locally only (from file storage)
  Future<void> deleteLocalOnly(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    notifyListeners();

    // Delete from file storage only
    try {
      await _fileStorage.deleteEntry(entryId);
      logger.info('Entry deleted locally: $entryId');
    } catch (e) {
      logger.error('Error deleting entry from file: $e');
    }

    // Refresh UI (no need to reload from storage)
    refreshUI();
  }

  // Delete entry from server only (CalDAV)
  Future<void> deleteServerOnly(String entryId) async {
    // Don't remove from _entries or file storage - only from server
    if (_shouldSyncToServer()) {
      try {
        logger.info('Deleting entry from calendar only: $entryId');
        await _calendarAdapter!.deleteEvent(entryId);
        logger.info('Entry deleted from calendar successfully: $entryId');
      } catch (e) {
        logger.error('Error deleting entry from calendar: $e');
      }
    } else {
      logger.info('CalDAV not configured or disabled');
    }
    // No need to refresh UI or reload - entry still exists locally
  }

  // Search entries with filters
  List<DiaryEntry> searchEntries({
    String? query,
    String? mood,
    List<String>? locations,
  }) {
    return _entries.where((entry) {
      bool matches = true;

      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        matches =
            matches &&
            (entry.title.toLowerCase().contains(lowerQuery) ||
                entry.description.toLowerCase().contains(lowerQuery));
      }

      if (mood != null && mood.isNotEmpty) {
        matches = matches && entry.mood == mood;
      }

      if (locations != null && locations.isNotEmpty) {
        matches =
            matches &&
            (entry.location != null && locations.contains(entry.location));
      }

      return matches;
    }).toList();
  }

  // Get the storage path for display
  Future<String> getStoragePath() async {
    return await _fileStorage.getStoragePath();
  }

  // Move entries to a new location
  Future<bool> moveEntriesToNewLocation(String newPath) async {
    try {
      final success = await _fileStorage.moveEntriesToNewLocation(newPath);
      if (success) {
        // Reload entries from new location
        await loadEntriesFromStorage();
      }
      return success;
    } catch (e) {
      logger.error('Error moving entries: $e');
      return false;
    }
  }

  // Reset to default storage path
  Future<void> resetToDefaultPath() async {
    try {
      // Load current entries before reset
      final currentEntries = List<DiaryEntry>.from(_entries);

      // Reset to default
      await _fileStorage.resetToDefaultPath();

      // Save all entries to new default location
      for (final entry in currentEntries) {
        await _saveEntryToFile(entry);
      }

      // Reload from new location
      await loadEntriesFromStorage();
    } catch (e) {
      logger.error('Error resetting to default path: $e');
    }
  }

  @override
  void dispose() {
    stopServerPolling();
    super.dispose();
  }
}
