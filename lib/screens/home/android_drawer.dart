import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../models/diary_entry.dart';
import '../../providers/diary_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/settings_screen.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/entry_sidebar_widget.dart';

class AndroidDrawer extends StatelessWidget {
  final String? selectedMoodFilter;
  final List<String> selectedLocationFilters;
  final DiaryEntry? selectedEntry;
  final Function(DiaryEntry) onEntrySelected;
  final Function(String?) onMoodFilterChanged;
  final Function(List<String>) onLocationFiltersChanged;
  final Function(String) onDelete;
  final Function(String) onAppend;

  const AndroidDrawer({
    Key? key,
    required this.selectedMoodFilter,
    required this.selectedLocationFilters,
    required this.selectedEntry,
    required this.onEntrySelected,
    required this.onMoodFilterChanged,
    required this.onLocationFiltersChanged,
    required this.onDelete,
    required this.onAppend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final settings = context.watch<SettingsProvider>();
    final entries = provider.entries;

    return Drawer(
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  AppConfig.appName,
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
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
            ),
          ),
          Expanded(
            child: EntriesSidebarWidget(
              entries: entries,
              allEntries: provider.entries,
              selectedMoodFilter: selectedMoodFilter,
              selectedLocationFilters: selectedLocationFilters,
              selectedEntry: selectedEntry,
              use24HourFormat: settings.use24HourFormat,
              onEntrySelected: (entry) {
                Navigator.pop(context);
                onEntrySelected(entry);
              },
              onEntryTap: (entry) {
                Navigator.pop(context);
                onEntrySelected(entry);
              },
              onMoodFilterChanged: onMoodFilterChanged,
              onLocationFiltersChanged: onLocationFiltersChanged,
              onDelete: onDelete,
              onAppend: (entryId) {
                onAppend(entryId);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}