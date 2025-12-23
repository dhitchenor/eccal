import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'settings/general_tab.dart';
import 'settings/display_tab.dart';
import 'settings/local_tab.dart';
import 'settings/server_tab.dart';
import 'settings/security_tab.dart';
import 'settings/about_tab.dart';
import 'settings/legal_tab.dart';
import '../dialogs/storage_setup_dialog.dart';
import '../providers/settings_provider.dart';
import '../providers/diary_provider.dart';
import '../services/file_storage_service.dart';
import '../services/logger_service.dart';
import '../services/setup_dialogs_manager.dart';
import '../utils/app_localizations.dart';
import '../utils/error_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  final int initialTabIndex;

  const SettingsScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _calendarNameController;
  late TextEditingController _durationController;
  late TextEditingController _titleTemplateController;
  late TabController _tabController;
  late SetupDialogsManager _navigationManager;
  String? _currentStoragePath;
  bool _isLoadingPath = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // Initialize navigation manager (handles tab changes and dialogs)
    _navigationManager = SetupDialogsManager(
      getContext: () => context,
      tabController: _tabController,
    );

    final settings = context.read<SettingsProvider>();
    _urlController = TextEditingController(text: settings.caldavUrl ?? '');
    _usernameController = TextEditingController(
      text: settings.caldavUsername ?? '',
    );
    // Password controller remains empty - password is stored securely
    _passwordController = TextEditingController(text: '');
    _calendarNameController = TextEditingController(
      text: settings.caldavCalendarName ?? '',
    );
    _titleTemplateController = TextEditingController(
      text: settings.defaultEntryTitle,
    );
    _durationController = TextEditingController(
      text: settings.eventDurationMinutes.toString(),
    );
    _loadCurrentPath();
  }

  Future<void> _loadCurrentPath() async {
    final fileStorage = FileStorageService();
    final location = await fileStorage.getStorageLocationDescription();
    setState(() {
      _currentStoragePath = location;
      _isLoadingPath = false;
    });
  }

  Future<void> _chooseStorageDirectory() async {
    String? selectedDirectory;

    if (Platform.isAndroid) {
      // Use SAF on Android - loop until valid selection or cancel
      while (true) {
        final fileStorage = FileStorageService();
        final result = await fileStorage.pickAndSaveDirectory();

        if (result == 'DOWNLOADS_BLOCKED') {
          // Downloads folder blocked - show warning and ask to retry
          if (!mounted) return;

          final retry = await DownloadsWarningDialog.show(context);

          if (retry != true) {
            // User cancelled
            return;
          }

          // Loop continues - picker will open again
          continue;
        } else if (result != null) {
          // SAF selection successful
          logger.info('SAF directory selected in settings: $result');

          if (!mounted) return;

          // Show confirmation dialog for moving entries
          final diaryProvider = context.read<DiaryProvider>();
          final hasEntries = diaryProvider.entries.isNotEmpty;

          if (hasEntries) {
            final newLocation = await FileStorageService()
                .getStorageLocationDescription();

            final confirmed = await MoveEntriesDialog.show(
              context,
              newLocation: newLocation,
              entryCount: diaryProvider.entries.length,
            );

            if (confirmed != true) {
              // User cancelled - reset SAF configuration
              final fileStorage = FileStorageService();
              await fileStorage.resetSafConfiguration();
              return;
            }
          }

          // Show loading indicator while moving entries
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );

          // Reload entries from new location (which copies them via SAF)
          await diaryProvider.loadEntriesFromStorage();

          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog

          // Reload path display to show new location
          await _loadCurrentPath();

          if (!mounted) return;

          ErrorSnackbar.showSuccess(
            context,
            'local_settings.storage_move_success'.tr(),
          );

          return;
        } else {
          // User cancelled picker
          logger.info('User cancelled SAF picker in settings');
          return;
        }
      }
    } else {
      // Desktop/iOS - use FilePicker
      selectedDirectory = await FilePicker.platform.getDirectoryPath();
    }

    if (selectedDirectory != null) {
      final diaryProvider = context.read<DiaryProvider>();

      // Show confirmation dialog using shared dialog
      final confirmed = await MoveEntriesDialog.show(
        context,
        newLocation: selectedDirectory,
        entryCount: diaryProvider.entries.length,
      );

      if (confirmed == true) {
        // Show loading indicator
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          final success = await diaryProvider.moveEntriesToNewLocation(
            selectedDirectory,
          );

          if (!mounted) return;
          Navigator.pop(context);

          if (success) {
            await _loadCurrentPath();
            if (!mounted) return;
            ErrorSnackbar.showSuccess(
              context,
              'local_settings.storage_move_success'.tr(),
            );
          } else {
            if (!mounted) return;
            ErrorSnackbar.showError(
              context,
              'local_settings.storage_move_failed'.tr(),
            );
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context);
          ErrorSnackbar.showError(context, 'error_'.tr([e.toString()]));
        }
      }
    }
  }

  Future<void> _resetToDefaultPath() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('local_settings.reset_storage_location_question'.tr()),
        content: Text('local_settings.moveto_defaultfolder'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('reset'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final fileStorage = FileStorageService();
        await fileStorage.resetSafConfiguration();

        final diaryProvider = context.read<DiaryProvider>();
        await diaryProvider.loadEntriesFromStorage();

        if (!mounted) return;
        Navigator.pop(context);
        await _loadCurrentPath();

        if (!mounted) return;
        ErrorSnackbar.showSuccess(
          context,
          'local_settings.reset_storage_location'.tr(),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ErrorSnackbar.showError(context, 'error_'.tr([e.toString()]));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return WillPopScope(
      onWillPop: () async {
        final shouldBlock = _navigationManager.shouldBlockPop(settings);

        if (shouldBlock) {
          await _navigationManager.handlePopAttempt(context, settings);
          return false; // Don't pop, we'll handle it in the dialog
        }

        return true; // Allow pop
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 72,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () async {
                    final shouldBlock = _navigationManager.shouldBlockPop(
                      settings,
                    );

                    if (shouldBlock) {
                      await _navigationManager.handlePopAttempt(
                        context,
                        settings,
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 16,
                    ), // Add padding on right
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 12, // Reduced from 16 to align better
                        vertical: 4,
                      ),
                      indicatorWeight: 3,
                      tabAlignment: TabAlignment.start, // Align tabs to start
                      tabs: [
                        Tab(
                          text: 'settings_screen.general'.tr(),
                          icon: Icon(Icons.settings),
                        ),
                        Tab(
                          text: 'settings_screen.display'.tr(),
                          icon: Icon(Icons.palette),
                        ),
                        Tab(
                          text: 'settings_screen.local'.tr(),
                          icon: Icon(Icons.folder),
                        ),
                        Tab(
                          text: 'settings_screen.server'.tr(),
                          icon: Icon(Icons.cloud),
                        ),
                        Tab(
                          text: 'settings_screen.security'.tr(),
                          icon: Icon(Icons.security),
                        ),
                        Tab(
                          text: 'settings_screen.about'.tr(),
                          icon: Icon(Icons.info),
                        ),
                        Tab(
                          text: 'settings_screen.legal'.tr(),
                          icon: Icon(Icons.gavel),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            GeneralTab(
              durationController: _durationController,
              titleTemplateController: _titleTemplateController,
            ),
            const DisplayTab(),
            LocalTab(
              currentStoragePath: _currentStoragePath,
              isLoadingPath: _isLoadingPath,
              onChooseStorageDirectory: _chooseStorageDirectory,
              onResetToDefaultPath: _resetToDefaultPath,
            ),
            ServerTab(
              urlController: _urlController,
              usernameController: _usernameController,
              passwordController: _passwordController,
              calendarNameController: _calendarNameController,
              onServerSetupSave: _navigationManager.handleServerSetupSave,
            ),
            const SecurityTab(),
            const AboutTab(),
            const LegalTab(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navigationManager.dispose();
    _tabController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _calendarNameController.dispose();
    _durationController.dispose();
    _titleTemplateController.dispose();
    super.dispose();
  }
}
