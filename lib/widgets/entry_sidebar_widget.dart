import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/moods.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import '../services/export_service.dart';
import '../utils/app_localizations.dart';
import '../utils/date_formatter.dart';
import '../utils/error_snackbar.dart';
import '../utils/search_helper.dart';

class EntriesSidebarWidget extends StatefulWidget {
  final List<DiaryEntry> entries;
  final List<DiaryEntry> allEntries; // Unfiltered entries for location list
  final String? selectedMoodFilter;
  final List<String> selectedLocationFilters;
  final DiaryEntry? selectedEntry;
  final bool use24HourFormat;
  final Function(DiaryEntry) onEntrySelected;
  final Function(DiaryEntry) onEntryTap; // For "View" menu option
  final Function(String?) onMoodFilterChanged;
  final Function(List<String>) onLocationFiltersChanged;
  final Function(String entryId)? onAppend; // For "Append" menu option
  final Function(String entryId)? onDelete; // For "Delete" menu option

  const EntriesSidebarWidget({
    Key? key,
    required this.entries,
    required this.allEntries,
    this.selectedMoodFilter,
    required this.selectedLocationFilters,
    this.selectedEntry,
    required this.use24HourFormat,
    required this.onEntrySelected,
    required this.onEntryTap,
    required this.onMoodFilterChanged,
    required this.onLocationFiltersChanged,
    this.onAppend,
    this.onDelete,
  }) : super(key: key);

  @override
  State<EntriesSidebarWidget> createState() => _EntriesSidebarWidgetState();
}

class _EntriesSidebarWidgetState extends State<EntriesSidebarWidget> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilters(context),
        Expanded(child: _buildEntriesList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search entries...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 375;
        final filters = [
          _buildMoodFilter(context, isNarrow),
          _buildLocationFilter(context, isNarrow),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: isNarrow
              ? Column(
                  children: [filters[0], const SizedBox(height: 8), filters[1]],
                )
              : Row(
                  children: [
                    Expanded(child: filters[0]),
                    const SizedBox(width: 8),
                    Expanded(child: filters[1]),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMoodFilter(BuildContext context, bool isNarrow) {
    return DropdownButtonFormField<String>(
      value: widget.selectedMoodFilter,
      decoration: InputDecoration(
        labelText: 'mood'.tr(),
        prefixIcon: const Icon(Icons.mood, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      isExpanded: true,
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
      ),
      items: MoodHelper.buildMoodFilterItems(),
      onChanged: widget.onMoodFilterChanged,
    );
  }

  Widget _buildLocationFilter(BuildContext context, bool isNarrow) {
    return InkWell(
      onTap: () => _showLocationFilterModal(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: isNarrow ? 'location'.tr() : 'Location',
          prefixIcon: const Icon(Icons.location_on, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        child: Text(
          widget.selectedLocationFilters.isEmpty
              ? (isNarrow ? 'sidebar.all_locations'.tr() : 'All locations')
              : (isNarrow
                    ? 'sidebar.selected_count'.tr([
                        widget.selectedLocationFilters.length.toString(),
                      ])
                    : '${widget.selectedLocationFilters.length} selected'),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  void _showDeleteDialog(DiaryEntry entry) {
    if (widget.onDelete != null) {
      widget.onDelete!(entry.id);
    }
  }

  void _showLocationFilterModal(BuildContext context) {
    // Extract all unique locations from entries
    final locations =
        widget.allEntries
            .expand((entry) {
              final locs = <String>[];
              if (entry.location?.isNotEmpty ?? false)
                locs.add(entry.location!);
              locs.addAll(entry.appendLocations.where((loc) => loc.isNotEmpty));
              return locs;
            })
            .toSet()
            .toList()
          ..sort();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('sidebar.filter_locations'.tr()),
              content: SizedBox(
                width: double.maxFinite,
                child: locations.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'sidebar.no_locations'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          final location = locations[index];
                          final isSelected = widget.selectedLocationFilters
                              .contains(location);

                          return CheckboxListTile(
                            title: Text(location),
                            value: isSelected,
                            dense: true,
                            onChanged: (bool? checked) {
                              setModalState(() {
                                final newFilters = List<String>.from(
                                  widget.selectedLocationFilters,
                                );
                                if (checked == true) {
                                  newFilters.add(location);
                                } else {
                                  newFilters.remove(location);
                                }
                                widget.onLocationFiltersChanged(newFilters);
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                if (widget.selectedLocationFilters.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      widget.onLocationFiltersChanged([]);
                      Navigator.pop(context);
                    },
                    child: Text('sidebar.clear_all'.tr()),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('done'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEntriesList() {
    // Filter entries based on search
    final filteredEntries = _searchController.text.isEmpty
        ? widget.entries
        : SearchHelper.searchEntries(
            entries: widget.entries,
            query: _searchController.text,
            use24HourFormat: widget.use24HourFormat,
          );

    if (filteredEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _searchController.text.isEmpty
                ? 'sidebar.no_entries'.tr()
                : 'sidebar.no_matching_entries'.tr(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final diaryProvider = context.watch<DiaryProvider>();

    return ListView.builder(
      itemCount: filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        final hasLocal = true;
        final hasServer = diaryProvider.isOnServer(entry.id);

        return _buildEntryTile(entry, hasLocal: hasLocal, hasServer: hasServer);
      },
    );
  }

  Widget _buildEntryTile(
    DiaryEntry entry, {
    required bool hasLocal,
    required bool hasServer,
  }) {
    final isSelected = widget.selectedEntry?.id == entry.id;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 300;
        final showDeleteButton = constraints.maxWidth >= 375;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: isSelected ? _buildSelectedDecoration(context) : null,
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${MoodHelper.getMoodEmoji(entry.mood)} ${DateFormatter.formatDateTime(entry.dtstart, use24Hour: widget.use24HourFormat, timezone: entry.timezone)}',
              style: TextStyle(color: _getSubtitleColor(context)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStorageIcon(hasLocal, hasServer),
                SizedBox(width: showDeleteButton ? 8 : 2),
                if (showDeleteButton) ...[
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showDeleteDialog(entry),
                    tooltip: 'delete'.tr(),
                  ),
                  const SizedBox(width: 4),
                ],
                _buildPopupMenu(context, entry),
              ],
            ),
            onTap: () => widget.onEntrySelected(entry),
            onLongPress: isMobile
                ? () => _showContextMenu(context, entry)
                : null,
          ),
        );
      },
    );
  }

  BoxDecoration _buildSelectedDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Color _getSubtitleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade200
        : Colors.grey.shade800;
  }

  Widget _buildStorageIcon(bool hasLocal, bool hasServer) {
    if (hasLocal && hasServer) {
      return const Icon(Icons.check_circle, size: 20, color: Colors.green);
    } else if (hasServer) {
      return const Icon(Icons.cloud, size: 20, color: Colors.blue);
    } else if (hasLocal) {
      return const Icon(Icons.folder, size: 20, color: Colors.blue);
    } else {
      return const Icon(Icons.error, size: 20, color: Colors.red);
    }
  }

  Widget _buildPopupMenu(BuildContext context, DiaryEntry entry) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20, color: _getSubtitleColor(context)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
      itemBuilder: (_) => _buildMenuItems(),
      onSelected: (value) => _handleMenuAction(value, entry, context),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    return [
      _buildMenuItem('view', Icons.visibility, 'view'.tr()),
      _buildMenuItem('append', Icons.add, 'sidebar.append_to_entry'.tr()),
      _buildMenuItem('export', Icons.file_download, 'export'.tr()),
      _buildMenuItem('delete', Icons.delete, 'delete'.tr(), color: Colors.red),
    ];
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: color != null ? TextStyle(color: color) : null),
        ],
      ),
    );
  }

  void _handleMenuAction(
    String action,
    DiaryEntry entry,
    BuildContext context,
  ) {
    switch (action) {
      case 'view':
        widget.onEntryTap(entry);
      case 'append':
        widget.onAppend?.call(entry.id);
      case 'export':
        _showExportDialog(context, entry);
      case 'delete':
        widget.onDelete?.call(entry.id);
    }
  }

  void _showContextMenu(BuildContext context, DiaryEntry entry) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: _buildMenuItems(),
    ).then((value) {
      if (value != null) _handleMenuAction(value, entry, context);
    });
  }

  void _showExportDialog(BuildContext context, DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('export'.tr()),
        content: Text('export_dialog.select_format'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportEntry(context, entry, ExportFormat.md);
            },
            child: Text('Markdown'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportEntry(context, entry, ExportFormat.txt);
            },
            child: Text('export_dialog.plain_text'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _exportEntry(
    BuildContext context,
    DiaryEntry entry,
    ExportFormat format,
  ) async {
    try {
      final directory =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final filePath = await ExportService.exportSingleEntry(
        entry: entry,
        outputDirectory: directory.path,
        format: format,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('export_dialog.export_success'.tr([filePath])),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ErrorSnackbar.showError(
        context,
        'export_dialog.export_failed'.tr([e.toString()]),
      );
    }
  }
}
