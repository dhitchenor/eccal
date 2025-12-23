import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/diary_provider.dart';
import '../../services/export_service.dart';
import '../../services/file_storage_service.dart';
import '../../services/logger_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/error_snackbar.dart';
import 'settings_components.dart';

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

    return ResponsiveSettingsLayout(
      children: [
        SettingsSpacing.item(),

        // Default File Format Section
        SettingsDropdownRow<FileFormat>(
          title: 'local_settings.default_file_format'.tr(),
          helperText: 'local_settings.file_format_description'.tr(),
          value: settings.fileFormat,
          items: const [
            DropdownMenuItem(value: FileFormat.ics, child: Text('.ics')),
            DropdownMenuItem(value: FileFormat.txt, child: Text('.txt')),
          ],
          onChanged: (value) {
            if (value != null) {
              settings.setFileFormat(value);
            }
          },
        ),

        SettingsSpacing.section(),

        // Storage Location Section
        SettingsTitleWithValue(
          title: 'local_settings.storage_location'.tr(),
          value:
              widget.currentStoragePath ??
              'local_settings.storage_not_set'.tr(),
          helperText: 'local_settings.change_location_description'.tr(),
          isLoading: widget.isLoadingPath,
        ),
        SettingsSpacing.item(),
        SettingsButtonRow(
          buttons: [
            ElevatedButton.icon(
              onPressed: widget.onChooseStorageDirectory,
              icon: const Icon(Icons.folder_open),
              label: Text('local_settings.change_location'.tr()),
            ),
            OutlinedButton.icon(
              onPressed: widget.onResetToDefaultPath,
              icon: const Icon(Icons.refresh),
              label: Text('local_settings.reset_to_default'.tr()),
            ),
          ],
        ),

        SettingsSpacing.section(),

        // Export Section
        SettingsTitleWithAction<ExportFormat>(
          title: 'local_settings.export_all_entries'.tr(),
          helperText: 'local_settings.export_description'.tr(),
          actionButton: OutlinedButton.icon(
            onPressed: _isExporting ? null : _startExport,
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download),
            label: Text(
              _isExporting ? 'local_settings.exporting'.tr() : 'start'.tr(),
            ),
          ),
          dropdownLabel: 'local_settings.export_as'.tr(),
          dropdownValue: _selectedExportFormat,
          dropdownItems: const [
            DropdownMenuItem(value: ExportFormat.txt, child: Text('.txt')),
            DropdownMenuItem(value: ExportFormat.ics, child: Text('.ics')),
            DropdownMenuItem(value: ExportFormat.md, child: Text('.md')),
          ],
          onDropdownChanged: (format) {
            if (format != null) {
              setState(() {
                _selectedExportFormat = format;
              });
            }
          },
        ),

        SettingsSpacing.section(),

        // Logging Section
        SettingsTitleWithAction<LogLevel>(
          title: 'local_settings.logging'.tr(),
          helperText: 'local_settings.logging_description'.tr(),
          actionButton: settings.logLevel != LogLevel.none
              ? OutlinedButton.icon(
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
                )
              : null,
          dropdownLabel: 'local_settings.log_level'.tr(),
          dropdownValue: settings.logLevel,
          dropdownItems: [
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
          onDropdownChanged: (level) {
            if (level != null) {
              settings.setLogLevel(level);
            }
          },
        ),
        SettingsSpacing.item(),
        SettingsInfoBox(
          title: 'local_settings.log_levels_title'.tr(),
          content:
              '• ${'local_settings.log_levels_description_1'.tr()}\n'
              '• ${'local_settings.log_levels_description_2'.tr()}\n'
              '• ${'local_settings.log_levels_description_3'.tr()}\n'
              '• ${'local_settings.log_levels_description_4'.tr()}\n',
        ),
      ],
    );
  }
}
