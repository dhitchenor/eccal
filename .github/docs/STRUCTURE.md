/==============================================\
### PROJECT STRUCTURE
\==============================================/
```
lib/
├── config/          # App configuration
├── dialogs/         # Dialog logic
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic
├── utils/           # Helper functions
└── widgets/         # Reusable UI components
```

/==============================================\
### EcCal iCAL FILE STRUCTURE
\==============================================/
BEGIN:VCALENDAR
PRODID:-//dhitchenor//EcCal 1.0//EN
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


### Explanations:
=================
#### Items/properties that are not mentioned, don't need to be mentioned

DTSTAMP - Time when the object is created, or edited. Used in EcCal for syncing, and appending
UID - Globally unique identifier
DTSTART - Initial start date/time of event; doesn't change, useful for syncing, and appending
DURATION - Duration (used instead of DTEND), sets how much time in the calendar that is taken up by the entry
    - FORMAT:
        - P: Indicates period (required)
        - nD: n days
        - T: Time component (prefix for hours/minutes/seconds)
        - nH: n hours
        - nM: n minutes
        - nS: n seconds
            eg: P2DT3H4M19S - 2 days, 3 hours, 4 minutes, 19 seconds
            default: PT15M - 15 minutes
SUMMARY - Title of the entry
DESCRIPTION - Body of the entry, stored as markdown, by default
X-MOOD - Custom property; stores 'mood'
LOCATION - Human-readable location
GEO - Latitude/longitude
    LOCATION is human-readable; GEO is numeric
X-APPENDDATE - Sustom property; stores appendix date. (indexed instances, can have multiple)
    - includes timezone of when the entry was appended 
X-APPENDMOOD - Custom property; stores appendix mood (indexed instances, can have multiple)
X-APPENDLOC - Custom property; stores appendix location (indexed instances, can have multiple)
X-APPENDGEO - Custom property; stores appendix geo, (indexed instances, can have multiple)
CATEGORIES - Tags or categories
ATTACH - Attached files or links.
    - Attached mimetypes, inline, if not URL/links..
    - potentially allowed types:
        - application/pdf       (PDF documents)
        - application/zip       (ZIP archive)
        - image/png             (PNG image)
        - image/jpeg            (JPEG image)
        - image/gif             (GIF image)
        - text/plain            (Plain text)
        - text/html             (HTML file)
        - audio/mpeg	        (MP3 audio)
        - audio/ogg             (OGG audio)
        - video/mp4             (MP4 video)
        - video/ogg             (OGG video)

#### Ignored / Not used properties
CREATED
METHOD
DUE
DTEND
RECURRENCE-ID:
RRULE
RDATE
RDATE
EXDATE
EXRULE
RESOURCES
PRIORITY
PERCENT-COMPLETE
COMPLETED
SEQUENCE
COMMENT
REQUEST-STATUS
ORGANIZER
ATTENDEE
CONTACT
URL
RELATED-TO

### Explanations:
=================
#### Items/properties that didn't need to be mentioned

BEGIN:VCALENDAR - Beginning of the iCal (vCalendar) format
PRODID - Production ID
VERSION - iCal format version
CALSCALE - Variety/ type of calendar used
BEGIN:VTIMEZONE - Beginning of the timezone (vTimezone) format
TZID - Identifier of the IANA timezone
BEGIN:STANDARD - Beginning of the type of timezone used
DTSTART - Start time, needed for VTIMEZONE, doesn't actually affect anything
TZOFFSETFROM - Timezone offset (from, typically the same as 'to')
TZOFFSETTO - Timezone offset (to, typically the same as 'from')
TZNAME - Timezone abbreviation, eg, AST, IST, VLAT
END:STANDARD - Ending of the type of timezone used
END:VTIMEZONE - Ending of the timezone (vTimezone) format
BEGIN:VEVENT - Beginning of the event (vEvent) format
CLASS - PUBLIC / PRIVATE / CONFIDENTIAL (Defaults to confidential, and honestly does not need to be changed)
    - PUBLIC: The event is visible to everyone.	Default if CLASS is omitted.
    - PRIVATE: The event is private. Only the owner should see details; others may see “busy” without details. Used for sensitive events.
    - CONFIDENTIAL: The event is restricted; details are hidden except for authorized viewers.
STATUS - TENTATIVE / CONFIRMED / CANCELLED
    - TENTATIVE: Event is planned but not confirmed.
    - CONFIRMED: Event is definitely scheduled.
    - CANCELLED: Event has been canceled.
TRANSP - OPAQUE / TRANSPARENT
    - OPAQUE: Event blocks the time, so others see you as 'busy'. Default for scheduled events
    - TRANSPARENT: Event does not block time, so others see you as 'free'. Useful for reminders or informational events
        - Default: TRANSPARENT (this is so it does not affect any other items in the calendar)
END:VEVENT - Beginning of the event (vEvent) format
END:VCALENDAR - Ending of the iCal (vCalendar) format