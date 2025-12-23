import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_screen.dart';
import 'home/android_drawer.dart';
import 'home/desktop_layout.dart';
import 'home/mobile_layout.dart';
import 'home/main_section.dart';
import 'home/refresh_button.dart';
import '../config/app_config.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import '../providers/settings_provider.dart';
import '../services/logger_service.dart';
import '../utils/app_localizations.dart';
import '../utils/append_header_generator.dart';
import '../utils/error_snackbar.dart';
import '../utils/time_helper.dart';
import '../widgets/entry_editor_widget.dart';
import '../widgets/entry_sidebar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<EntryEditorWidgetState> _editorKey =
      GlobalKey<EntryEditorWidgetState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _selectedMoodFilter;
  List<String> _selectedLocationFilters = [];
  bool _isSidebarCollapsed = false;
  bool _isDrawerOpen = false;

  DiaryEntry? _selectedEntry;
  String _viewMode = 'rich_text'; // 'rich_text' or 'markdown'
  bool _isAppendMode = false;

  @override
  void initState() {
    super.initState();
    // Initialization is now handled by InitializationManager in main.dart
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool get _isDesktop {
    return Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows;
  }

  bool get _isAndroid {
    return Theme.of(context).platform == TargetPlatform.android;
  }

  bool get _isIOS {
    return Theme.of(context).platform == TargetPlatform.iOS;
  }

  void _createNewEntry() {
    setState(() {
      _selectedEntry = null;
      _isAppendMode = false;
      _editorKey.currentState?.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        automaticallyImplyLeading: false,
        actions: [
          // Mobile: Refresh button in AppBar
          if (!_isDesktop) RefreshButton(onRefresh: _handleRefresh),
          // Mobile: Hamburger menu on right side
          if (!_isDesktop)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
                tooltip: 'menu'.tr(),
              ),
            ),
          // Desktop: Refresh and Settings buttons in top right
          if (_isDesktop) ...[
            RefreshButton(onRefresh: _handleRefresh),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              tooltip: 'settings'.tr(),
            ),
          ],
        ],
      ),
      endDrawer: _isAndroid
          ? AndroidDrawer(
              selectedMoodFilter: _selectedMoodFilter,
              selectedLocationFilters: _selectedLocationFilters,
              selectedEntry: _selectedEntry,
              onEntrySelected: _selectEntry,
              onMoodFilterChanged: (mood) {
                setState(() => _selectedMoodFilter = mood);
              },
              onLocationFiltersChanged: (locations) {
                setState(() => _selectedLocationFilters = locations);
              },
              onDelete: (entryId) {
                _deleteEntry(entryId: entryId, deleteFromServer: true);
              },
              onAppend: (entryId) {
                final entry = context.read<DiaryProvider>().entries.firstWhere(
                  (e) => e.id == entryId,
                );
                setState(() {
                  _selectedEntry = entry;
                  _isAppendMode = true;
                });
              },
              onRefresh: _handleRefresh,
            )
          : null,
      onEndDrawerChanged: (isOpen) {
        setState(() {
          _isDrawerOpen = isOpen;
        });
      },
      body: _isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: (_isDrawerOpen || (_selectedEntry == null && !_isAppendMode))
            ? const SizedBox.shrink(key: ValueKey('empty'))
            : Builder(
                key: const ValueKey('fab'),
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final sidebarWidth = screenWidth / 3;
                  final offset = _isDesktop && !_isSidebarCollapsed
                      ? sidebarWidth + 16.0
                      : 16.0;

                  return Padding(
                    padding: EdgeInsets.only(right: offset),
                    child: FloatingActionButton(
                      onPressed: _createNewEntry,
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onTertiary,
                      child: const Icon(Icons.add),
                      tooltip: 'home_screen.new_entry'.tr(),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return DesktopLayout(
      isSidebarCollapsed: _isSidebarCollapsed,
      onToggleSidebar: () {
        setState(() {
          _isSidebarCollapsed = !_isSidebarCollapsed;
        });
      },
      mainSection: _buildMainSection(),
      entriesSidebar: _buildEntriesSidebar(),
    );
  }

  Widget _buildMobileLayout() {
    return MobileLayout(
      isIOS: _isIOS,
      onRefresh: _handleRefresh,
      mainSection: _buildMainSection(),
      entriesSidebar: _buildEntriesSidebar(),
    );
  }

  Future<void> _handleRefresh() async {
    final provider = context.read<DiaryProvider>();
    final settings = context.read<SettingsProvider>();

    // Show starting message
    if (mounted) {
      ErrorSnackbar.showInfo(
        context,
        'updates.refreshing'.tr(),
        duration: const Duration(seconds: 1),
      );
    }

    bool localSynced = false;
    bool serverSynced = false;
    String? serverError;

    // Reload entries from storage (local sync)
    try {
      await provider.loadEntriesFromStorage();
      localSynced = true;
      logger.info('Local entries loaded successfully');
    } catch (e) {
      logger.error('Error loading local entries: $e');
    }

    // Sync with CalDAV (server sync)
    if (settings.caldavUrl != null && settings.caldavUrl!.isNotEmpty) {
      try {
        await provider.syncWithCalDAV();
        serverSynced = true;
        logger.info('Server sync completed successfully');
      } catch (e) {
        serverSynced = false;
        // Extract meaningful error message
        final errorStr = e.toString();
        if (errorStr.contains('401') || errorStr.contains('Authentication')) {
          serverError = 'caldav.auth_failed'.tr();
        } else if (errorStr.contains('404')) {
          serverError = 'caldav.calendar_not_found'.tr();
        } else if (errorStr.contains('Connection') ||
            errorStr.contains('SocketException')) {
          serverError = 'updates.connection_failed'.tr();
        } else if (errorStr.contains('timeout')) {
          serverError = 'updates.connection_timeout'.tr();
        } else {
          serverError = 'updates.sync_failed'.tr();
        }
        logger.error('Error syncing with CalDAV: $e');
      }
    } else {
      serverError = 'updates.not_configured'.tr();
    }

    // Force UI refresh to update server status indicators
    if (mounted) {
      setState(() {});

      // Build status message
      String message;

      final errorMsg = serverError ?? 'failed'.tr();
      if (localSynced && serverSynced) {
        message =
            '✓ ${'updates.local_synced'.tr()}\n✓ ${'updates.server_synced'.tr()}';
        ErrorSnackbar.showSuccess(context, message);
      } else if (localSynced && !serverSynced) {
        message =
            '✓ ${'updates.local_synced'.tr()}\n✗ ${'updates.server_failed'.tr([errorMsg])}';
        ErrorSnackbar.showWarning(context, message);
      } else if (!localSynced && serverSynced) {
        message =
            '✗ ${'updates.local_failed'.tr()}\n✓ ${'updates.server_synced'.tr()}';
        ErrorSnackbar.showWarning(context, message);
      } else {
        message =
            '✗ ${'updates.local_failed'.tr()}\n✗ ${'updates.server_failed'.tr([errorMsg])}';
        ErrorSnackbar.showError(context, message);
      }
    }
  }

  Widget _buildMainSection() {
    return MainSection(
      selectedEntry: _selectedEntry,
      isAppendMode: _isAppendMode,
      editorKey: _editorKey,
      viewMode: _viewMode,
      onSave: _handleSaveEntry,
      onCancelAppend: () {
        setState(() {
          _isAppendMode = false;
        });
      },
      onStartAppend: _startAppendMode,
      onEntryDeleted: () {
        setState(() {
          _selectedEntry = null;
        });
      },
      onViewModeChanged: (mode) {
        setState(() => _viewMode = mode);
      },
    );
  }

  Widget _buildEntriesSidebar() {
    final provider = context.watch<DiaryProvider>();
    final entries = provider.entries;
    final allEntries = provider.entries; // Unfiltered entries

    return EntriesSidebarWidget(
      entries: entries,
      allEntries: allEntries,
      selectedMoodFilter: _selectedMoodFilter,
      selectedLocationFilters: _selectedLocationFilters,
      selectedEntry: _selectedEntry,
      use24HourFormat: context.watch<SettingsProvider>().use24HourFormat,
      onEntrySelected: _selectEntry,
      onEntryTap: _selectEntry, // For "View" menu option - selects the entry
      onMoodFilterChanged: (value) {
        setState(() => _selectedMoodFilter = value);
      },
      onLocationFiltersChanged: (values) {
        setState(() => _selectedLocationFilters = values);
      },
      onAppend: (entryId) {
        // Select the entry first, then start append mode
        final entry = entries.firstWhere((e) => e.id == entryId);
        _selectEntry(entry);
        _startAppendMode();
      },
      onDelete: (entryId) {
        // Delete from both local and server
        _deleteEntry(deleteFromServer: true, entryId: entryId);
      },
    );
  }

  void _selectEntry(DiaryEntry entry) {
    setState(() {
      _selectedEntry = entry;
      _isAppendMode = false;
    });
  }

  void _startAppendMode() {
    setState(() {
      _isAppendMode = true;
      _editorKey.currentState?.clear();
    });
  }

  void _deleteEntry({bool deleteFromServer = false, String? entryId}) {
    final id = entryId ?? _selectedEntry?.id;
    if (id == null) return;

    // Capture scaffold context before showing dialog
    final scaffoldContext = context;

    DiaryEntry? entry;
    try {
      entry = scaffoldContext.read<DiaryProvider>().entries.firstWhere(
        (e) => e.id == id,
      );
    } catch (e) {
      ErrorSnackbar.showWarning(
        scaffoldContext,
        'home_screen.entry_notfound'.tr(),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_dialog.title'.tr()),
        content: Text('delete_dialog.message'.tr([entry!.title])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog first

              final provider = scaffoldContext.read<DiaryProvider>();

              try {
                // Delete from both local and server
                await provider.deleteEntry(id);

                if (mounted) {
                  ErrorSnackbar.showSuccess(
                    scaffoldContext,
                    'viewer.entry_deleted'.tr(),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ErrorSnackbar.showError(
                    scaffoldContext,
                    'viewer.error_deleting'.tr([e.toString()]),
                  );
                }
              }

              // Clear selection if it was the selected entry
              if (_selectedEntry?.id == id) {
                setState(() {
                  _selectedEntry = null;
                });
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _handleSaveEntry(
    String title,
    String description,
    String mood,
    String? location,
    double? latitude,
    double? longitude,
  ) async {
    final provider = context.read<DiaryProvider>();
    final settings = context.read<SettingsProvider>();

    // Create a ValueNotifier to track the message
    final messageNotifier = ValueNotifier<String>('save_dialog.preparing'.tr());

    // Show dialog with ValueListenableBuilder
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: ValueListenableBuilder<String>(
          valueListenable: messageNotifier,
          builder: (context, message, child) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(message),
                ],
              ),
            );
          },
        ),
      ),
    );

    // Small delay so user can see "Preparing..." message
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      if (_isAppendMode && _selectedEntry != null) {
        // Append to existing entry
        // Get current time in the entry's timezone
        final now = nowInTimezone(_selectedEntry!.timezone);

        // Generate append header using utility
        final appendHeader = AppendHeaderGenerator.generateFromSettings(
          appendDate: now,
          settings: settings,
          mood: mood,
          location: location,
        );

        final updatedDescription =
            '${_selectedEntry!.description}\n\n$appendHeader\n$description';

        // Add append metadata to lists
        final updatedAppendDates = [..._selectedEntry!.appendDates, now];
        final updatedAppendMoods = [..._selectedEntry!.appendMoods, mood];
        final updatedAppendLocations = [
          ..._selectedEntry!.appendLocations,
          location ?? '',
        ];
        final updatedAppendLatitudes = [
          ..._selectedEntry!.appendLatitudes,
          latitude,
        ];
        final updatedAppendLongitudes = [
          ..._selectedEntry!.appendLongitudes,
          longitude,
        ];

        final updatedEntry = DiaryEntry(
          id: _selectedEntry!.id,
          title: _selectedEntry!.title,
          description: updatedDescription,
          dtstart: _selectedEntry!.dtstart,
          dtstamp: now,
          mood: _selectedEntry!.mood,
          location: _selectedEntry!.location,
          latitude: _selectedEntry!.latitude,
          longitude: _selectedEntry!.longitude,
          categories: _selectedEntry!.categories,
          appendDates: updatedAppendDates,
          appendMoods: updatedAppendMoods,
          appendLocations: updatedAppendLocations,
          appendLatitudes: updatedAppendLatitudes,
          appendLongitudes: updatedAppendLongitudes,
          attachments: _selectedEntry!.attachments,
          timezone: _selectedEntry!.timezone,
        );

        await provider.updateEntry(
          updatedEntry,
          onProgress: (msg) => messageNotifier.value = msg,
        );

        if (mounted) {
          Navigator.of(context).pop();

          setState(() {
            _selectedEntry = updatedEntry;
            _isAppendMode = false;
            _editorKey.currentState?.clear();
          });

          ErrorSnackbar.showSuccess(context, 'save_dialog.entry_saved'.tr());
        }
      } else if (_selectedEntry != null) {
        // Edit existing entry
        final updatedEntry = DiaryEntry(
          id: _selectedEntry!.id,
          title: title,
          description: description,
          dtstart: _selectedEntry!.dtstart,
          dtstamp: DateTime.now(),
          mood: mood,
          location: location,
          latitude: latitude,
          longitude: longitude,
          categories: _selectedEntry!.categories,
          appendDates: _selectedEntry!.appendDates,
          appendMoods: _selectedEntry!.appendMoods,
          appendLocations: _selectedEntry!.appendLocations,
          appendLatitudes: _selectedEntry!.appendLatitudes,
          appendLongitudes: _selectedEntry!.appendLongitudes,
          attachments: _selectedEntry!.attachments,
          timezone: _selectedEntry!.timezone,
        );

        await provider.updateEntry(
          updatedEntry,
          onProgress: (msg) => messageNotifier.value = msg,
        );

        if (mounted) {
          Navigator.of(context).pop();

          setState(() {
            _selectedEntry = updatedEntry;
          });

          ErrorSnackbar.showSuccess(context, 'save_dialog.entry_saved'.tr());
        }
      } else {
        // Create new entry
        logger.debug('Timezone in Settings = ${settings.timezone}');

        final newEntry = DiaryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          description: description,
          dtstart: nowInTimezone(settings.timezone),
          mood: mood,
          location: location,
          latitude: latitude,
          longitude: longitude,
          timezone: settings.timezone,
        );
        logger.debug('New Entry Timezone = ${newEntry.timezone}');

        await provider.addEntry(
          newEntry,
          onProgress: (msg) => messageNotifier.value = msg,
        );

        if (mounted) {
          Navigator.of(context).pop();

          setState(() {
            _selectedEntry = newEntry;
            _editorKey.currentState?.clear();
          });

          ErrorSnackbar.showSuccess(context, 'save_dialog.entry_saved'.tr());
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

        ErrorSnackbar.showError(
          context,
          'save_dialog.entry_saved'.tr([e.toString()]),
        );
      }
    } finally {
      messageNotifier.dispose();
    }
  }
}
