import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'file_storage_service.dart';
import '../utils/saf_helper.dart';

// Log levels for filtering
enum LogLevel {
  none, // No logging
  info, // General info only (app opened, connected to server, etc)
  error, // Errors and general info (server not reachable, etc)
  debug, // Everything including verbose debugging
}

// Individual log entry
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  // Format for display and file writing
  String format() {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
    final levelStr = level.name.toUpperCase().padRight(5);
    return '[$dateStr] [$levelStr] $message';
  }
}

// Main logging service
class LoggerService {
  static const String _logsFolder = 'eccal_logs';
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  LogLevel _currentLevel =
      LogLevel.debug; // Default to debug for troubleshooting ADD TO CONFIG
  File? _logFile;
  bool _initialized = false;

  // Queue for sequential writes
  final List<String> _writeQueue = [];
  bool _isWriting = false;

  // Initialize the logger (call this on app startup)
  Future<void> initialize(LogLevel level) async {
    _currentLevel = level;

    if (level == LogLevel.none) {
      _initialized = true;
      return;
    }

    try {
      // Use absolutely guaranteed storage location
      Directory baseDir;
      if (Platform.isAndroid) {
        // Android: Use external storage directory (always accessible, no SAF)
        final externalDir = await getExternalStorageDirectory();
        baseDir = externalDir ?? await getApplicationDocumentsDirectory();
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      final logDir = Directory('${baseDir.path}/$_logsFolder');

      // Create logs directory if it doesn't exist
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Create log file with date
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logDir.path}/eccal_$dateStr.log');

      _initialized = true;

      // Log initialization
      _writeLog(LogLevel.info, 'Logger initialized at level: ${level.name}');
      _writeLog(LogLevel.info, 'Log file location: ${_logFile?.path}');
    } catch (e) {
      print('Failed to initialize logger: $e');
      _initialized = false;
    }
  }

  // Auto-initialize if not already done
  Future<void> _ensureInitialized() async {
    if (!_initialized && _currentLevel != LogLevel.none) {
      await initialize(_currentLevel);
    }
  }

  // Change log level at runtime
  void setLogLevel(LogLevel level) {
    final oldLevel = _currentLevel;
    _currentLevel = level;

    // If changing from none to something, or if never initialized, initialize now
    if (level != LogLevel.none && (!_initialized || _logFile == null)) {
      initialize(level);
    }

    if (level != LogLevel.none && _initialized) {
      _writeLog(
        LogLevel.info,
        'Log level changed from ${oldLevel.name} to ${level.name}',
      );
    }
  }

  // Check if a log level should be recorded
  bool _shouldLog(LogLevel messageLevel) {
    if (_currentLevel == LogLevel.none) return false;
    if (messageLevel == LogLevel.none) return false;

    switch (_currentLevel) {
      case LogLevel.none:
        return false;
      case LogLevel.info:
        return messageLevel == LogLevel.info;
      case LogLevel.error:
        return messageLevel == LogLevel.info || messageLevel == LogLevel.error;
      case LogLevel.debug:
        return true; // Log everything
    }
  }

  // Write log entry
  void _writeLog(LogLevel level, String message) {
    if (!_shouldLog(level)) return;

    // Auto-initialize if needed
    if (!_initialized) {
      _ensureInitialized().then((_) => _writeLog(level, message));
      return;
    }

    // Sanitize message - remove newlines and carriage returns
    final cleanMessage = message
        .replaceAll('\n', ' ')
        .replaceAll('\r', '')
        .trim();

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: cleanMessage,
    );

    // Print to console
    print(entry.format()); // Also print to console for debugging

    // Add to write queue
    if (_logFile != null) {
      _writeQueue.add('${entry.format()}\n');
      _processWriteQueue();
    }
  }

  // Process write queue sequentially
  Future<void> _processWriteQueue() async {
    if (_isWriting || _writeQueue.isEmpty || _logFile == null) return;

    _isWriting = true;

    while (_writeQueue.isNotEmpty) {
      final line = _writeQueue.removeAt(0);
      try {
        await _logFile!.writeAsString(line, mode: FileMode.append, flush: true);
      } catch (e) {
        print('Failed to write log: $e');
      }
    }

    _isWriting = false;
  }

  // Public logging methods
  void info(String message) {
    _writeLog(LogLevel.info, message);
  }

  void error(String message) {
    _writeLog(LogLevel.error, message);
  }

  void debug(String message) {
    _writeLog(LogLevel.debug, message);
  }

  // Multi-level logging in one call
  void log({String? info, String? error, String? debug}) {
    if (info != null) this.info(info);
    if (error != null) this.error(error);
    if (debug != null) this.debug(debug);
  }

  // Get log file path
  String? getLogFilePath() => _logFile?.path;

  // Get all log files in logs directory
  Future<List<File>> getAllLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/$_logsFolder');

      if (!await logDir.exists()) {
        return [];
      }

      final files = await logDir.list().toList();
      return files
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList();
    } catch (e) {
      print('Failed to get log files: $e');
      return [];
    }
  }

  // Export logs to user-configured location (with eccal_logs subfolder)
  Future<String?> exportLogs() async {
    try {
      final logFiles = await getAllLogFiles();

      if (logFiles.isEmpty) {
        return null;
      }

      // Get logs location from FileStorageService (eccal_logs subfolder)
      final fileStorage = FileStorageService();
      final location = await fileStorage.getLogsLocation();

      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final filename = 'eccal_logs_$timestamp.txt';

      final buffer = StringBuffer();
      buffer.writeln('EcCal Logs Export');
      buffer.writeln(
        'Exported at: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
      );
      buffer.writeln('Log Level: ${_currentLevel.name}');
      buffer.writeln('=' * 25);
      buffer.writeln();

      // Combine all log files
      for (final file in logFiles) {
        buffer.writeln('--- ${file.path.split('/').last} ---');
        final content = await file.readAsString();
        buffer.writeln(content);
        buffer.writeln();
      }

      final content = buffer.toString();

      // Write using SAF if available
      if (location.useSaf && location.safUri != null) {
        try {
          await SafHelper.writeFile(
            treeUri: location.safUri!,
            fileName: filename,
            content: content,
            subfolder: location.subfolder, // Pass subfolder for SAF
          );
          info('Logs exported via SAF: $filename in ${location.subfolder}');
          return filename;
        } catch (e) {
          error('SAF log export failed, falling back to file system: $e');
          // Fall through to file system write
        }
      }

      // Regular file system write
      final exportPath = '${location.directory}/$filename';
      final exportFile = File(exportPath);
      await exportFile.writeAsString(content);
      info('Logs exported to: $exportPath');
      return exportPath;
    } catch (e) {
      print('Failed to export logs: $e');
      return null;
    }
  }

  // Clear old log files (keep last N days)
  Future<void> clearOldLogs({int keepDays = 7}) async {
    try {
      final logFiles = await getAllLogFiles();
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

      for (final file in logFiles) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
          info('Deleted old log file: ${file.path.split('/').last}');
        }
      }
    } catch (e) {
      print('Failed to clear old logs: $e');
    }
  }
}

// Global logger instance for easy access
final logger = LoggerService();
