import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings/general_tab.dart';
import 'settings/display_tab.dart';
import 'settings/local_tab.dart';
import 'settings/server_tab.dart';
import 'settings/about_tab.dart';
import 'settings/legal_tab.dart';
import '../constants/themes.dart';
import '../constants/third_party_licenses.dart';
import '../providers/settings_provider.dart';
import '../providers/diary_provider.dart';
import '../services/caldav_service.dart';
import '../services/export_service.dart';
import '../services/logger_service.dart';
import '../utils/app_localizations.dart';
import '../utils/theme_controller.dart';
import '../utils/time_helper.dart';

class SettingsScreen extends StatefulWidget {
  final int initialTabIndex;
  const SettingsScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _calendarNameController;
  late TextEditingController _durationController;
  late TextEditingController _titleTemplateController;
  late TabController _tabController;
  String? _currentStoragePath;
  bool _isLoadingPath = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: widget.initialTabIndex);
    final settings = context.read<SettingsProvider>();
    _urlController = TextEditingController(text: settings.caldavUrl ?? '');
    _usernameController = TextEditingController(text: settings.caldavUsername ?? '');
    _passwordController = TextEditingController(text: settings.caldavPassword ?? '');
    _calendarNameController = TextEditingController(text: settings.caldavCalendarName ?? '');
    _titleTemplateController = TextEditingController(text: settings.defaultEntryTitle);
    _durationController = TextEditingController(
      text: settings.eventDurationMinutes.toString(),
    );
    _loadCurrentPath();
  }

  Future<void> _loadCurrentPath() async {
    final diaryProvider = context.read<DiaryProvider>();
    final path = await diaryProvider.getStoragePath();
    setState(() {
      _currentStoragePath = path;
      _isLoadingPath = false;
    });
  }

  Future<void> _chooseStorageDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null) {
      final diaryProvider = context.read<DiaryProvider>();
      
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('local_settings.change_storage_question'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('local_settings.moveentries_to'.tr()),
              const SizedBox(height: 8),
              Text(
                selectedDirectory,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'local_settings.oldentries_remain'.tr(),
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('local_sttings.move_entries'.tr()),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Show loading indicator
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          final success = await diaryProvider.moveEntriesToNewLocation(selectedDirectory);
          
          if (!mounted) return;
          Navigator.pop(context);

          if (success) {
            await _loadCurrentPath();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('local_settings.storagemove_success'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('local_settings.storagemove_failed'.tr()),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error'.tr([e.toString()])),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _resetToDefaultPath() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('local_settings.reset_storagelocation_question'.tr()),
        content: Text(
          'local_settings.moveto_defaultfolder'.tr(),
        ),
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
      final diaryProvider = context.read<DiaryProvider>();
      
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await diaryProvider.resetToDefaultPath();
        
        if (!mounted) return;
        Navigator.pop(context);
        await _loadCurrentPath();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('local_settings.reset_storagelocation'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error'.tr([e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: 'settings_screen.general'.tr(), icon: Icon(Icons.settings)),
                    Tab(text: 'settings_screen.display'.tr(), icon: Icon(Icons.palette)),
                    Tab(text: 'settings_screen.local'.tr(), icon: Icon(Icons.folder)),
                    Tab(text: 'settings_screen.server'.tr(), icon: Icon(Icons.cloud)),
                    Tab(text: 'settings_screen.about'.tr(), icon: Icon(Icons.info)),
                    Tab(text: 'settings_screen.legal'.tr(), icon: Icon(Icons.gavel)),
                  ],
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
          ),
          const AboutTab(),
          const LegalTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
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