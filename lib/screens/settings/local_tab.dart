import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/diary_provider.dart';
import '../../services/export_service.dart';
import '../../services/file_storage_service.dart';
import '../../services/logger_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/error_snackbar.dart';

class LocalTab extends StatefulWidget {
  final String? currentStoragePath;
  final bool isLoadingPath;
  final VoidCallback onChooseStorageDirectory;
  final VoidCallback onResetToDefaultPath;

  const LocalTab({
    Key? key,
    required this.currentStoragePath,
    required this.isLoadingPath,
    required this.onChooseStorageDirectory,
    required this.onResetToDefaultPath,
  }) : super(key: key);

  @override
  State<LocalTab> createState() => _LocalTabState();
}

class _LocalTabState extends State<LocalTab> {
  ExportFormat _selectedExportFormat = ExportFormat.txt;
  bool _isExporting = false;

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final diaryProvider = context.read<DiaryProvider>();
      final entries = diaryProvider.entries;

      if (entries.isEmpty) {
        if (!mounted) return;
        ErrorSnackbar.showWarning(
          context,
          'local_settings.export_no_entries'.tr(),
        );
        setState(() {
          _isExporting = false;
        });
        return;
      }

      final storagePath = widget.currentStoragePath;
      if (storagePath == null) {
        if (!mounted) return;
        ErrorSnackbar.showError(
          context,
          'local_settings.export_no_storage'.tr(),
        );
        setState(() {
          _isExporting = false;
        });
        return;
      }

      // Get export location (with eccal_exports subfolder)
      final fileStorage = FileStorageService();
      final location = await fileStorage.getExportLocation();

      // Export entries
      final zipPath = await ExportService.exportAllEntries(
        entries: entries,
        outputDirectory: location.directory,
        format: _selectedExportFormat,
        safUri: location.safUri,
        subfolder: location.subfolder,
      );

      if (!mounted) return;
      ErrorSnackbar.showSuccess(
        context,
        '${'local_settings.export_success'.tr([entries.length.toString()])}, ${zipPath.split('/').last}',
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorSnackbar.showError(
        context,
        'sidebar.export_failed'.tr([e.toString()]),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),

        // Default File Format Section
        Row(
          children: [
            Text(
              'local_settings.default_file_format'.tr(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<FileFormat>(
                value: settings.fileFormat,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(
                    value: FileFormat.ics,
                    child: Text('.ics'),
                  ),
                  DropdownMenuItem(
                    value: FileFormat.txt,
                    child: Text('.txt'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setFileFormat(value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'local_settings.file_format_description'.tr(),
            style: TextStyle(fontSize: 12, color: Colors.grey),
            softWrap: true,
          ),
        ),

        const SizedBox(height: 32),

        // Storage Location Section
        Text(
          'local_settings.storage_location'.tr(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'local_settings.current_storage_location'.tr(),
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                if (widget.isLoadingPath)
                  const CircularProgressIndicator()
                else
                  SelectableText(
                    widget.currentStoragePath ?? 'local_settings.storage_not_set'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onChooseStorageDirectory,
                      icon: const Icon(Icons.folder_open),
                      label: Text('local_settings.change_location'.tr()),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: widget.onResetToDefaultPath,
                      icon: const Icon(Icons.refresh),
                      label: Text('local_settings.reset_to_default'.tr()),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'local_settings.change_location_description'.tr(),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Export Section
        Text(
          'local_settings.export_all_entries'.tr(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'local_settings.export_description'.tr(),
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'local_settings.export_as'.tr(),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<ExportFormat>(
                      value: _selectedExportFormat,
                      items: [
                        DropdownMenuItem(
                          value: ExportFormat.txt,
                          child: Text('.txt'),
                        ),
                        DropdownMenuItem(
                          value: ExportFormat.ics,
                          child: Text('.ics'),
                        ),
                        DropdownMenuItem(
                          value: ExportFormat.md,
                          child: Text('.md'),
                        ),
                      ],
                      onChanged: (format) {
                        if (format != null) {
                          setState(() {
                            _selectedExportFormat = format;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _startExport,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.file_download),
                      label: Text(_isExporting ? 'local_settings.exporting'.tr() : 'start'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Logging Section
        Text(
          'local_settings.logging'.tr(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'local_settings.logging_description'.tr(),
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'local_settings.log_level'.tr(),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<LogLevel>(
                      value: settings.logLevel,
                      items: [
                        DropdownMenuItem(
                          value: LogLevel.none,
                          child: Text('local_settings.log_level_none'.tr()),
                        ),
                        DropdownMenuItem(
                          value: LogLevel.info,
                          child: Text('local_settings.log_level_info'.tr()),
                        ),
                        DropdownMenuItem(
                          value: LogLevel.error,
                          child: Text('local_settings.log_level_error'.tr()),
                        ),
                        DropdownMenuItem(
                          value: LogLevel.debug,
                          child: Text('local_settings.log_level_debug'.tr()),
                        ),
                      ],
                      onChanged: (level) {
                        if (level != null) {
                          settings.setLogLevel(level);
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    if (settings.logLevel != LogLevel.none)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final path = await logger.exportLogs();
                          if (!context.mounted) return;
                          if (path != null) {
                            ErrorSnackbar.showSuccess(
                              context,
                              '${'local_settings.logs_exported'.tr()} ${path.split('/').last}',
                            );
                          } else {
                            ErrorSnackbar.showWarning(
                              context,
                              'local_settings.no_logs'.tr(),
                            );
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: Text('local_settings.export_logs'.tr()),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'local_settings.log_levels_title'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• ${'local_settings.log_levels_description_1'.tr()}\n'
                        '• ${'local_settings.log_levels_description_2'.tr()}\n'
                        '• ${'local_settings.log_levels_description_3'.tr()}\n'
                        '• ${'local_settings.log_levels_description_4'.tr()}\n',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
