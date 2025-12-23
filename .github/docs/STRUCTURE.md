/==============================================\
### PROJECT STRUCTURE
\==============================================/
```
lib/
├── config/          # App configuration
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic
├── utils/           # Helper functions
└── widgets/         # Reusable UI components
```

/==============================================\
### iCAL FILE STRUCTURE
\==============================================/

BEGIN:VCALENDAR
PRODID:-//dhitchenor//EcCal 0.9.9//EN
VERSION:2.0
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:12345678-90ab-cdef-1234-567890abcdef
DTSTAMP:20250101T120000Z
DTSTART:20250103T090000Z
DURATION:PT15M
SUMMARY:Example Event With All Standard Properties
DESCRIPTION:This event demonstrates every property allowed in an EcCal Entry.
X-MOOD:happy
LOCATION:Example Conference Room
GEO:37.386013;-122.082932
CATEGORIES:Business,Meeting
CLASS:CONFIDENTIAL
STATUS:CONFIRMED
TRANSP:TRANSPARENT
CREATED:20241201T100000Z
EXDATE:20241215T150000Z
ATTACH;FMTTYPE=application/pdf:https://example.com/files/event-info.pdf
END:VEVENT
END:VCALENDAR


### Explanations:
=================
#### (R) denotes a 'required' property for the iCal format

DTSTAMP (R) — When the event object was created.
UID (R) — Globally unique identifier.
DTSTART — Start date/time of event.
DURATION — Duration instead of DTEND.
    P: Indicates period (required)
    nD: n days
    T: Time component (prefix for hours/minutes/seconds)
    nH: n hours
    nM: n minutes
    nS: n seconds
        eg: P2DT3H4M19S - 2 days, 3 hours, 4 minutes, 19 seconds
        default: PT15M - 15 minutes
SUMMARY — Title of the entry
DESCRIPTION — Body of the entry
X-MOOD - Custom property; stores 'mood'
LOCATION — Human-readable location
GEO — Latitude/longitude
    LOCATION is human-readable; GEO is numeric
CATEGORIES — Tags or categories
CLASS — PUBLIC / PRIVATE / CONFIDENTIAL (Defaults to confidential, and honestly does not need to be changed)
    PUBLIC: The event is visible to everyone.	Default if CLASS is omitted.
    PRIVATE: The event is private. Only the owner should see details; others may see “busy” without details. Used for sensitive events.
    CONFIDENTIAL: The event is restricted; details are hidden except for authorized viewers.
STATUS — TENTATIVE / CONFIRMED / CANCELLED
    TENTATIVE: Event is planned but not confirmed.
CONFIRMED: Event is definitely scheduled.
CANCELLED: Event has been canceled.
TRANSP — OPAQUE / TRANSPARENT
    OPAQUE: Event blocks the time — others see you as “busy”. Default for scheduled events
    TRANSPARENT: Event does not block time — others see you as free. Useful for reminders or informational events
    Default: TRANSPARENT (this is so it does not affect any other items in the calendar)
EXDATE — Exception/excluded dates
    Used in EcCal, as appended dates
ATTACH — Attached files or links.
    Attached mimetypes, inline, if not URL/links..
    potentially allowed types:
        application/pdf
        application/zip	ZIP archive	Multiple files bundled
        image/png	PNG image	Diagrams, charts
        image/jpeg	JPEG image	Photos Fixed height for the editor
        image/gif	GIF image	Small animations
        text/plain	Plain text	Notes
        text/html	HTML file	Web content or rich text
        audio/mpeg	MP3 audio	Voice memos
        audio/ogg	OGG audio	Voice memos
        video/mp4	MP4 video	Recordings
        video/ogg	OGG video	Short clips
PRODID — Product identifier (shows which program created the file)
X-* — Any custom extended property (e.g., X-MOOD)

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