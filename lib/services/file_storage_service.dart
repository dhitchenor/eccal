import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import '../services/icalendar_generator.dart';
import '../services/icalendar_parser.dart';
import '../services/logger_service.dart';
import '../utils/saf_helper.dart';

class FileStorageService {
  static const String _folderName = 'eccal_entries';
  static const String _safUriKey = 'saf_tree_uri';
  static const String _storageSetupShownKey = 'storage_setup_dialog_shown';
  static const String _customPathKey = 'custom_storage_path';

  // Initialize and verify storage (call during app startup)
  Future<void> initialize() async {
    // Get default directory ONCE and cache it
    final defaultDir = await _getDefaultStorageDirectory();

    // On Android, check if SAF is configured first
    if (Platform.isAndroid) {
      final isSafConfigured = await this.isSafConfigured();
      if (isSafConfigured) {
        final safUri = await getSafUri();
        // Verify we still have access to SAF
        final hasAccess = await SafHelper.checkAccess(safUri!);
        if (hasAccess) {
          logger.debug('SAF configured and accessible');
          // Get SAF display path for logging
          final displayName = await SafHelper.getDisplayName(safUri);
          logger.debug('Storage path: $displayName/eccal_entries (SAF)');
        } else {
          logger.debug(
            'SAF configured but access lost - will use default storage',
          );
          logger.debug('Storage path verified: ${defaultDir.path}');
        }
      } else {
        logger.debug('Using default storage (SAF not configured)');
        logger.debug('Storage path verified: ${defaultDir.path}');
      }
    } else {
      // Desktop/iOS - just log the default path
      logger.debug('Storage path verified: ${defaultDir.path}');
    }

    // Ensure directory exists (reuse cached defaultDir)
    if (!await defaultDir.exists()) {
      await defaultDir.create(recursive: true);
      logger.debug('Created storage directory: ${defaultDir.path}');
    }
  }

  /// Check if SAF is configured (Android only)
  Future<bool> isSafConfigured() async {
    if (!Platform.isAndroid) return false;

    final prefs = await SharedPreferences.getInstance();
    final uri = prefs.getString(_safUriKey);

    if (uri == null) return false;

    // Verify we still have access
    try {
      return await SafHelper.checkAccess(uri);
    } catch (e) {
      logger.error('Error checking SAF access: $e');
      return false;
    }
  }

  /// Get the SAF tree URI (Android only)
  Future<String?> getSafUri() async {
    if (!Platform.isAndroid) return null;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_safUriKey);
  }

  /// Pick a directory using SAF and save the URI (Android only)
  Future<String?> pickAndSaveDirectory() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF is only available on Android');
    }

    try {
      final uri = await SafHelper.pickDirectory();
      if (uri == null) {
        logger.info('User cancelled directory selection');
        return null;
      }

      // Validate the URI - block Downloads folder
      if (uri.contains('/Download') || uri.contains('%3ADownload')) {
        logger.info('Downloads folder blocked for SAF');
        return 'DOWNLOADS_BLOCKED';
      }

      // Save the URI
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_safUriKey, uri);

      logger.info('SAF directory saved: $uri');
      return uri;
    } catch (e) {
      logger.error('Error picking SAF directory: $e');
      rethrow;
    }
  }

  /// Reset SAF configuration (Android only)
  Future<void> resetSafConfiguration() async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_safUriKey);
    logger.info('SAF configuration reset');
  }

  /// Get the default storage directory (non-SAF fallback)
  Future<Directory> _getDefaultStorageDirectory() async {
    // Check for custom path first (desktop/iOS)
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(_customPathKey);

    if (customPath != null && customPath.isNotEmpty) {
      final customDir = Directory(customPath);
      if (await customDir.exists()) {
        logger.info('Using custom storage path: $customPath');
        return customDir;
      }
    }

    if (Platform.isAndroid) {
      // Use app-specific external storage (accessible via file manager)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final dir = Directory('${externalDir.path}/$_folderName');
        logger.info('Using Android external storage: ${dir.path}');
        return dir;
      }
    }

    // Fallback to documents directory
    final documentsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${documentsDir.path}/$_folderName');
    logger.info('Using documents directory: ${dir.path}');
    return dir;
  }

  /// Save a diary entry (for regular storage only)
  /// For exports, use ExportService instead
  Future<String> saveEntry(
    DiaryEntry entry, {
    String? fileFormat,
    String? timezone,
    int? durationMinutes,
  }) async {
    try {
      // Regular saves always use .ics format with ID-based filename
      final fileName = '${entry.id}.ics';
      final content = ICalendarGenerator.generate(
        entry,
        durationMinutes: durationMinutes ?? 15,
      );

      // Try SAF first on Android
      if (Platform.isAndroid) {
        final safUri = await getSafUri();
        if (safUri != null) {
          try {
            // Get the local entry location which includes subfolder
            final location = await getLocalEntryLocation();

            await SafHelper.writeFile(
              treeUri: safUri,
              fileName: fileName,
              content: content,
              subfolder: location.subfolder,
            );
            logger.info(
              'Entry saved via SAF: $fileName in ${location.subfolder}',
            );
            return fileName;
          } catch (e) {
            logger.error(
              'SAF write failed, falling back to default storage: $e',
            );
            // Fall through to default storage
          }
        }
      }

      // Fallback to default storage
      final storageDir = await _getDefaultStorageDirectory();
      if (!await storageDir.exists()) {
        await storageDir.create(recursive: true);
      }

      final file = File('${storageDir.path}/$fileName');
      await file.writeAsString(content);
      logger.info('Entry saved to default storage: ${file.path}');
      return file.path;
    } catch (e) {
      logger.error('Error saving entry: $e');
      rethrow;
    }
  }

  /// Load all diary entries
  Future<List<DiaryEntry>> loadAllEntries() async {
    final entries = <DiaryEntry>[];

    try {
      // Try SAF first on Android
      if (Platform.isAndroid) {
        final safUri = await getSafUri();
        if (safUri != null) {
          try {
            // Get location with subfolder
            final location = await getLocalEntryLocation();

            final fileNames = await SafHelper.listFiles(
              safUri,
              subfolder: location.subfolder, // Use eccal_entries subfolder
            );
            logger.info(
              'Found ${fileNames.length} files via SAF in ${location.subfolder}',
            );

            for (final fileName in fileNames) {
              try {
                final content = await SafHelper.readFile(
                  treeUri: safUri,
                  fileName: fileName,
                  subfolder: location.subfolder,
                );

                final entry = ICalendarParser.parse(content);
                if (entry != null) {
                  entries.add(entry);
                }
              } catch (e) {
                logger.error('Error parsing file $fileName: $e');
              }
            }

            return entries;
          } catch (e) {
            logger.error(
              'SAF read failed, falling back to default storage: $e',
            );
            // Fall through to default storage
          }
        }
      }

      // Fallback to default storage
      final storageDir = await _getDefaultStorageDirectory();
      if (!await storageDir.exists()) {
        logger.info('Storage directory does not exist yet');
        return entries;
      }

      final files = storageDir
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.ics'))
          .cast<File>();

      logger.info('Found ${files.length} files in default storage');

      for (final file in files) {
        try {
          final content = await file.readAsString();
          final entry = ICalendarParser.parse(content);
          if (entry != null) {
            entries.add(entry);
          }
        } catch (e) {
          logger.error('Error parsing file ${file.path}: $e');
        }
      }
    } catch (e) {
      logger.error('Error loading entries: $e');
    }

    return entries;
  }

  /// Delete a diary entry
  Future<void> deleteEntry(String entryId) async {
    try {
      final fileName = '$entryId.ics';

      // Try SAF first on Android
      if (Platform.isAndroid) {
        final safUri = await getSafUri();
        if (safUri != null) {
          try {
            // Get location with subfolder
            final location = await getLocalEntryLocation();

            final deleted = await SafHelper.deleteFile(
              treeUri: safUri,
              fileName: fileName,
              subfolder:
                  location.subfolder, // Delete from eccal_entries subfolder
            );
            if (deleted) {
              logger.info(
                'Entry deleted via SAF: $fileName from ${location.subfolder}',
              );
              return;
            }
          } catch (e) {
            logger.error(
              'SAF delete failed, falling back to default storage: $e',
            );
            // Fall through to default storage
          }
        }
      }

      // Fallback to default storage
      final storageDir = await _getDefaultStorageDirectory();
      final file = File('${storageDir.path}/$fileName');

      if (await file.exists()) {
        await file.delete();
        logger.info('Entry deleted from default storage: ${file.path}');
      }
    } catch (e) {
      logger.error('Error deleting entry: $e');
      rethrow;
    }
  }

  /// Get current storage location description for UI
  Future<String> getStorageLocationDescription() async {
    if (Platform.isAndroid) {
      final safUri = await getSafUri();
      if (safUri != null) {
        // Get the display name from SAF
        final displayName = await SafHelper.getDisplayName(safUri);
        if (displayName != null && displayName.isNotEmpty) {
          return '$displayName/eccal_entries';
        }

        // Fallback: Try to extract a readable path from the URI
        if (safUri.contains('Documents')) {
          return 'Documents/eccal_entries';
        } else if (safUri.contains('Download')) {
          return 'Downloads/eccal_entries';
        } else {
          // Try to decode the last part of the URI
          final decoded = Uri.decodeComponent(safUri);
          final parts = decoded.split('/');
          if (parts.isNotEmpty) {
            final lastPart = parts.last.replaceAll('%3A', '/');
            return '$lastPart/eccal_entries';
          }
          return 'Custom Storage/eccal_entries';
        }
      }
    }

    final dir = await _getDefaultStorageDirectory();
    return dir.path;
  }

  // ===== Methods needed by other files =====

  /// Check if storage setup dialog should be shown (first launch only)
  Future<bool> shouldShowStorageSetupDialog() async {
    if (!Platform.isAndroid) return false;

    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_storageSetupShownKey) ?? false;

    // Only show if we haven't shown it before
    return !hasShown;
  }

  /// Mark storage setup dialog as shown
  Future<void> markStorageSetupDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageSetupShownKey, true);
  }

  /// Get storage path for display (used by diary_provider)
  Future<String> getStoragePath() async {
    return await getStorageLocationDescription();
  }

  /// Move entries to new location (used by settings and diary_provider)
  Future<bool> moveEntriesToNewLocation(String newPath) async {
    try {
      logger.info('Moving entries to new location: $newPath');

      // On Android, if using SAF, the path is already managed
      if (Platform.isAndroid) {
        final safUri = await getSafUri();
        if (safUri != null) {
          logger.info(
            'Android: Using SAF, entries already in correct location',
          );
          return true;
        }
      }

      // Desktop/iOS OR Android without SAF: actually move files
      final oldDir = await _getDefaultStorageDirectory();
      final newDir = Directory('$newPath/eccal_entries');

      logger.info('Moving from ${oldDir.path} to ${newDir.path}');

      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
      }

      // Copy all .ics files to new location
      if (await oldDir.exists()) {
        final files = oldDir
            .listSync()
            .where((entity) => entity is File && entity.path.endsWith('.ics'))
            .cast<File>();

        logger.info('Found ${files.length} files to move');

        for (final file in files) {
          final fileName = file.path.split('/').last;
          final newFile = File('${newDir.path}/$fileName');
          await file.copy(newFile.path);
          logger.info('Copied: $fileName');
        }
      }

      // Save new custom path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customPathKey, '${newDir.path}');
      logger.info('Saved new custom path: ${newDir.path}');

      return true;
    } catch (e) {
      logger.error('Error moving entries: $e');
      return false;
    }
  }

  /// Reset to default path (used by settings and diary_provider)
  Future<void> resetToDefaultPath() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove custom path
    await prefs.remove(_customPathKey);

    // On Android, also reset SAF configuration
    if (Platform.isAndroid) {
      await resetSafConfiguration();
    }

    logger.info('Reset to default storage path');
  }

  /// Get base storage location (SAF or default)
  Future<ExportLocation> _getBaseLocation() async {
    if (Platform.isAndroid) {
      final safUri = await getSafUri();

      if (safUri != null) {
        // User has SAF configured
        final description = await getStorageLocationDescription();
        return ExportLocation(
          directory: '', // Not used for SAF
          safUri: safUri,
          description: description,
        );
      } else {
        // No SAF - use external storage
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return ExportLocation(
            directory: externalDir.path,
            safUri: null,
            description: 'App Storage',
          );
        } else {
          final docsDir = await getApplicationDocumentsDirectory();
          return ExportLocation(
            directory: docsDir.path,
            safUri: null,
            description: 'Documents',
          );
        }
      }
    } else {
      // Desktop/iOS: use Documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      return ExportLocation(
        directory: documentsDir.path,
        safUri: null,
        description: documentsDir.path,
      );
    }
  }

  /// Get location for diary entries (eccal_entries subfolder)
  Future<ExportLocation> getLocalEntryLocation() async {
    final base = await _getBaseLocation();

    if (base.useSaf) {
      // SAF: Create/use eccal_entries subfolder
      return ExportLocation(
        directory: '',
        safUri: base.safUri,
        description: '${base.description}/eccal_entries',
        subfolder: 'eccal_entries',
      );
    } else {
      // File system: Create eccal_entries directory
      final entryDir = Directory('${base.directory}/eccal_entries');
      if (!await entryDir.exists()) {
        await entryDir.create(recursive: true);
      }
      return ExportLocation(
        directory: entryDir.path,
        safUri: null,
        description: '${base.description}/eccal_entries',
      );
    }
  }

  /// Get location for exports (eccal_exports subfolder)
  Future<ExportLocation> getExportLocation() async {
    final base = await _getBaseLocation();

    if (base.useSaf) {
      // SAF: Create/use eccal_exports subfolder
      return ExportLocation(
        directory: '',
        safUri: base.safUri,
        description: '${base.description}/eccal_exports',
        subfolder: 'eccal_exports',
      );
    } else {
      // File system: Create eccal_exports directory
      final exportDir = Directory('${base.directory}/eccal_exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      return ExportLocation(
        directory: exportDir.path,
        safUri: null,
        description: '${base.description}/eccal_exports',
      );
    }
  }

  /// Get location for logs (eccal_logs subfolder)
  Future<ExportLocation> getLogsLocation() async {
    final base = await _getBaseLocation();

    if (base.useSaf) {
      // SAF: Create/use eccal_logs subfolder
      return ExportLocation(
        directory: '',
        safUri: base.safUri,
        description: '${base.description}/eccal_logs',
        subfolder: 'eccal_logs',
      );
    } else {
      // File system: Create eccal_logs directory
      final logsDir = Directory('${base.directory}/eccal_logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      return ExportLocation(
        directory: logsDir.path,
        safUri: null,
        description: '${base.description}/eccal_logs',
      );
    }
  }
}

/// Export location information
class ExportLocation {
  final String directory; // File system path (empty if using SAF)
  final String? safUri; // SAF tree URI (null if not using SAF)
  final String description; // Human-readable description
  final String? subfolder; // Subfolder name for SAF (null for root)

  ExportLocation({
    required this.directory,
    required this.safUri,
    required this.description,
    this.subfolder,
  });

  bool get useSaf => safUri != null;
}
