import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/moods.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import '../services/export_service.dart';
import '../services/file_storage_service.dart';
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

    // Listen to search changes and rebuild
    _searchController.addListener(() {
      setState(() {
        // Rebuild to filter entries
      });
    });
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: isNarrow
              ? Column(
                  children: [
                    // Mood filter dropdown
                    DropdownButtonFormField<String>(
                      value: widget.selectedMoodFilter,
                      decoration: InputDecoration(
                        labelText: 'mood'.tr(),
                        prefixIcon: const Icon(Icons.mood, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black87,
                      ),
                      items: MoodHelper.buildMoodFilterItems(),
                      onChanged: widget.onMoodFilterChanged,
                    ),
                    const SizedBox(height: 8),
                    // Location filter button styled as dropdown
                    InkWell(
                      onTap: () => _showLocationFilterModal(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'location'.tr(),
                          prefixIcon: const Icon(Icons.location_on, size: 20),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          widget.selectedLocationFilters.isEmpty
                              ? 'sidebar.all_locations'.tr()
                              : 'sidebar.selected_count'.tr([
                                  widget.selectedLocationFilters.length
                                      .toString(),
                                ]),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Mood filter dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: widget.selectedMoodFilter,
                        decoration: InputDecoration(
                          labelText: 'mood'.tr(),
                          prefixIcon: const Icon(Icons.mood, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.black87,
                        ),
                        items: MoodHelper.buildMoodFilterItems(),
                        onChanged: widget.onMoodFilterChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Location filter button styled as dropdown
                    Expanded(
                      child: InkWell(
                        onTap: () => _showLocationFilterModal(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Location',
                            prefixIcon: const Icon(Icons.location_on, size: 20),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            widget.selectedLocationFilters.isEmpty
                                ? 'All locations'
                                : '${widget.selectedLocationFilters.length} selected',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _showDeleteDialog(DiaryEntry entry) {
    // Just call the onDelete callback directly - it will show its own confirmation dialog
    if (widget.onDelete != null) {
      widget.onDelete!(entry.id);
    }
  }

  // Remove _performDelete method - not needed anymore

  void _showLocationFilterModal(BuildContext context) {
    // Get all unique locations from ALL entries (primary + append locations)
    final allLocations = <String>{};

    for (final entry in widget.allEntries) {
      // Add primary location
      if (entry.location != null && entry.location!.isNotEmpty) {
        allLocations.add(entry.location!);
      }

      // Add append locations
      for (final appendLocation in entry.appendLocations) {
        if (appendLocation.isNotEmpty) {
          allLocations.add(appendLocation);
        }
      }
    }

    final sortedLocations = allLocations.toList()..sort();

    if (sortedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sidebar.no_locations_found'.tr())),
      );
      return;
    }

    // Create a copy of current selections for modal state
    final tempSelections = Set<String>.from(widget.selectedLocationFilters);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('sidebar.filter_by_location'.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: sortedLocations.map((location) {
                final isSelected = tempSelections.contains(location);
                return CheckboxListTile(
                  title: Text(location),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        tempSelections.add(location);
                      } else {
                        tempSelections.remove(location);
                      }
                    });
                  },
                  dense: true,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  tempSelections.clear();
                });
              },
              child: Text('sidebar.clear_all'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onLocationFiltersChanged(tempSelections.toList());
                Navigator.of(dialogContext).pop();
              },
              child: Text('apply'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    final provider = context.watch<DiaryProvider>();

    // Get search query
    final searchQuery = _searchController.text.toLowerCase().trim();

    // Apply search filter using SearchHelper
    var filteredEntries = SearchHelper.searchEntries(
      entries: widget.entries,
      query: searchQuery,
      use24HourFormat: widget.use24HourFormat,
    );

    // Apply mood filter (check both primary and append moods)
    if (widget.selectedMoodFilter != null) {
      filteredEntries = filteredEntries.where((entry) {
        // Check primary mood
        if (entry.mood == widget.selectedMoodFilter) {
          return true;
        }

        // Check append moods
        for (final appendMood in entry.appendMoods) {
          if (appendMood == widget.selectedMoodFilter) {
            return true;
          }
        }

        return false;
      }).toList();
    }

    // Apply location filter (check both primary and append locations)
    if (widget.selectedLocationFilters.isNotEmpty) {
      filteredEntries = filteredEntries.where((entry) {
        // Check primary location
        if (entry.location != null &&
            widget.selectedLocationFilters.contains(entry.location)) {
          return true;
        }

        // Check append locations
        for (final appendLocation in entry.appendLocations) {
          if (widget.selectedLocationFilters.contains(appendLocation)) {
            return true;
          }
        }

        return false;
      }).toList();
    }

    // Build list
    return ListView(
      children: filteredEntries.map((entry) {
        final hasServer = provider.isOnServer(entry.id);
        final hasLocal = true;
        return _buildEntryTile(entry, hasLocal: hasLocal, hasServer: hasServer);
      }).toList(),
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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: isSelected
              ? BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.tertiary.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                )
              : null,
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
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors
                          .grey
                          .shade200 // Lighter grey for dark theme
                    : Colors.grey.shade800, // Darker grey for light theme
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Storage status icon
                Builder(
                  builder: (context) {
                    Widget icon;

                    if (hasLocal && hasServer) {
                      // Saved to both - green checkmark in circle
                      icon = const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Colors.green,
                      );
                    } else if (hasServer) {
                      // Server only - blue cloud
                      icon = const Icon(
                        Icons.cloud,
                        size: 20,
                        color: Colors.blue,
                      );
                    } else if (hasLocal) {
                      // Local only - blue folder
                      icon = const Icon(
                        Icons.folder,
                        size: 20,
                        color: Colors.blue,
                      );
                    } else {
                      // This shouldn't happen, but let's log it
                      icon = const Icon(
                        Icons.error,
                        size: 20,
                        color: Colors.red,
                      );
                    }
                    return icon;
                  },
                ),
                SizedBox(
                  width: constraints.maxWidth < 375 ? 2 : 8,
                ), // Smaller gap when narrow
                // Delete button (only show when width >= 375px)
                if (constraints.maxWidth >= 375)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showDeleteDialog(entry),
                    tooltip: 'delete'.tr(),
                  ),
                if (constraints.maxWidth >= 375) const SizedBox(width: 4),
                // Options menu
                Builder(
                  builder: (BuildContext context) => PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors
                                .grey
                                .shade200 // Lighter grey for dark theme
                          : Colors.grey.shade800, // Darker grey for light theme
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 150,
                      maxWidth: 200,
                    ),
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility, size: 18),
                            const SizedBox(width: 8),
                            Text('view'.tr()),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'append',
                        child: Row(
                          children: [
                            const Icon(Icons.add, size: 18),
                            const SizedBox(width: 8),
                            Text('sidebar.append_to_entry'.tr()),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'export',
                        child: Row(
                          children: [
                            const Icon(Icons.file_download, size: 18),
                            const SizedBox(width: 8),
                            Text('export'.tr()),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'delete'.tr(),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (String value) {
                      switch (value) {
                        case 'view':
                          widget.onEntryTap(entry);
                          break;
                        case 'append':
                          if (widget.onAppend != null) {
                            widget.onAppend!(entry.id);
                          }
                          break;
                        case 'export':
                          _showExportDialog(context, entry);
                          break;
                        case 'delete':
                          if (widget.onDelete != null) {
                            widget.onDelete!(entry.id);
                          }
                          break;
                      }
                    },
                  ),
                ),
              ],
            ),
            // Remove tileColor line - now using Container decoration
            onTap: () => widget.onEntrySelected(entry),
            onLongPress: isMobile
                ? () {
                    // Show context menu on long press (mobile only)
                    final RenderBox button =
                        context.findRenderObject() as RenderBox;
                    final RenderBox overlay =
                        Navigator.of(
                              context,
                            ).overlay!.context.findRenderObject()
                            as RenderBox;
                    final RelativeRect position = RelativeRect.fromRect(
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
                      items: [
                        PopupMenuItem<String>(
                          value: 'view',
                          child: Row(
                            children: [
                              const Icon(Icons.visibility, size: 18),
                              const SizedBox(width: 8),
                              Text('view'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'append',
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: 18),
                              const SizedBox(width: 8),
                              Text('sidebar.append_to_entry'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'export',
                          child: Row(
                            children: [
                              const Icon(Icons.file_download, size: 18),
                              const SizedBox(width: 8),
                              Text('export'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'delete'.tr(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).then((value) {
                      if (value != null) {
                        switch (value) {
                          case 'view':
                            widget.onEntryTap(entry);
                            break;
                          case 'append':
                            if (widget.onAppend != null) {
                              widget.onAppend!(entry.id);
                            }
                            break;
                          case 'export':
                            _showExportDialog(context, entry);
                            break;
                          case 'delete':
                            if (widget.onDelete != null) {
                              widget.onDelete!(entry.id);
                            }
                            break;
                        }
                      }
                    });
                  }
                : null, // Desktop has no long press
          ),
        );
      },
    );
  }

  void _showExportDialog(BuildContext context, DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('sidebar.export_entry'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('sidebar.export_to'.tr([entry.title])),
            const SizedBox(height: 16),
            Text(
              'sidebar.choose_format'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportEntry(context, entry, 'txt');
            },
            icon: const Icon(Icons.text_snippet),
            label: const Text('.txt'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportEntry(context, entry, 'ics');
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('.ics'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportEntry(context, entry, 'md');
            },
            icon: const Icon(Icons.article),
            label: const Text('.md'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportEntry(
    BuildContext context,
    DiaryEntry entry,
    String format,
  ) async {
    try {
      final fileStorage = FileStorageService();

      // Show loading
      ErrorSnackbar.showInfo(
        context,
        'sidebar.exporting_as'.tr([entry.title, format]),
        duration: const Duration(seconds: 1),
      );

      // Check if user has configured SAF (Android only)
      String? safUri;
      String outputDirPath = '';
      String locationDescription = '';

      if (Platform.isAndroid) {
        safUri = await fileStorage.getSafUri();

        if (safUri != null) {
          // User has SAF configured - export to SAF location
          locationDescription = await fileStorage
              .getStorageLocationDescription();
        } else {
          // No SAF - use Downloads folder (accessible)
          outputDirPath = '/storage/emulated/0/Download';
          locationDescription = 'Downloads';

          final outputDir = Directory(outputDirPath);
          if (!await outputDir.exists()) {
            await outputDir.create(recursive: true);
          }
        }
      } else {
        // Desktop/iOS: use app documents directory
        final docsDir = await getApplicationDocumentsDirectory();
        outputDirPath = docsDir.path;
        locationDescription = docsDir.path;
      }

      // Convert format string to ExportFormat enum
      final ExportFormat exportFormat;
      switch (format.toLowerCase()) {
        case 'txt':
          exportFormat = ExportFormat.txt;
          break;
        case 'md':
          exportFormat = ExportFormat.md;
          break;
        case 'ics':
        default:
          exportFormat = ExportFormat.ics;
          break;
      }

      // Export entry using ExportService
      final result = await ExportService.exportSingleEntry(
        entry: entry,
        outputDirectory: outputDirPath,
        format: exportFormat,
        safUri: safUri, // Pass SAF URI if available
      );

      // Extract just the filename from the result (might be full path or just filename)
      final fileName = result.split('/').last;

      // Show success with file name and location
      if (context.mounted) {
        ErrorSnackbar.showSuccess(
          context,
          'sidebar.exported_to'.tr(['$fileName in $locationDescription']),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorSnackbar.showError(
          context,
          'sidebar.export_failed'.tr([e.toString()]),
        );
      }
    }
  }
}
