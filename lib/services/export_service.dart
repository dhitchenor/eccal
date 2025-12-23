import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'entry_conversion.dart';
import 'icalendar_generator.dart';
import 'logger_service.dart';
import '../models/diary_entry.dart';
import '../utils/app_localizations.dart';

enum ExportFormat { txt, ics, md, icalendar }

class ExportService {
  // Export all entries to a ZIP file in the specified format
  // Returns the path to the created ZIP file
  static Future<String> exportAllEntries({
    required List<DiaryEntry> entries,
    required String outputDirectory,
    required ExportFormat format,
  }) async {
    // Create archive
    final archive = Archive();
    
    // Add each entry to the archive
    for (final entry in entries) {
      final content = _formatEntryContent(entry, format);
      final filename = _generateFilename(entry, format);
      
      // Create archive file
      final file = ArchiveFile(
        filename,
        content.length,
        content.codeUnits,
      );
      archive.addFile(file);
    }
    
    // Encode archive to ZIP
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      logger.info('Failed to create ZIP archive');
    }
    
    // Generate output filename with timestamp
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final extension = format.name;
    final zipFilename = 'eccal_export_$extension\_$timestamp.zip';
    final zipPath = path.join(outputDirectory, zipFilename);
    
    // Write ZIP file
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipData);
    
    return zipPath;
  }
  
  // Format entry content based on export format
  static String _formatEntryContent(DiaryEntry entry, ExportFormat format) {
    switch (format) {
      case ExportFormat.txt:
        return _formatAsPlainText(entry);
      case ExportFormat.ics:
      case ExportFormat.icalendar:
        return _formatAsICalendar(entry);
      case ExportFormat.md:
        return _formatAsMarkdown(entry);
    }
  }
  
  // Generate filename for entry based on format
  static String _generateFilename(DiaryEntry entry, ExportFormat format) {
    // Use entry title and date for filename, sanitize for filesystem
    final sanitizedTitle = entry.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, entry.title.length > 50 ? 50 : entry.title.length);
    
    final dateStr = entry.dtstart.toIso8601String().split('T')[0];
    
    // Use 'ics' extension for both ics and icalendar formats
    final extension = (format == ExportFormat.icalendar) ? 'ics' : format.name;
    
    return '${dateStr}_$sanitizedTitle.$extension';
  }
  
  // Format entry as plain text (human-readable)
  static String _formatAsPlainText(DiaryEntry entry) {
    final buffer = StringBuffer();
    
    // Title
    buffer.writeln('${'title'.tr()}: ${entry.title}');
    buffer.writeln('${'date'.tr()}: ${entry.dtstart.toIso8601String()}');
    buffer.writeln('${'mood'.tr()}: ${entry.mood}');
    if (entry.location != null && entry.location!.isNotEmpty) {
      buffer.writeln('${'location'.tr()}: ${entry.location}');
    }
    
    // Show append history if exists
    if (entry.appendDates.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${'export.append_history'.tr()}:');
      for (int i = 0; i < entry.appendDates.length; i++) {
        buffer.write('  ${i + 1}. ${entry.appendDates[i].toIso8601String()}');
        
        if (i < entry.appendMoods.length) {
          buffer.write(' | ${'mood'.tr()}: ${entry.appendMoods[i]}');
        }
        
        if (i < entry.appendLocations.length && entry.appendLocations[i].isNotEmpty) {
          buffer.write(' | ${'location'.tr()}: ${entry.appendLocations[i]}');
        }
        
        buffer.writeln();
      }
    }
    
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    
    // Content
    buffer.writeln(entry.description);
    
    return buffer.toString();
  }
  
  // Format entry as iCalendar (.ics) - full fidelity with all X-APPEND properties
  static String _formatAsICalendar(DiaryEntry entry) {
    return ICalendarGenerator.generate(entry);
  }
  
  // Format entry as Markdown (human-readable)
  static String _formatAsMarkdown(DiaryEntry entry) {
    final buffer = StringBuffer();
    
    // Front matter
    buffer.writeln('# ${entry.title}');
    buffer.writeln();
    buffer.writeln('**${'date'.tr()}:** ${entry.dtstart.toIso8601String()}');
    buffer.writeln('**${'mood'.tr()}:** ${entry.mood}');
    if (entry.location != null && entry.location!.isNotEmpty) {
      buffer.writeln('**${'location'.tr()}:** ${entry.location}');
    }
    
    // Show append history if exists
    if (entry.appendDates.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('**${'append_history'.tr()}:**');
      for (int i = 0; i < entry.appendDates.length; i++) {
        buffer.write('- ${entry.appendDates[i].toIso8601String()}');
        
        if (i < entry.appendMoods.length) {
          buffer.write(' | ${'mood'.tr()}: ${entry.appendMoods[i]}');
        }
        
        if (i < entry.appendLocations.length && entry.appendLocations[i].isNotEmpty) {
          buffer.write(' | ${'location'.tr()}: ${entry.appendLocations[i]}');
        }
        
        buffer.writeln();
      }
    }
    
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    
    // Content (already in markdown format)
    buffer.writeln(entry.description);
    
    return buffer.toString();
  }
}