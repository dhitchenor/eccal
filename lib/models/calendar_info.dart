import '../providers/settings_provider.dart';

/// Unified calendar information model for all calendar providers
/// (CalDAV, Google Calendar, Apple Calendar)
class CalendarInfo {
  /// Unique identifier for the calendar
  /// - CalDAV: Calendar name
  /// - Google: Calendar ID (e.g., "abc123@group.calendar.google.com")
  /// - Apple: Calendar identifier
  final String id;

  /// Display name of the calendar
  final String name;

  /// Optional description of the calendar
  final String? description;

  /// Whether this is the primary/default calendar
  final bool isPrimary;

  /// The provider this calendar belongs to
  final CalendarProvider provider;

  /// Optional calendar color (hex format)
  final String? color;

  const CalendarInfo({
    required this.id,
    required this.name,
    this.description,
    this.isPrimary = false,
    required this.provider,
    this.color,
  });

  /// Display name for UI
  String get displayName => name;

  /// Value for selection/storage
  String get selectionValue => id;

  /// Provider name as string
  String get providerName {
    switch (provider) {
      case CalendarProvider.caldav:
        return 'CalDAV';
      case CalendarProvider.google:
        return 'Google Calendar';
      case CalendarProvider.apple:
        return 'Apple Calendar';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          provider == other.provider;

  @override
  int get hashCode => Object.hash(id, provider);

  @override
  String toString() => '$name ($providerName)';

  /// Create a copy with some fields updated
  CalendarInfo copyWith({
    String? id,
    String? name,
    String? description,
    bool? isPrimary,
    CalendarProvider? provider,
    String? color,
  }) {
    return CalendarInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isPrimary: isPrimary ?? this.isPrimary,
      provider: provider ?? this.provider,
      color: color ?? this.color,
    );
  }
}
