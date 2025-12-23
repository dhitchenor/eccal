# Logger Service Usage Guide

This guide explains how to use the `LoggerService` for debugging, error tracking, and monitoring in the EcCal application.

## Table of Contents
- [Quick Start](#quick-start)
- [Log Levels](#log-levels)
- [Logging Methods](#logging-methods)
- [Configuration](#configuration)
- [Log Files](#log-files)
- [Best Practices](#best-practices)

---

## Quick Start

### Basic Usage

```dart
import '../services/logger_service.dart';

// Log at different levels
logger.info('User opened settings screen');
logger.error('Failed to connect to CalDAV server');
logger.debug('Sync operation details: entries=${entries.length}');
```

### Initialization

The logger is automatically initialized on app startup in `main.dart`:

```dart
// In main.dart
await logger.initialize(LogLevel.debug);
```

**Note:** The logger auto-initializes if you use it before calling `initialize()`.

---

## Log Levels

### `LogLevel.none`
**No logging** - completely disables the logger.

```dart
await logger.initialize(LogLevel.none);
```

**When to use:** Production releases where logging is not needed.

---

### `LogLevel.info`
**General information only** - logs important application events.

```dart
await logger.initialize(LogLevel.info);

// What gets logged:
logger.info('App started');              // ✓ Logged
logger.error('Connection failed');       // ✗ Not logged
logger.debug('Processing entry 42');     // ✗ Not logged
```

**Logs:**
- App lifecycle events (startup, shutdown)
- User actions (opened screen, saved entry)
- Server connection status
- Sync completed/started

**When to use:** Production releases with minimal logging.

---

### `LogLevel.error`
**Errors and general info** - logs errors and important events.

```dart
await logger.initialize(LogLevel.error);

// What gets logged:
logger.info('App started');              // ✓ Logged
logger.error('Connection failed');       // ✓ Logged
logger.debug('Processing entry 42');     // ✗ Not logged
```

**Logs:**
- Everything from `info` level
- Error conditions
- Failed operations
- Exception details

**When to use:** Production releases where you want error tracking.

---

### `LogLevel.debug`
**Everything** - logs all messages including verbose debugging.

```dart
await logger.initialize(LogLevel.debug);

// What gets logged:
logger.info('App started');              // ✓ Logged
logger.error('Connection failed');       // ✓ Logged
logger.debug('Processing entry 42');     // ✓ Logged
```

**Logs:**
- Everything from `info` and `error` levels
- Detailed operation information
- Variable values
- Function call traces
- State changes

**When to use:** Development and debugging.

---

## Logging Methods

### `info(String message)`
Log general information about application events.

```dart
logger.info('User logged into CalDAV server');
logger.info('Loaded ${entries.length} entries from storage');
logger.info('Background sync started');
```

**Use for:**
- User actions
- App state changes
- Successful operations
- Milestone events

---

### `error(String message)`
Log error conditions and failures.

```dart
logger.error('Failed to connect to server: ${e.toString()}');
logger.error('CalDAV authentication failed for user: $username');
logger.error('Storage permission denied');
```

**Use for:**
- Exceptions and errors
- Failed operations
- Authentication failures
- Network errors

**Tip:** Include error details in the message.

---

### `debug(String message)`
Log detailed debugging information.

```dart
logger.debug('Sync operation started with ${entries.length} entries');
logger.debug('CalDAV URL: $url, Username: $username');
logger.debug('Processing entry: ${entry.toJson()}');
```

**Use for:**
- Variable values
- Detailed operation flow
- State dumps
- Performance metrics

**Tip:** Be verbose - debug logs help troubleshooting.

---

### `log()` - Multi-level logging
Log at multiple levels in one call.

```dart
logger.log(
  info: 'Sync started',
  debug: 'Server URL: $url, Entries: ${entries.length}',
);

logger.log(
  error: 'Sync failed: ${e.toString()}',
  debug: 'Full error details: ${e.stackTrace}',
);
```

**Use for:**
- Complex operations where you want different detail levels
- Operations that should log at multiple levels

---

## Configuration

### Change Log Level at Runtime

```dart
import '../providers/settings_provider.dart';

// User changes log level in settings
settings.setLogLevel(LogLevel.info);

// Logger automatically adjusts
logger.setLogLevel(LogLevel.info);
```

**Behavior:**
- Changing to `LogLevel.none` stops all logging
- Changing from `LogLevel.none` to any other level initializes the logger
- Level changes are logged automatically

---

### Get Current Log File Path

```dart
final path = logger.getLogFilePath();
if (path != null) {
  print('Logs are being written to: $path');
}
```

**Returns:** Absolute path to current log file, or `null` if logging is disabled.

---

## Log Files

### Location

**Android:**
```
/storage/emulated/0/Android/data/com.voryzen.eccal/files/eccal_logs/
```

**Desktop/iOS:**
```
{ApplicationDocumentsDirectory}/eccal_logs/
```

### File Format

```
eccal_logs/
├── eccal_2025-01-22.log
├── eccal_2025-01-23.log
└── eccal_2025-01-24.log
```

**Naming:** `eccal_YYYY-MM-DD.log` (one file per day)

---

### Log Entry Format

```
[2025-01-22 14:35:42.123] [INFO ] User opened settings screen
[2025-01-22 14:35:45.456] [ERROR] Failed to connect to CalDAV server
[2025-01-22 14:35:46.789] [DEBUG] Sync operation details: entries=42
```

**Format:** `[timestamp] [level] message`
- **Timestamp:** `YYYY-MM-DD HH:mm:ss.SSS`
- **Level:** `INFO`, `ERROR`, `DEBUG` (padded to 5 chars)
- **Message:** Log message (newlines are replaced with spaces)

---

### Export Logs

Export all log files to user-configured storage location:

```dart
final path = await logger.exportLogs();
if (path != null) {
  print('Logs exported to: $path');
} else {
  print('No logs to export');
}
```

**Export file format:**
```
eccal_logs_2025-01-22_14-35-42.txt
```

**Contents:**
```
EcCal Logs Export
Exported at: 2025-01-22 14:35:42
Log Level: debug
=========================

--- eccal_2025-01-22.log ---
[2025-01-22 14:35:42.123] [INFO ] App started
[2025-01-22 14:35:45.456] [ERROR] Connection failed
...

--- eccal_2025-01-23.log ---
...
```

**Export location:**
- Android SAF: User's selected folder + `/eccal_logs/` subfolder
- Desktop: User's selected folder + `/eccal_logs/` subfolder

---

### Clear Old Logs

Automatically delete log files older than N days:

```dart
// Keep logs from last 7 days (default)
await logger.clearOldLogs(keepDays: 7);

// Keep logs from last 30 days
await logger.clearOldLogs(keepDays: 30);
```

**Behavior:**
- Checks all log files in `eccal_logs/` directory
- Deletes files older than the cutoff date
- Logs deletion operations

**When to use:** Periodic cleanup to prevent storage bloat.

---

### Get All Log Files

```dart
final logFiles = await logger.getAllLogFiles();
print('Found ${logFiles.length} log files');

for (final file in logFiles) {
  final stat = await file.stat();
  print('${file.path}: ${stat.size} bytes, modified ${stat.modified}');
}
```

**Returns:** List of `File` objects for all `.log` files.

---

## Best Practices

### 1. Choose Appropriate Log Levels

```dart
// ✓ Good
logger.info('User saved diary entry');
logger.error('Failed to sync with server: ${e.toString()}');
logger.debug('Entry data: ${entry.toJson()}');

// ✗ Bad
logger.debug('User saved diary entry');  // Too verbose for info
logger.info('x=42, y=100, z=true');      // Too detailed for info
```

**Guidelines:**
- `info`: Important events users/admins care about
- `error`: Things that went wrong
- `debug`: Everything else

---

### 2. Include Context in Error Messages

```dart
// ✓ Good
logger.error('Failed to connect to CalDAV server at $url: ${e.toString()}');
logger.error('Sync failed for entry ${entry.id}: ${e.message}');

// ✗ Bad
logger.error('Connection failed');
logger.error('Error: $e');
```

**Include:**
- What operation failed
- Relevant identifiers (URLs, IDs, usernames)
- Error details from exceptions

---

### 3. Use Debug Level Generously

```dart
void syncEntries() async {
  logger.debug('Starting sync with ${entries.length} entries');

  for (final entry in entries) {
    logger.debug('Processing entry ${entry.id}');
    // ... sync logic ...
  }

  logger.debug('Sync completed successfully');
}
```

**Benefits:**
- Easy troubleshooting
- Track execution flow
- Identify bottlenecks

---

### 4. Sanitize Sensitive Data

```dart
// ✓ Good
logger.debug('CalDAV URL: $url, Username: $username');
logger.info('Authenticated as $username');

// ✗ Bad
logger.debug('CalDAV credentials: $username:$password');
logger.debug('Password: $password');
```

**Never log:**
- Passwords
- API keys
- Auth tokens
- Personal data (unless debugging user-reported issues)

---

### 5. Use try-catch with Logging

```dart
try {
  await syncWithCalDAV();
  logger.info('CalDAV sync completed');
} catch (e, stackTrace) {
  logger.error('CalDAV sync failed: $e');
  logger.debug('Stack trace: $stackTrace');
  rethrow;
}
```

**Pattern:**
- Log success at `info` level
- Log errors at `error` level
- Log stack traces at `debug` level

---

### 6. Log State Changes

```dart
void setCalendarProvider(CalendarProvider provider) {
  logger.info('Calendar provider changed from $_provider to $provider');
  _provider = provider;
}

void setCaldavSyncDisabled(bool disabled) {
  logger.info('CalDAV sync ${disabled ? "disabled" : "enabled"}');
  _syncDisabled = disabled;
}
```

**Log when:**
- Settings change
- User actions occur
- App state transitions

---

### 7. Performance-Critical Code

```dart
// ✓ Good - Only log at debug level
for (final entry in entries) {
  logger.debug('Processing entry ${entry.id}');
  // ... fast operation ...
}

// ✗ Bad - Don't log in tight loops at info/error level
for (final entry in largeList) {
  logger.info('Processing entry ${entry.id}');  // Too much overhead
}
```

**Guidelines:**
- Use `debug` level in loops
- Minimize logging in performance-critical paths
- Log summaries instead of individual items

---

### 8. Initialization Sequence

```dart
// In main.dart or app initialization
Future<void> _performFullInitialization() async {
  // 1. Initialize logger FIRST
  await logger.initialize(LogLevel.debug);

  // 2. Log initialization steps
  logger.info('App initialization started');

  await widget.settingsProvider.initialize();
  logger.info('Settings loaded');

  await widget.diaryProvider.initialize();
  logger.info('Diary provider initialized');

  logger.info('App initialization completed');
}
```

**Pattern:**
- Initialize logger before other services
- Log each initialization step
- Log completion

---

## Common Patterns

### Server Operations

```dart
Future<void> syncWithServer() async {
  logger.info('Starting server sync');
  logger.debug('Server URL: $url, Calendar: $calendarName');

  try {
    final entries = await fetchEntries();
    logger.debug('Fetched ${entries.length} entries from server');

    await saveEntries(entries);
    logger.info('Server sync completed: ${entries.length} entries');
  } catch (e) {
    logger.error('Server sync failed: $e');
    logger.debug('Error details: ${e.toString()}');
    rethrow;
  }
}
```

---

### User Actions

```dart
void onSaveEntry(DiaryEntry entry) {
  logger.info('User saved entry: ${entry.id}');
  logger.debug('Entry details: title="${entry.title}", date=${entry.date}');

  try {
    saveToStorage(entry);
    logger.info('Entry saved to storage: ${entry.id}');
  } catch (e) {
    logger.error('Failed to save entry ${entry.id}: $e');
    showError(context, 'Failed to save entry');
  }
}
```

---

### Async Operations

```dart
Future<void> loadEntries() async {
  final stopwatch = Stopwatch()..start();
  logger.debug('Loading entries from storage');

  try {
    final entries = await storage.loadAll();
    logger.info('Loaded ${entries.length} entries in ${stopwatch.elapsedMilliseconds}ms');
  } catch (e) {
    logger.error('Failed to load entries after ${stopwatch.elapsedMilliseconds}ms: $e');
    rethrow;
  }
}
```

---

## Troubleshooting

### Logs Not Being Written

**Check:**
1. Log level is not `LogLevel.none`
2. App has storage permissions (Android)
3. Logger was initialized: `await logger.initialize(LogLevel.debug)`

**Debug:**
```dart
print('Log file: ${logger.getLogFilePath()}');
```

---

### Can't Find Log Files

**Desktop/iOS:**
```dart
final docsDir = await getApplicationDocumentsDirectory();
print('Documents directory: ${docsDir.path}/eccal_logs');
```

**Android:**
```dart
final extDir = await getExternalStorageDirectory();
print('External storage: ${extDir?.path}/eccal_logs');
```

---

### Export Fails

**Common causes:**
1. No storage location configured (Settings → Local → Storage Location)
2. Storage permissions denied
3. No log files exist (logging was disabled)

**Check:**
```dart
final files = await logger.getAllLogFiles();
if (files.isEmpty) {
  print('No log files to export');
}
```

---

## Migration from Print Statements

**Before:**
```dart
print('Starting sync...');
print('Error: $e');
print('Debug: x=$x, y=$y');
```

**After:**
```dart
logger.info('Starting sync');
logger.error('Sync failed: $e');
logger.debug('State: x=$x, y=$y');
```

**Benefits:**
- Logs saved to files
- Level-based filtering
- Consistent formatting
- Export functionality

---

## Complete Example

```dart
import '../services/logger_service.dart';

class CalDAVService {
  Future<void> syncWithServer(String url, String username, String password) async {
    logger.info('CalDAV sync started');
    logger.debug('Server: $url, User: $username');

    try {
      // Connect
      logger.debug('Connecting to CalDAV server...');
      final client = await connect(url, username, password);
      logger.info('Connected to CalDAV server');

      // Fetch calendars
      logger.debug('Fetching calendar list...');
      final calendars = await client.listCalendars();
      logger.debug('Found ${calendars.length} calendars');

      // Sync each calendar
      for (final calendar in calendars) {
        logger.debug('Syncing calendar: ${calendar.name}');
        final entries = await fetchEntries(calendar);
        logger.debug('Calendar ${calendar.name}: ${entries.length} entries');
      }

      logger.info('CalDAV sync completed: ${calendars.length} calendars');
    } catch (e, stackTrace) {
      logger.error('CalDAV sync failed: $e');
      logger.debug('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
```

---

## Need More Help?

- Check `logger_service.dart` for implementation details
- See `main.dart` for initialization example
- Look at existing service files for usage patterns
- All logging is automatic once you call `logger.info/error/debug()`!
