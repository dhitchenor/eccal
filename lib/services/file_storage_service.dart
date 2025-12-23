import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../constants/moods.dart';
import '../models/diary_entry.dart';
import '../services/icalendar_generator.dart';
import '../services/logger_service.dart';
import '../utils/app_localizations.dart';

class FileStorageService {
  static const String _folderName = 'eccal_entries';
  static const String _customPathKey = 'custom_storage_path';

  // Get the directory where entries are stored
  Future<Directory> _getStorageDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(_customPathKey);
    
    Directory storageDir;
    
    if (customPath != null && customPath.isNotEmpty) {
      // Use custom path if set
      storageDir = Directory(customPath);
    } else {
      // Use platform-appropriate default directory
      if (Platform.isAndroid) {
        // On Android, try to use external storage for user accessibility
        try {
          // Try to use Download directory first (accessible to user)
          final downloadDir = Directory('/storage/emulated/0/Download/$_folderName');
          if (await downloadDir.exists() || await _canCreateDirectory(downloadDir)) {
            storageDir = downloadDir;
          } else {
            // Fallback to app's external storage
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              storageDir = Directory('${externalDir.path}/$_folderName');
            } else {
              // Last resort: use Documents directory
              final documentsDir = await getApplicationDocumentsDirectory();
              storageDir = Directory('${documentsDir.path}/$_folderName');
            }
          }
        } catch (e) {
          logger.error('Error accessing external storage: $e');
          // Fallback to Documents directory
          final documentsDir = await getApplicationDocumentsDirectory();
          storageDir = Directory('${documentsDir.path}/$_folderName');
        }
      } else {
        // On desktop/iOS, use Documents directory
        final documentsDir = await getApplicationDocumentsDirectory();
        storageDir = Directory('${documentsDir.path}/$_folderName');
      }
    }
    
    // Create directory if it doesn't exist
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    
    return storageDir;
  }

  // Helper to check if we can create a directory
  Future<bool> _canCreateDirectory(Directory dir) async {
    try {
      await dir.create(recursive: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Set a custom storage path
  Future<bool> setCustomStoragePath(String path) async {
    try {
      final directory = Directory(path);
      
      // Validate that the directory exists or can be created
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customPathKey, path);
      logger.info('Custom storage path set to: $path');
      return true;
    } catch (e) {
      logger.error('Error setting custom storage path: $e');
      return false;
    }
  }

  // Reset to default storage path
  Future<void> resetToDefaultPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customPathKey);
    logger.info('Storage path reset to default');
  }

  // Get the current custom path (null if using default)
  Future<String?> getCustomStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customPathKey);
  }

  // Generate a safe filename from entry ID
  String _getSafeFilename(String id, {String extension = 'ics'}) {
    // Remove any characters that aren't safe for filenames
    final safe = id.replaceAll(RegExp(r'[^\w\-]'), '_');
    return '$safe.$extension';
  }

  // Save an entry to a file
  Future<File> saveEntry(DiaryEntry entry, {String fileFormat = 'ics', String timezone = 'UTC', int durationMinutes = 15}) async {
    final directory = await _getStorageDirectory();
    final filename = _getSafeFilename(entry.id, extension: fileFormat);
    final file = File('${directory.path}/$filename');
    
    // All formats use iCalendar format
    final content = ICalendarGenerator.generate(entry, durationMinutes: durationMinutes);
    
    await file.writeAsString(content);
    
    return file;
  }

  // Delete an entry file
  Future<bool> deleteEntry(String entryId) async {
    try {
      final directory = await _getStorageDirectory();
      
      // Try all extensions
      for (final ext in ['ics', 'txt', 'md']) {
        final filename = _getSafeFilename(entryId, extension: ext);
        final file = File('${directory.path}/$filename');
        
        if (await file.exists()) {
          await file.delete();
          logger.info('Entry deleted: ${file.path}');
          return true;
        }
      }
      return false;
    } catch (e) {
      logger.error('Error deleting entry: $e');
      return false;
    }
  }

  // Load all entries from files
  Future<List<DiaryEntry>> loadAllEntries() async {
    try {
      final directory = await _getStorageDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.ics') || file.path.endsWith('.txt') || file.path.endsWith('.md'))
          .toList();
      
      final entries = <DiaryEntry>[];
      
      for (final file in files) {
        try {
          final entry = await _parseEntryFile(file);
          if (entry != null) {
            entries.add(entry);
          }
        } catch (e) {
          logger.error('Error parsing file ${file.path}: $e');
        }
      }
      
      // Sort by creation date, newest first
      entries.sort((a, b) => b.dtstart.compareTo(a.dtstart));
      
      return entries;
    } catch (e) {
      logger.error('Error loading entries: $e');
      return [];
    }
  }

  // Parse iCalendar DateTime (YYYYMMDDTHHMMSSZ format)
  DateTime? _parseICalDateTime(String value) {
    try {
      // Remove the 'Z' at the end if present
      final cleanValue = value.replaceAll('Z', '');
      
      if (cleanValue.length >= 15) {
        final year = int.parse(cleanValue.substring(0, 4));
        final month = int.parse(cleanValue.substring(4, 6));
        final day = int.parse(cleanValue.substring(6, 8));
        final hour = int.parse(cleanValue.substring(9, 11));
        final minute = int.parse(cleanValue.substring(11, 13));
        final second = int.parse(cleanValue.substring(13, 15));
        
        return DateTime.utc(year, month, day, hour, minute, second);
      }
    } catch (e) {
      logger.error('Error parsing iCal DateTime: $value - $e');
    }
    return null;
  }

  // Parse an entry from an iCalendar file
  Future<DiaryEntry?> _parseEntryFile(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.split('\n').map((l) => l.trim()).toList();
      
      String? uid;
      String? summary;
      String? description;
      DateTime? dtstart;
      DateTime? dtstamp;
      String? location;
      double? latitude;
      double? longitude;
      List<String> categories = [];
      List<DateTime> appendDates = [];
      List<String> appendMoods = [];
      List<String> appendLocations = [];
      List<double?> appendLatitudes = [];
      List<double?> appendLongitudes = [];
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
        
        // Check for X-APPEND properties first
        if (line.startsWith('X-APPENDDATE:')) {
          // Format: X-APPENDDATE:1;20251227T131608Z
          final parts = value.split(';');
          if (parts.length == 2) {
            final index = int.tryParse(parts[0]);
            final dateTime = _parseICalDateTime(parts[1]);
            if (index != null && dateTime != null) {
              appendData.putIfAbsent(index, () => {});
              appendData[index]!['date'] = dateTime;
            }
          }
          continue;
        }
        
        if (line.startsWith('X-APPENDMOOD:')) {
          // Format: X-APPENDMOOD:1;happy
          final parts = value.split(';');
          if (parts.length == 2) {
            final index = int.tryParse(parts[0]);
            if (index != null) {
              appendData.putIfAbsent(index, () => {});
              appendData[index]!['mood'] = parts[1];
            }
          }
          continue;
        }
        
        if (line.startsWith('X-APPENDLOC:')) {
          // Format: X-APPENDLOC:1;Coffee Shop
          final parts = value.split(';');
          if (parts.length >= 2) {
            final index = int.tryParse(parts[0]);
            if (index != null) {
              appendData.putIfAbsent(index, () => {});
              // Join back in case location had semicolons
              appendData[index]!['location'] = parts.sublist(1).join(';');
            }
          }
          continue;
        }
        
        if (line.startsWith('X-APPENDGEO:')) {
          // Format: X-APPENDGEO:1;40.712776;-74.005974
          final parts = value.split(';');
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
          continue;
        }
        
        switch (key.split(';').first) { // Remove parameters like TZID
          case 'UID':
            uid = value;
            break;
          case 'SUMMARY':
            summary = value;
            break;
          case 'DESCRIPTION':
            // Unescape special characters - must match escaping order in reverse!
            description = value
                .replaceAll('\\\\', '\\')  // Unescape backslashes first
                .replaceAll('\\n', '\n')   // Then unescape newlines
                .replaceAll('\\,', ',')
                .replaceAll('\\;', ';');
            break;
          case 'DTSTART':
            dtstart = _parseICalDateTime(value);
            break;
          case 'DTSTAMP':
            dtstamp = _parseICalDateTime(value);
            break;
          case 'LOCATION':
            location = value;
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
          case 'EXDATE':
            final exdate = _parseICalDateTime(value);
            if (exdate != null) {
              appendDates.add(exdate);
            }
            break;
          case 'ATTACH':
            attachments.add(value);
            break;
        }
      }
      
      // Convert grouped append data to lists, sorted by index
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
        logger.info('Missing required fields in file: ${file.path}');
        return null;
      }
      
      // Extract mood from categories (assume first category is mood)
      String mood = 'neutral';
      if (categories.isNotEmpty) {
        // Check if any category matches a known mood
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
        mood: mood,
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
      logger.error('Error parsing entry file: $e');
      return null;
    }
  }

  // Get the storage directory path for display purposes
  Future<String> getStoragePath() async {
    final directory = await _getStorageDirectory();
    return directory.path;
  }

  // Move all entries to a new location
  Future<bool> moveEntriesToNewLocation(String newPath) async {
    try {
      // Load all current entries
      final entries = await loadAllEntries();
      final oldPath = await getStoragePath();
      
      // Set new path
      final success = await setCustomStoragePath(newPath);
      if (!success) return false;
      
      // Save all entries to new location
      for (final entry in entries) {
        await saveEntry(entry);
      }
      logger.info('Moved ${entries.length} entries to: $newPath');
      return true;
    } catch (e) {
      logger.error('Error moving entries: $e');
      return false;
    }
  }
}