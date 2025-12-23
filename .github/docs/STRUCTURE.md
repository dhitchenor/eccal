# EcCal Project Structure

This document describes the complete project structure, file organization, and key components of the EcCal application.

---

## Table of Contents
- [Directory Structure](#directory-structure)
- [Source Code Organization](#source-code-organization)
- [Assets & Resources](#assets--resources)
- [Build Scripts](#build-scripts)
- [Platform-Specific Files](#platform-specific-files)
- [iCalendar File Format](#icalendar-file-format)

---

## Directory Structure

```
eccal/
├── lib/                          # Main application source code
│   ├── config/                   # Application configuration
│   ├── constants/                # App-wide constants
│   ├── dialogs/                  # Dialog widgets
│   ├── models/                   # Data models
│   ├── providers/                # State management (Provider pattern)
│   ├── screens/                  # Screen widgets
│   │   └── settings/             # Settings screen tabs
│   ├── services/                 # Business logic services
│   ├── utils/                    # Helper functions & utilities
│   └── widgets/                  # Reusable UI components
│
├── assets/                       # Static assets & resources
│   ├── i18n/                     # Internationalization (translations)
│   │   ├── en.json               # English translations
│   │   └── ...                   # Other language files
│   └── icon/                     # Application icons
│       └── app_icon.png          # Main app icon (source)
│
├── scripts/                      # Build & automation scripts
│   ├── version_update.sh         # Linux/macOS version update script
│   ├── version_update.ps1        # Windows PowerShell version script
│   └── version_update.bat        # Windows batch wrapper
│
├── android/                      # Android platform files
│   ├── app/                      # Android app module
│   └── gradle.properties         # Android build configuration
│
├── ios/                          # iOS platform files
│   └── Runner/                   # iOS app target
│
├── linux/                        # Linux platform files
│   ├── eccal.desktop             # Linux desktop entry
│   └── eccal.png                 # App icon (copied from assets/)
│
├── macos/                        # macOS platform files
│   └── Runner/                   # macOS app target
│
├── windows/                      # Windows platform files
│   └── runner/                   # Windows app target
│
├── .github/                      # GitHub configuration
│   └── workflows/                # GitHub Actions CI/CD
│       └── release.yml           # Automated release workflow
│
├── pubspec.yaml                  # Flutter project configuration
├── COMPONENT_USE.md              # Settings components usage guide
├── LOGGER_USE.md                 # Logger service usage guide
├── TRANSLATIONS_USE.md           # Translations & i18n usage guide
├── VERSIONING.md                 # Versioning & release process guide
└── STRUCTURE.md                  # This file
```

---

## Source Code Organization

### `lib/config/` - Application Configuration

```
config/
└── app_config.dart               # Central app configuration (SOURCE OF TRUTH)
```

**Contains:**
- App version number
- App name
- Flutter version
- Dependency versions (SOURCE OF TRUTH)
- Dev dependency versions

**Purpose:** Single source of truth for versioning and package versions across the entire project.

---

### `lib/constants/` - Application Constants

```
constants/
├── themes.dart                   # Theme colors and color schemes
├── timezones.dart                # Timezone data and offsets
└── times.dart                    # Time-related constants (month/weekday names)
```

**Purpose:** Centralized constants to avoid magic numbers and ensure consistency.

---

### `lib/dialogs/` - Dialog Widgets

```
dialogs/
├── storage_setup_dialog.dart     # First-run storage setup dialog
├── caldav_setup_dialogs.dart     # CalDAV configuration dialogs
└── ...                           # Other dialog widgets
```

**Purpose:** Reusable dialog components for user interactions.

---

### `lib/models/` - Data Models

```
models/
├── diary_entry.dart              # Diary entry data model
├── calendar_event.dart           # Calendar event representation
└── ...                           # Other data models
```

**Purpose:** Define data structures used throughout the app.

---

### `lib/providers/` - State Management

```
providers/
├── settings_provider.dart        # App settings state
├── diary_provider.dart           # Diary entries state
└── ...                           # Other providers
```

**Purpose:** Manage application state using the Provider pattern (state management).

---

### `lib/screens/` - Screen Widgets

```
screens/
├── home_screen.dart              # Main app screen
├── initialization_screen.dart    # Startup/loading screen
└── settings/                     # Settings screen tabs
    ├── display_tab.dart          # Display settings
    ├── general_tab.dart          # General settings
    ├── local_tab.dart            # Local storage settings
    ├── server_tab.dart           # Server/CalDAV settings
    └── settings_components.dart  # Reusable settings UI components
```

**Purpose:** Top-level screen widgets and navigation.

---

### `lib/services/` - Business Logic

```
services/
├── caldav_service.dart           # CalDAV server communication
├── file_storage_service.dart     # Local file I/O operations
├── google_calendar_service.dart  # Google Calendar integration
├── logger_service.dart           # Logging system
└── initialization_manager.dart   # App startup management
```

**Purpose:** Business logic, API communication, and core functionality.

---

### `lib/utils/` - Helper Functions

```
utils/
├── app_localizations.dart        # Translation/i18n system
├── date_formatter.dart           # Date/time formatting
├── time_helper.dart              # Time conversion utilities
├── theme_controller.dart         # Theme management
├── error_snackbar.dart           # Error message display
└── saf_helper.dart               # Android Storage Access Framework
```

**Purpose:** Utility functions and helpers used throughout the app.

---

### `lib/widgets/` - Reusable Components

```
widgets/
├── build_calendar_signin.dart    # Calendar provider sign-in UI
├── caldav_server_form.dart       # CalDAV configuration form
└── ...                           # Other reusable widgets
```

**Purpose:** Reusable UI components shared across screens.

---

## Assets & Resources

### `assets/i18n/` - Translations

```
assets/i18n/
├── en.json                       # English (primary language)
├── es.json                       # Spanish (if available)
├── fr.json                       # French (if available)
└── ...                           # Other language files
```

**Format:** JSON key-value pairs
```json
{
  "app_name": "EcCal",
  "save": "Save",
  "settings": {
    "title": "Settings",
    "general": "General"
  }
}
```

**Usage:**
```dart
'save'.tr()                       // "Save"
'settings.title'.tr()             // "Settings"
'error.message'.tr(['filename'])  // "Error loading filename"
```

**See:** [TRANSLATIONS_USE.md](TRANSLATIONS_USE.md) for complete guide.

---

### `assets/icon/` - Application Icons

```
assets/icon/
└── app_icon.png                  # Main application icon (1024x1024 recommended)
```

**Purpose:** Source icon file that gets copied to platform-specific locations during build.

**Copied to:**
- `linux/eccal.png` - Linux desktop icon
- Android/iOS app icons (via flutter_launcher_icons or manual setup)

---

## Build Scripts

### `scripts/version_update.sh` - Linux/macOS Version Update

**Platform:** Linux, macOS  
**Language:** Bash  
**Execution:**
```bash
./scripts/version_update.sh
```

**Features:**
- Checks version consistency across all files
- Validates version format (X.Y.Z, X.Y.Z-alpha, X.Y.Z-beta, X.Y.Z-rc1)
- Syncs dependencies from `app_config.dart` to `pubspec.yaml`
- Updates Android version code
- Copies app icon if changed (MD5 checksum comparison)
- Updates GitHub Actions Flutter version

**See:** [VERSIONING.md](VERSIONING.md) for complete guide.

---

### `scripts/version_update.ps1` - Windows Version Update

**Platform:** Windows  
**Language:** PowerShell  
**Execution:** (via wrapper)
```cmd
scripts\version_update.bat
```

**Features:** Identical to Bash script, but for Windows environment.

---

### `scripts/version_update.bat` - Windows Wrapper

**Platform:** Windows  
**Language:** Batch  
**Purpose:** Launches PowerShell script with proper execution policy.

**Contents:**
```batch
@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0version_update.ps1"
pause
```

**Why needed:** Windows PowerShell has execution policies that prevent running scripts by default. This wrapper bypasses the restriction temporarily.

---

## Platform-Specific Files

### Android - `android/gradle.properties`

```properties
flutter.versionName=1.0.0
flutter.versionCode=1
```

**Purpose:**
- `versionName`: Human-readable version (same as `app_config.dart`)
- `versionCode`: Integer version for Google Play (must increment with each release)

---

### Linux - `linux/eccal.desktop`

```ini
[Desktop Entry]
Version=1.0.0
Type=Application
Name=EcCal
Comment=A cross-platform diary app with CalDAV integration
Exec=eccal
Icon=eccal
Terminal=false
Categories=Office;Calendar;Utility;
Keywords=diary;journal;calendar;caldav;notes;
StartupNotify=true
```

**Purpose:** Linux desktop environment integration (app launcher, menus).

---

### Linux - `linux/eccal.png`

**Purpose:** Application icon for Linux desktop environments.  
**Source:** Automatically copied from `assets/icon/app_icon.png` by version update scripts.

---

### GitHub Actions - `.github/workflows/release.yml`

**Purpose:** Automated CI/CD for releases.

**Contains:**
- Flutter version to use for builds
- Build steps for all platforms
- Automated release creation
- Asset upload to GitHub releases

**Updated by:** Version update scripts sync Flutter version from `app_config.dart`.

---

## iCalendar File Format

EcCal stores diary entries in RFC 5545 iCalendar format (`.ics` files).

### Basic Structure

```
BEGIN:VCALENDAR
PRODID:-//ec_com//EcCal 1.0//EN
VERSION:2.0
CALSCALE:GREGORIAN
BEGIN:VTIMEZONE
...
END:VTIMEZONE
BEGIN:VEVENT
...
END:VEVENT
END:VCALENDAR
```

---

### Complete Example

```ics
BEGIN:VCALENDAR
PRODID:-//ec_com//EcCal 1.0//EN
VERSION:2.0
CALSCALE:GREGORIAN
BEGIN:VTIMEZONE
TZID:Asia/Kolkata
BEGIN:STANDARD
DTSTART:19700101T000000
TZOFFSETFROM:+0530
TZOFFSETTO:+0530
TZNAME:IST
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
UID:eccal-20250105-140000-a1b2c3d4
CLASS:CONFIDENTIAL
STATUS:CONFIRMED
TRANSP:TRANSPARENT
DTSTAMP:20250105T084500Z
DTSTART;TZID=Asia/Kolkata:20250105T140000
DURATION:PT15M
X-MOOD:😊
LOCATION:Central Park, New York
GEO:40.785091;-73.968285
X-APPENDDATE;INDEX=1;TZID=Asia/Kolkata:20250105T150000
X-APPENDMOOD;INDEX=1:😐
X-APPENDLOC;INDEX=1:Home
X-APPENDGEO;INDEX=1:40.712776;-74.005974
X-APPENDDATE;INDEX=2;TZID=Asia/Kolkata:20250105T180000
X-APPENDMOOD;INDEX=2:😃
X-APPENDLOC;INDEX=2:Coffee Shop
X-APPENDGEO;INDEX=2:40.730610;-73.935242
X-APPENDDATE;INDEX=3;TZID=Asia/Kolkata:20250105T210000
X-APPENDMOOD;INDEX=3:😌
CATEGORIES:personal,reflection
SUMMARY:My Diary Entry - January 5th
DESCRIPTION:This is the main content of my diary entry.\n\nI went to the park today.
ATTACH;FMTTYPE=application/pdf:https://example.com/files/event-info.pdf
END:VEVENT
END:VCALENDAR
```

---

### Core Properties (Used by EcCal)

#### Entry Identification
| Property | Purpose | Example |
|----------|---------|---------|
| `UID` | Globally unique identifier | `eccal-20250105-140000-a1b2c3d4` |
| `DTSTAMP` | Creation/edit timestamp (UTC) | `20250105T084500Z` |

#### Date & Time
| Property | Purpose | Example |
|----------|---------|---------|
| `DTSTART` | Initial start date/time (doesn't change) | `DTSTART;TZID=Asia/Kolkata:20250105T140000` |
| `DURATION` | Event duration | `PT15M` (15 minutes) |

**Duration Format:**
```
P[nD]T[nH][nM][nS]
P:        Period (required)
nD:       n days
T:        Time component separator
nH:       n hours
nM:       n minutes
nS:       n seconds

Examples:
PT15M              = 15 minutes (default)
PT1H30M            = 1 hour 30 minutes
P2DT3H4M19S        = 2 days, 3 hours, 4 minutes, 19 seconds
```

#### Content
| Property | Purpose | Example |
|----------|---------|---------|
| `SUMMARY` | Entry title | `My Diary Entry - January 5th` |
| `DESCRIPTION` | Entry content (Markdown) | `This is the main content...` |
| `CATEGORIES` | Tags/categories | `personal,reflection` |

#### Location & Mood
| Property | Purpose | Example |
|----------|---------|---------|
| `X-MOOD` | Mood emoji (custom property) | `😊` |
| `LOCATION` | Human-readable location | `Central Park, New York` |
| `GEO` | GPS coordinates (lat;lon) | `40.785091;-73.968285` |

#### Append Entries (Indexed)
| Property | Purpose | Example |
|----------|---------|---------|
| `X-APPENDDATE` | Append timestamp with timezone | `X-APPENDDATE;INDEX=1;TZID=Asia/Kolkata:20250105T150000` |
| `X-APPENDMOOD` | Append mood | `X-APPENDMOOD;INDEX=1:😐` |
| `X-APPENDLOC` | Append location | `X-APPENDLOC;INDEX=1:Home` |
| `X-APPENDGEO` | Append GPS coordinates | `X-APPENDGEO;INDEX=1:40.712776;-74.005974` |

**Note:** All append properties use `INDEX` parameter to group related data.

#### Attachments
| Property | Purpose | Example |
|----------|---------|---------|
| `ATTACH` | File attachments or URLs | `ATTACH;FMTTYPE=application/pdf:https://...` |

**Potentially Supported MIME types:**
- `application/pdf` - PDF documents
- `application/zip` - ZIP archives
- `image/png`, `image/jpeg`, `image/gif` - Images
- `text/plain`, `text/html` - Text files
- `audio/mpeg`, `audio/ogg` - Audio files
- `video/mp4`, `video/ogg` - Video files

---

### Calendar-Level Properties

#### `VCALENDAR` Container
| Property | Value | Purpose |
|----------|-------|---------|
| `PRODID` | `-//ec_com//EcCal 1.0//EN` | Identifies ec_com (EcCal Community) as creator |
| `VERSION` | `2.0` | iCalendar format version |
| `CALSCALE` | `GREGORIAN` | Calendar system |

#### `VTIMEZONE` Container
| Property | Purpose | Example |
|----------|---------|---------|
| `TZID` | IANA timezone identifier | `Asia/Kolkata` |
| `DTSTART` | Required for VTIMEZONE (doesn't affect events) | `19700101T000000` |
| `TZOFFSETFROM` | Timezone offset (from) | `+0530` |
| `TZOFFSETTO` | Timezone offset (to) | `+0530` |
| `TZNAME` | Timezone abbreviation | `IST` |

---

### Event Properties

#### Classification & Status
| Property | Values | Default | Purpose |
|----------|--------|---------|---------|
| `CLASS` | `PUBLIC`, `PRIVATE`, `CONFIDENTIAL` | `CONFIDENTIAL` | Access control |
| `STATUS` | `TENTATIVE`, `CONFIRMED`, `CANCELLED` | `CONFIRMED` | Event status |
| `TRANSP` | `OPAQUE`, `TRANSPARENT` | `TRANSPARENT` | Free/busy indicator |

**CLASS values:**
- `PUBLIC`: Event visible to everyone
- `PRIVATE`: Event private, others see "busy" without details
- `CONFIDENTIAL`: Event restricted, details hidden except for authorized viewers

**STATUS values:**
- `TENTATIVE`: Event planned but not confirmed
- `CONFIRMED`: Event definitely scheduled
- `CANCELLED`: Event has been canceled

**TRANSP values:**
- `OPAQUE`: Event blocks time (others see "busy")
- `TRANSPARENT`: Event doesn't block time (others see "free") - **EcCal default** to not affect other calendar items

---

### Ignored Properties

EcCal does not use the following standard iCalendar properties:

```
CREATED          (Creation timestamp)
METHOD           (iMIP method)
DUE              (Due date for TODOs)
DTEND            (End Date and Time)
RECURRENCE-ID    (Recurring event instance)
RRULE            (Recurrence rule)
RDATE            (Recurrence date)
EXDATE           (Exception date)
EXRULE           (Exception rule)
RESOURCES        (Resources required)
PRIORITY         (Priority level)
PERCENT-COMPLETE (Completion percentage)
COMPLETED        (Completion timestamp)
SEQUENCE         (Revision number)
COMMENT          (Comment/note)
REQUEST-STATUS   (Status from scheduling)
ORGANIZER        (Event organizer)
ATTENDEE         (Event attendees)
CONTACT          (Contact information)
URL              (Associated URL)
RELATED-TO       (Related events)
```

**Why ignored:** EcCal is a personal diary application, not a full calendar/scheduling system. These properties are for multi-user scheduling, recurring events, and task management which are out of scope.

---

## File Organization Best Practices

### When Adding New Files

1. **Widgets:** Place in `lib/widgets/` if reusable across multiple screens
2. **Screens:** Place in `lib/screens/` for top-level navigation destinations
3. **Services:** Place in `lib/services/` for business logic and API communication
4. **Models:** Place in `lib/models/` for data structures
5. **Utilities:** Place in `lib/utils/` for helper functions
6. **Dialogs:** Place in `lib/dialogs/` for popup/modal interactions

### File Naming Conventions

- **Snake case:** `diary_entry.dart`, `caldav_service.dart`
- **Descriptive:** `storage_setup_dialog.dart` not `dialog1.dart`
- **Suffix by type:** `_provider.dart`, `_service.dart`, `_dialog.dart`

### Import Organization

```dart
// 1. Dart/Flutter packages
import 'dart:io';
import 'package:flutter/material.dart';

// 2. External packages
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// 3. Local imports (relative paths)
import '../models/diary_entry.dart';
import '../services/caldav_service.dart';
import '../utils/app_localizations.dart';
```

---

## Documentation Files

| File | Purpose |
|------|---------|
| `COMPONENT_USE.md` | Settings UI components usage guide |
| `LOGGER_USE.md` | Logger service usage guide |
| `TRANSLATIONS_USE.md` | Translation & i18n usage guide |
| `VERSIONING.md` | Versioning & release process guide |
| `STRUCTURE.md` | This file - project structure overview |

**See these files for detailed usage instructions on specific systems.**

---

## Need More Help?

- **UI Components:** See [COMPONENT_USE.md](COMPONENT_USE.md)
- **Logging:** See [LOGGER_USE.md](LOGGER_USE.md)
- **Translations:** See [TRANSLATIONS_USE.md](TRANSLATIONS_USE.md)
- **Versioning:** See [VERSIONING.md](VERSIONING.md)
- **Code Examples:** Check existing files in each directory for patterns and conventions
