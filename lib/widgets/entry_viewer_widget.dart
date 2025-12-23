import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../constants/moods.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/date_formatter.dart';
import '../utils/error_snackbar.dart';
import '../services/entry_conversion.dart';

class EntryViewerWidget extends StatefulWidget {
  final DiaryEntry entry;
  final String viewMode; // 'rich_text' or 'markdown'
  final bool use24HourFormat;
  final Function(String) onViewModeChanged;
  final VoidCallback onAppend; // Called after append is confirmed
  final VoidCallback? onDeleted; // Called after entry is deleted

  const EntryViewerWidget({
    Key? key,
    required this.entry,
    required this.viewMode,
    required this.use24HourFormat,
    required this.onViewModeChanged,
    required this.onAppend,
    this.onDeleted,
  }) : super(key: key);

  @override
  State<EntryViewerWidget> createState() => _EntryViewerWidgetState();
}

class _EntryViewerWidgetState extends State<EntryViewerWidget> {
  bool _cancelDelete = false;

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('viewer.delete_entry'.tr()),
        content: Text(
          '${'delete_dialog.message'.tr([widget.entry.title])}\n\n${'viewer.delete_explanation'.tr()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              _performDelete(); // Start deletion with progress dialog
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    setState(() {
      _cancelDelete = false;
    });

    // Show progress dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('viewer.deleting_entry'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('viewer.deleting_please_wait'.tr()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _cancelDelete = true;
              });
              Navigator.pop(context); // Close progress dialog
            },
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );

    try {
      final provider = context.read<DiaryProvider>();

      // Delete from both local and server
      await provider.deleteEntry(widget.entry.id);

      // Check if cancelled
      if (_cancelDelete) {
        if (mounted) {
          // Just refresh UI without showing success message
          provider.refreshUI();
        }
        return;
      }

      if (mounted) {
        Navigator.pop(context); // Close progress dialog

        ErrorSnackbar.showSuccess(
          context,
          'viewer.entry_deleted'.tr(),
        );

        // Notify parent that entry was deleted
        widget.onDeleted?.call();
      }
    } catch (e) {
      if (mounted) {
        if (!_cancelDelete) {
          Navigator.pop(context); // Close progress dialog
        }

        ErrorSnackbar.showError(
          context,
          'viewer.error_deleting'.tr([e.toString()]),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cancelDelete = false;
        });
      }
    }
  }

  void _handleAppend() {
    // Just call the parent's append handler
    widget.onAppend();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View mode dropdown and action buttons
        Row(
          children: [
            Text(
              'view'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: widget.viewMode,
              items: [
                DropdownMenuItem(
                  value: 'rich_text',
                  child: Text('viewer.rich_text'.tr()),
                ),
                DropdownMenuItem(
                  value: 'markdown',
                  child: Text('viewer.markdown'.tr()),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.onViewModeChanged(value);
                }
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _handleAppend,
              icon: const Icon(Icons.add),
              label: Text('append'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _handleDelete,
              icon: const Icon(Icons.delete),
              label: Text('delete'.tr()),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(child: _buildEntryContent(context)),
      ],
    );
  }

  Widget _buildEntryContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entry header
            _buildEntryHeader(context),
            const Divider(height: 32),

            // Entry content
            if (widget.viewMode == 'rich_text')
              _buildRichTextView()
            else
              _buildMarkdownView(),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if screen is narrow
        final isNarrow = constraints.maxWidth < 450;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.entry.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (isNarrow)
              // Narrow layout: mood/time on one row, location on next row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        MoodHelper.getMoodEmoji(widget.entry.mood),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          DateFormatter.formatDateTimeWithTZ(
                            widget.entry.dtstart,
                            use24Hour: widget.use24HourFormat,
                            timezone: widget.entry.timezone,
                          ),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.public, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        widget.entry.timezone,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (widget.entry.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.entry.location!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              )
            else
              // Wide layout: everything on one row
              Row(
                children: [
                  Text(
                    MoodHelper.getMoodEmoji(widget.entry.mood),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormatter.formatDateTimeWithTZ(
                      widget.entry.dtstart,
                      use24Hour: widget.use24HourFormat,
                      timezone: widget.entry.timezone,
                    ),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.public, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    widget.entry.timezone,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  if (widget.entry.location != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.entry.location!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildRichTextView() {
    // Convert Markdown to Quill Document for rich text display
    final document = EntryConverter.fromMarkdown(widget.entry.description);
    final controller = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    return quill.QuillEditor.basic(
      controller: controller,
      config: const quill.QuillEditorConfig(
        scrollable: true,
        padding: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildMarkdownView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        widget.entry.description,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'monospace',
          height: 1.5,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}
