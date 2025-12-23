import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'simple_rich_text_editor.dart';
import '../constants/moods.dart';
import '../models/diary_entry.dart';
import '../providers/settings_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/date_formatter.dart';
import '../utils/error_snackbar.dart';

class EntryEditorWidget extends StatefulWidget {
  final DiaryEntry? entry;
  final bool isAppendMode;
  final String? initialTitle;
  final Function(
    String title,
    String description,
    String mood,
    String? location,
    double? latitude,
    double? longitude,
  )
  onSave;
  final VoidCallback? onCancelAppend;

  const EntryEditorWidget({
    Key? key,
    this.entry,
    this.isAppendMode = false,
    this.initialTitle,
    required this.onSave,
    this.onCancelAppend,
  }) : super(key: key);

  @override
  State<EntryEditorWidget> createState() => EntryEditorWidgetState();
}

class EntryEditorWidgetState extends State<EntryEditorWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final GlobalKey<SimpleRichTextEditorState> _editorKey =
      GlobalKey<SimpleRichTextEditorState>();
  String _selectedMood = 'neutral';
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null && !widget.isAppendMode) {
      _titleController.text = widget.entry!.title;
      _locationController.text = widget.entry!.location ?? '';
      _selectedMood = widget.entry!.mood;
      // Set markdown content after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editorKey.currentState?.setMarkdown(widget.entry!.description);
      });
    } else if (widget.initialTitle != null && widget.entry == null) {
      // Set initial title for new entries
      _titleController.text = widget.initialTitle!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void clear() {
    _titleController.clear();
    _locationController.clear();
    _selectedMood = 'neutral';
    _latitude = null;
    _longitude = null;
    _editorKey.currentState?.clear();
  }

  String getMarkdown() {
    return _editorKey.currentState?.getMarkdown() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return _buildEntryForm();
  }

  Widget _buildEntryForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isAppendMode && widget.entry != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: '${'editor.appending_to'.tr()} '),
                          if (widget.entry!.title.isEmpty) ...[
                            TextSpan(
                              text: 'editor.unnamed_entry'.tr(),
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            if (widget.entry!.location != null &&
                                widget.entry!.location!.isNotEmpty)
                              TextSpan(
                                text: ' ${'at'.tr()} ${widget.entry!.location}',
                                style: TextStyle(color: Colors.blue.shade600),
                              ),
                          ] else
                            TextSpan(text: widget.entry!.title),
                          TextSpan(
                            text: ' (${_formatDate(widget.entry!.dtstart)})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Mood dropdown for append mode
            DropdownButtonFormField<String>(
              value: _selectedMood,
              items: MoodHelper.buildMoodFilterItems(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMood = value);
                }
              },
              isExpanded: true,
            ),
            const SizedBox(height: 16),
            // Location field for append mode
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'location'.tr(),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _getGPSLocation,
                  icon: const Icon(Icons.gps_fixed),
                  label: Text('gps'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (!widget.isAppendMode) ...[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'title'.tr(),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMood,
              items: MoodHelper.buildMoodFilterItems(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMood = value);
                }
              },
              isExpanded: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'location'.tr(),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _getGPSLocation,
                  icon: const Icon(Icons.gps_fixed),
                  label: Text('gps'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Rich text editor with border and dynamic height
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SimpleRichTextEditor(
                key: _editorKey,
                onChanged: (markdown) {
                  // Optional: track changes
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isAppendMode && widget.onCancelAppend != null) ...[
                  OutlinedButton.icon(
                    onPressed: widget.onCancelAppend,
                    icon: const Icon(Icons.cancel),
                    label: Text('editor.cancel_append'.tr()),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: _handleSave,
                  icon: const Icon(Icons.save),
                  label: Text(
                    widget.isAppendMode
                        ? 'editor.save_append'.tr()
                        : 'editor.save_entry'.tr(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getGPSLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ErrorSnackbar.showWarning(
            context,
            'editor.location_services_disabled'.tr(),
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ErrorSnackbar.showWarning(
              context,
              'editor.location_permission_denied'.tr(),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ErrorSnackbar.showWarning(
            context,
            'editor.location_permission_permanently_denied'.tr(),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ErrorSnackbar.showInfo(
          context,
          'editor.getting_gps_location'.tr(),
          duration: const Duration(seconds: 2),
        );
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Store coordinates separately
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Format coordinates and insert into location field
      final coordinates =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      setState(() {
        _locationController.text = coordinates;
      });

      if (mounted) {
        ErrorSnackbar.showSuccess(
          context,
          'editor.location_added'.tr([coordinates]),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.showError(
          context,
          'editor.error_getting_location'.tr([e.toString()]),
        );
      }
    }
  }

  void _handleSave() {
    final markdown = _editorKey.currentState?.getMarkdown() ?? '';
    final title = widget.isAppendMode
        ? widget.entry!.title
        : _titleController.text;
    final location = _locationController.text.isEmpty
        ? null
        : _locationController.text;

    widget.onSave(
      title,
      markdown,
      _selectedMood,
      location,
      _latitude,
      _longitude,
    );
  }

  String _formatDate(DateTime date) {
    // Get time format preference
    final settings = context.read<SettingsProvider>();
    final use24Hour = settings.use24HourFormat;

    // Use DateFormatter with entry's timezone
    return DateFormatter.formatDateTimeWithTZ(
      date,
      use24Hour: use24Hour,
      timezone: widget.entry?.timezone,
    );
  }
}
