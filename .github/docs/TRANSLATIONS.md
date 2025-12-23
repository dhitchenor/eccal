# Translations & Localization Usage Guide

This guide explains how to use the localization system in EcCal for translating strings, formatting dates/times, and handling pluralization.

## Table of Contents
- [Quick Start](#quick-start)
- [String Translation](#string-translation)
- [Date & Time Formatting](#date--time-formatting)
- [Pluralization](#pluralization)
- [Timezones](#timezones)
- [Adding New Languages](#adding-new-languages)
- [Best Practices](#best-practices)

---

## Quick Start

### Basic String Translation

```dart
import '../utils/app_localizations.dart';

// Simple translation
Text('welcome'.tr())

// Translation with arguments
Text('greeting'.tr(['John']))  // "Hello, John!"
```

### Date Formatting

```dart
import '../utils/date_formatter.dart';

// Format with time
final text = DateFormatter.formatDateTime(
  entry.date,
  use24Hour: settings.use24HourFormat,
  timezone: settings.timezone,
);
// Output: "Dec 18, 2025 at 15:44 (AST)"

// Date only
final date = DateFormatter.formatDate(entry.date);
// Output: "Dec 18, 2025"
```

---

## String Translation

### `tr()` Extension Method

The primary way to translate strings.

```dart
// Basic translation
'app_name'.tr()                    // "EcCal"
'save'.tr()                        // "Save"
'cancel'.tr()                      // "Cancel"
```

**How it works:**
1. Looks up key in current language JSON file
2. Returns translated string
3. Falls back to key itself if not found

---

### Nested Keys (Dot Notation)

Organize translations hierarchically.

```dart
// Translation files use nested structure:
// {
//   "settings": {
//     "title": "Settings",
//     "save": "Save Settings"
//   }
// }

'settings.title'.tr()              // "Settings"
'settings.save'.tr()               // "Save Settings"
'display_settings.theme'.tr()      // "Theme"
```

**When to use:** Group related translations (settings, errors, moods, etc.)

---

### Translations with Arguments

Replace placeholders with dynamic values.

```dart
// Translation file:
// {
//   "greeting": "Hello, {0}!",
//   "items_count": "Found {0} items in {1}",
//   "user_info": "{0} logged in at {1}"
// }

'greeting'.tr(['Alice'])
// Output: "Hello, Alice!"

'items_count'.tr(['42', 'folder'])
// Output: "Found 42 items in folder"

'user_info'.tr([username, timestamp])
// Output: "John logged in at 2:30 PM"
```

**Placeholders:**
- Use `{0}`, `{1}`, `{2}`, etc.
- Pass arguments as `List<String>`
- Arguments are replaced in order

---

### Example Translations

```dart
// Simple
Text('save'.tr())
Text('cancel'.tr())
Text('delete'.tr())

// With context
Text('settings.general'.tr())
Text('error.network'.tr())
Text('mood.happy'.tr())

// With arguments
ErrorSnackbar.showError(
  context,
  'error.failed_to_load'.tr([filename]),
)
// "Failed to load example.ics"

Text('sync.status'.tr([entryCount.toString()]))
// "Synced 42 entries"
```

---

## Date & Time Formatting

### `DateFormatter.formatDateTime()`

Format date and time with timezone abbreviation.

```dart
DateFormatter.formatDateTime(
  dateTime,
  use24Hour: true,        // 24-hour or 12-hour format
  timezone: 'America/New_York',  // Timezone for abbreviation
)
```

**Output examples:**
```dart
// 24-hour format
"Dec 18, 2025 at 15:44 (EST)"

// 12-hour format (use24Hour: false)
"Dec 18, 2025 at 3:44 PM (EST)"

// UTC timezone
"Dec 18, 2025 at 20:44 (UTC)"
```

**Parameters:**
- `dateTime`: DateTime object to format
- `use24Hour`: `true` for 24-hour, `false` for 12-hour (default: `true`)
- `timezone`: Timezone ID for abbreviation display (e.g., 'America/New_York')

**When to use:** Displaying full date and time to users.

---

### `DateFormatter.formatDate()`

Format date only (no time).

```dart
DateFormatter.formatDate(
  dateTime,
  timezone: settings.timezone,  // Optional
)
```

**Output example:**
```
"Dec 18, 2025"
```

**When to use:** Date-only displays (calendar headers, date pickers).

---

### `DateFormatter.formatDateTimeWithTZ()`

Format with timezone (no parentheses around abbreviation).

```dart
DateFormatter.formatDateTimeWithTZ(
  dateTime,
  use24Hour: true,
  timezone: 'America/New_York',
)
```

**Output examples:**
```dart
// 24-hour format
"Dec 18, 2025 at 15:44 EST"

// 12-hour format
"Dec 18, 2025 at 3:44 PM EST"
```

**When to use:** Tooltips, subtitles where compact format is needed.

---

### Month & Weekday Names

Get localized month and weekday names.

```dart
import '../utils/time_helper.dart';

// Month names
final monthNum = 12;  // December
monthNum.getFullMonth()          // "December"
monthNum.getAbbreviatedMonth()   // "Dec"

// Weekday names
final weekdayNum = 1;  // Monday
weekdayNum.getFullWeekday()      // "Monday"
weekdayNum.getAbbreviatedWeekday() // "Mon"
```

**Valid ranges:**
- Months: 1-12 (January-December)
- Weekdays: 1-7 (Monday-Sunday)

**Throws:** `ArgumentError` if out of range

---

### Time of Day Formatting

Use settings to format consistently.

```dart
final settings = context.watch<SettingsProvider>();

// Format time based on user preference
String formatTime(DateTime dateTime) {
  final hour = settings.use24HourFormat
      ? dateTime.hour.toString().padLeft(2, '0')
      : (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12).toString();
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = settings.use24HourFormat
      ? ''
      : (dateTime.hour >= 12 ? ' ${'pm'.tr().toUpperCase()}' : ' ${'am'.tr().toUpperCase()}');
  
  return '$hour:$minute$period';
}
```

**Output:**
- 24-hour: `"15:44"`
- 12-hour: `"3:44 PM"`

---

## Pluralization

### `formatDuration()`

Format time durations with proper pluralization.

```dart
import '../utils/time_helper.dart';

// Singular (count = 1)
formatDuration(1, 'minute')        // "1 minute"
formatDuration(1, 'hour')          // "1 hour"
formatDuration(1, 'day')           // "1 day"

// Plural (count > 1)
formatDuration(5, 'minute')        // "5 minutes"
formatDuration(2, 'hour')          // "2 hours"
formatDuration(30, 'day')          // "30 days"

// Abbreviated forms
formatDuration(1, 'minute', abbreviated: true)   // "1 min"
formatDuration(5, 'minute', abbreviated: true)   // "5 mins"
formatDuration(2, 'hour', abbreviated: true)     // "2 hrs"
```

**Supported units:**
- `'second'` / `'seconds'`
- `'minute'` / `'minutes'`
- `'hour'` / `'hours'`
- `'day'` / `'days'`
- `'week'` / `'weeks'`
- `'month'` / `'months'`
- `'year'` / `'years'`

**Parameters:**
- `count`: Number of units (int)
- `unit`: Unit type (String)
- `abbreviated`: Use short forms (default: `false`)

---

### Manual Pluralization

For custom pluralization logic.

```dart
String formatEntryCount(int count) {
  if (count == 1) {
    return 'entries.count_singular'.tr([count.toString()]);
    // "1 entry"
  } else {
    return 'entries.count_plural'.tr([count.toString()]);
    // "{0} entries"
  }
}

// Usage
Text(formatEntryCount(1))   // "1 entry"
Text(formatEntryCount(42))  // "42 entries"
```

**Translation file:**
```json
{
  "entries": {
    "count_singular": "{0} entry",
    "count_plural": "{0} entries"
  }
}
```

---

## Timezones

### Timezone Conversion

Convert UTC to specific timezone.

```dart
import '../utils/time_helper.dart';

// Get current time in timezone
final newYorkTime = nowInTimezone('America/New_York');
final tokyoTime = nowInTimezone('Asia/Tokyo');
final utcTime = nowInTimezone('UTC');

// Convert specific UTC time
final utcTime = DateTime.utc(2025, 1, 22, 20, 30);
final localTime = convertUtcToTimezone('America/Los_Angeles');
// Converts to Pacific time
```

**When to use:**
- Displaying times in user's timezone
- Converting server times (UTC) to local
- Calendar operations

---

### Timezone List for Dropdowns

Pre-generated list of timezones organized by region.

```dart
import '../utils/time_helper.dart';

// Use in Autocomplete/Dropdown
Autocomplete<String>(
  optionsBuilder: (TextEditingValue value) {
    if (value.text.isEmpty) {
      return commonTimezones;
    }
    return commonTimezones.where((tz) =>
      tz.toLowerCase().contains(value.text.toLowerCase())
    );
  },
  onSelected: (String timezone) {
    settings.setTimezone(timezone);
  },
)
```

**Format:**
```
UTC
--- Africa ---
Africa/Cairo
Africa/Johannesburg
--- Americas ---
America/New_York
America/Los_Angeles
America/Chicago
--- Asia ---
Asia/Tokyo
Asia/Shanghai
--- Europe ---
Europe/London
Europe/Paris
...
```

**Features:**
- Organized by region (Africa, Americas, Asia, etc.)
- Headers marked with `---` prefix/suffix
- Alphabetically sorted within regions
- UTC always first

---

### Timezone Data Access

```dart
import '../constants/timezones.dart';

// Get timezone info
final tzData = timezoneOffsets['America/New_York'];
if (tzData != null) {
  print('Standard: ${tzData.standardName}');    // "EST"
  print('Daylight: ${tzData.daylightName}');    // "EDT"
  print('Offset: ${tzData.standardOffset}');    // "-0500"
}
```

---

## Adding New Languages

### 1. Create Translation File

Create `assets/i18n/{language_code}.json`:

```json
{
  "app_name": "EcCal",
  "save": "Guardar",
  "cancel": "Cancelar",
  "settings": {
    "title": "Configuración",
    "general": "General"
  },
  "error": {
    "network": "Error de red",
    "failed_to_load": "Error al cargar {0}"
  },
  "months": {
    "january": "Enero",
    "february": "Febrero"
  }
}
```

---

### 2. Update `AppLanguages` Class

In `app_localizations.dart`:

```dart
class AppLanguages {
  static const Map<String, String> languages = {
    'en': 'English',
    'es': 'Español',      // Add new language
    'fr': 'Français',     // Add new language
  };
}
```

---

### 3. Add Month/Weekday Names

In `constants/times.dart`:

```dart
class MonthNames {
  static const List<String> fullMonth = [
    'months.january',
    'months.february',
    // ... rest of months
  ];
  
  static const List<String> abbreviatedMonth = [
    'months.jan',
    'months.feb',
    // ... rest of months
  ];
}

class WeekdayNames {
  static const List<String> fullWeekday = [
    'weekdays.monday',
    'weekdays.tuesday',
    // ... rest of weekdays
  ];
  
  static const List<String> abbreviatedWeekday = [
    'weekdays.mon',
    'weekdays.tue',
    // ... rest of weekdays
  ];
}
```

Then add translations in your JSON file:

```json
{
  "months": {
    "january": "Enero",
    "jan": "Ene",
    "february": "Febrero",
    "feb": "Feb"
  },
  "weekdays": {
    "monday": "Lunes",
    "mon": "Lun",
    "tuesday": "Martes",
    "tue": "Mar"
  }
}
```

---

### 4. Add Timezone Translations

```json
{
  "timezones": {
    "africa": "África",
    "americas": "Américas",
    "asia": "Asia",
    "atlantic": "Atlántico",
    "australia": "Australia",
    "europe": "Europa",
    "pacific": "Pacífico"
  }
}
```

---

### 5. Test Language

```dart
// In settings
await settings.setLanguage('es');
await AppLocalizations.load('es');
```

---

## Best Practices

### 1. Use Translation Keys Consistently

```dart
// ✓ Good - Descriptive keys
'settings.general'.tr()
'error.network_failed'.tr()
'mood.happy'.tr()

// ✗ Bad - Unclear keys
'msg1'.tr()
'txt'.tr()
'a'.tr()
```

**Guidelines:**
- Use dot notation for organization
- Descriptive, not abbreviated
- Consistent naming convention

---

### 2. Organize by Feature/Context

**Translation file structure:**
```json
{
  "app": {
    "name": "EcCal",
    "version": "Version {0}"
  },
  "settings": {
    "title": "Settings",
    "general": "General",
    "display": "Display"
  },
  "errors": {
    "network": "Network error",
    "auth": "Authentication failed"
  },
  "moods": {
    "happy": "Happy",
    "sad": "Sad"
  }
}
```

---

### 3. Use Arguments for Dynamic Content

```dart
// ✓ Good - Dynamic values
'sync.completed'.tr([entryCount.toString()])
// "Synced 42 entries"

'error.failed_to_load'.tr([filename])
// "Failed to load diary.ics"

// ✗ Bad - Hardcoded English
Text('Synced $entryCount entries')
Text('Failed to load $filename')
```

---

### 4. Handle Pluralization Properly

```dart
// ✓ Good - Proper pluralization
String formatCount(int count) {
  return count == 1
      ? 'entry.singular'.tr()
      : 'entry.plural'.tr([count.toString()]);
}

// ✗ Bad - English-only pluralization
Text('$count entry${count != 1 ? 's' : ''}')
```

**Translation file:**
```json
{
  "entry": {
    "singular": "1 entry",
    "plural": "{0} entries"
  }
}
```

---

### 5. Use DateFormatter for Dates

```dart
// ✓ Good - Localized formatting
DateFormatter.formatDateTime(
  entry.date,
  use24Hour: settings.use24HourFormat,
  timezone: settings.timezone,
)

// ✗ Bad - Manual formatting
'${entry.date.month}/${entry.date.day}/${entry.date.year}'
```

**Benefits:**
- Respects user's time format preference
- Shows timezone abbreviations
- Handles localization automatically

---

### 6. Test with Missing Translations

```dart
// If key doesn't exist, returns the key itself
'nonexistent.key'.tr()
// Output: "nonexistent.key"
```

**During development:**
- Missing translations are visible
- Add translations before release
- Use descriptive keys to help identify context

---

### 7. Avoid Concatenation

```dart
// ✗ Bad - Won't translate properly
Text('${label}: ${value}')
Text('${'user'.tr()} $name')

// ✓ Good - Single translation with arguments
'user.label_value'.tr([label, value])
// Translation: "{0}: {1}"

'user.greeting'.tr([name])
// Translation: "User {0}"
```

---

### 8. Use Settings for Format Preferences

```dart
final settings = context.watch<SettingsProvider>();

// Time format
DateFormatter.formatDateTime(
  date,
  use24Hour: settings.use24HourFormat,  // User preference
  timezone: settings.timezone,
)

// Language
await AppLocalizations.load(settings.language);
```

**User preferences:**
- Time format (24h vs 12h)
- Language
- Timezone

---

## Common Patterns

### Settings Screen

```dart
SettingsDropdownRow<String>(
  title: 'display_settings.language'.tr(),
  value: settings.language,
  items: AppLanguages.codes.map((code) {
    return DropdownMenuItem(
      value: code,
      child: Text(AppLanguages.getName(code)),
    );
  }).toList(),
  onChanged: (value) {
    if (value != null) {
      settings.setLanguage(value);
      ErrorSnackbar.showInfo(
        context,
        'display_settings.language_changed'.tr(),
      );
    }
  },
)
```

---

### Error Messages

```dart
try {
  await syncWithServer();
} catch (e) {
  ErrorSnackbar.showError(
    context,
    'error.sync_failed'.tr([e.toString()]),
  );
}
```

---

### Date Display

```dart
// Entry list item
ListTile(
  title: Text(entry.title),
  subtitle: Text(
    DateFormatter.formatDateTime(
      entry.date,
      use24Hour: settings.use24HourFormat,
      timezone: settings.timezone,
    ),
  ),
)
```

---

### Duration Display

```dart
// Event duration
Text(formatDuration(
  settings.eventDurationMinutes,
  'minute',
))
// Output: "30 minutes"

// Abbreviated
Text(formatDuration(
  settings.eventDurationMinutes,
  'minute',
  abbreviated: true,
))
// Output: "30 mins"
```

---

## Complete Example

```dart
import '../utils/app_localizations.dart';
import '../utils/date_formatter.dart';
import '../utils/time_helper.dart';

class DiaryEntryView extends StatelessWidget {
  final DiaryEntry entry;
  
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    // Format date/time
    final dateTime = DateFormatter.formatDateTime(
      entry.date,
      use24Hour: settings.use24HourFormat,
      timezone: settings.timezone,
    );
    
    // Duration
    final duration = formatDuration(
      entry.durationMinutes,
      'minute',
      abbreviated: true,
    );
    
    return Card(
      child: Column(
        children: [
          // Title
          Text(
            entry.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          
          // Date and time
          Text(
            'entry.created_at'.tr([dateTime]),
            // "Created at Dec 18, 2025 at 3:44 PM (EST)"
          ),
          
          // Duration
          Text(
            'entry.duration'.tr([duration]),
            // "Duration: 30 mins"
          ),
          
          // Mood
          if (entry.mood != null)
            Text(
              'mood.${entry.mood}'.tr(),
              // "Happy", "Sad", etc.
            ),
          
          // Actions
          Row(
            children: [
              TextButton(
                onPressed: () => editEntry(entry),
                child: Text('edit'.tr()),
              ),
              TextButton(
                onPressed: () => deleteEntry(entry),
                child: Text('delete'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## Troubleshooting

### Translation Not Found

**Symptom:** Key displayed instead of translated text

**Check:**
1. Key exists in JSON file
2. Nested keys use dot notation: `'settings.title'.tr()`
3. Language file loaded: `await AppLocalizations.load(languageCode)`

---

### Date Format Issues

**Symptom:** Incorrect date/time display

**Check:**
1. Using `DateFormatter` methods (not manual formatting)
2. Passing correct `use24Hour` parameter
3. Valid timezone string

---

### Pluralization Not Working

**Symptom:** Always shows plural form

**Check:**
1. Using `formatDuration()` for time units
2. Implementing custom logic for count == 1
3. Separate translation keys for singular/plural

---

## Need More Help?

- Check `app_localizations.dart` for implementation
- See `date_formatter.dart` for date formatting
- Look at `time_helper.dart` for time utilities
- Examine existing translation files in `assets/i18n/`
- All translations automatically fall back to English if key not found!
