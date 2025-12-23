import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/diary_entry.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/entry_editor_widget.dart';
import '../../widgets/entry_viewer_widget.dart';

class MainSection extends StatelessWidget {
  final DiaryEntry? selectedEntry;
  final bool isAppendMode;
  final GlobalKey editorKey;
  final String viewMode;
  final Function(String title, String description, String mood, String? location, double? latitude, double? longitude) onSave;
  final VoidCallback onCancelAppend;
  final VoidCallback onStartAppend;
  final VoidCallback onEntryDeleted;
  final Function(String) onViewModeChanged;

  const MainSection({
    Key? key,
    required this.selectedEntry,
    required this.isAppendMode,
    required this.editorKey,
    required this.viewMode,
    required this.onSave,
    required this.onCancelAppend,
    required this.onStartAppend,
    required this.onEntryDeleted,
    required this.onViewModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show editor when no entry is selected or in append mode, viewer when entry is selected
    if (selectedEntry == null || isAppendMode) {
      final settings = context.watch<SettingsProvider>();
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: EntryEditorWidget(
          key: editorKey,
          entry: selectedEntry,
          isAppendMode: isAppendMode,
          initialTitle: selectedEntry == null ? settings.generateEntryTitle() : null,
          onSave: onSave,
          onCancelAppend: onCancelAppend,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: EntryViewerWidget(
          entry: selectedEntry!,
          viewMode: viewMode,
          use24HourFormat: context.watch<SettingsProvider>().use24HourFormat,
          onViewModeChanged: onViewModeChanged,
          onAppend: onStartAppend,
          onDeleted: onEntryDeleted,
        ),
      );
    }
  }
}