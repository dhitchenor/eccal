class DiaryEntry {
  final String id; // UID
  final String title; // SUMMARY
  final String description; // DESCRIPTION (markdown)
  final DateTime dtstart; // DTSTART (initial creation date)
  final DateTime dtstamp; // DTSTAMP (updates on each save)
  final String mood; // Primary mood (X-MOOD)
  final String? location; // Primary location (LOCATION)
  final double? latitude; // GEO latitude
  final double? longitude; // GEO longitude
  final List<String> categories; // CATEGORIES (tags)
  final List<DateTime> appendDates; // X-APPENDDATE (list of append timestamps)
  final List<String> appendMoods; // X-APPENDMOOD (mood for each append, same index as appendDates)
  final List<String> appendLocations; // X-APPENDLOC (location for each append, same index as appendDates)
  final List<double?> appendLatitudes; // X-APPENDGEO (latitude, same index as appendDates)
  final List<double?> appendLongitudes; // X-APPENDGEO (longitude, same index as appendDates)
  final List<String> attachments; // ATTACH (file paths/URLs)
  final String timezone; // TZID (timezone when entry was created)

  DiaryEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.dtstart,
    DateTime? dtstamp,
    required this.mood,
    this.location,
    this.latitude,
    this.longitude,
    List<String>? categories,
    List<DateTime>? appendDates,
    List<String>? appendMoods,
    List<String>? appendLocations,
    List<double?>? appendLatitudes,
    List<double?>? appendLongitudes,
    List<String>? attachments,
    this.timezone = 'UTC', // Default to UTC
  })  : dtstamp = dtstamp ?? DateTime.now(),
        categories = categories ?? [],
        appendDates = appendDates ?? [],
        appendMoods = appendMoods ?? [],
        appendLocations = appendLocations ?? [],
        appendLatitudes = appendLatitudes ?? [],
        appendLongitudes = appendLongitudes ?? [],
        attachments = attachments ?? [];

  DiaryEntry copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dtstart,
    DateTime? dtstamp,
    String? mood,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? categories,
    List<DateTime>? appendDates,
    List<String>? appendMoods,
    List<String>? appendLocations,
    List<double?>? appendLatitudes,
    List<double?>? appendLongitudes,
    List<String>? attachments,
    String? timezone,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dtstart: dtstart ?? this.dtstart,
      dtstamp: dtstamp ?? this.dtstamp,
      mood: mood ?? this.mood,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      categories: categories ?? this.categories,
      appendDates: appendDates ?? this.appendDates,
      appendMoods: appendMoods ?? this.appendMoods,
      appendLocations: appendLocations ?? this.appendLocations,
      appendLatitudes: appendLatitudes ?? this.appendLatitudes,
      appendLongitudes: appendLongitudes ?? this.appendLongitudes,
      attachments: attachments ?? this.attachments,
      timezone: timezone ?? this.timezone,
    );
  }
}