import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/themes.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_localizations.dart';
import '../../utils/error_snackbar.dart';
import '../../utils/theme_controller.dart';

class DisplayTab extends StatelessWidget {
  const DisplayTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),

        // Theme Section - Compact with dropdown
        Row(
          children: [
            Text(
              'display_settings.theme'.tr(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),

            // ---- Theme COLOR Dropdown ----
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<AppColorFamily>(
                value: context.watch<ThemeController>().family,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: AppColorFamily.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    context.read<ThemeController>().setFamily(value);
                  }
                },
              ),
            ),

            const SizedBox(width: 16),

            // ---- DARK MODE Checkbox ----
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: context.watch<ThemeController>().isDark,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ThemeController>().toggleDark(value);
                    }
                  },
                ),
                Text('display_settings.dark_mode'.tr()),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Time Format Section - Compact with dropdown
        Row(
          children: [
            Text(
              'display_settings.time_format'.tr(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<bool>(
                value: settings.use24HourFormat,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(
                    value: true,
                    child: Text('display_settings.24_hour'.tr()),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text('display_settings.12_hour'.tr()),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setTimeFormat(value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Language Section
        Row(
          children: [
            Text(
              'display_settings.language'.tr(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: settings.language,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: AppLanguages.codes.map((code) {
                  return DropdownMenuItem(
                    value: code,
                    child: Text(AppLanguages.getName(code)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    settings.setLanguage(value);

                    // Show restart notice
                    ErrorSnackbar.showInfo(
                      context,
                      'display_settings.language_changed'.tr(),
                      duration: Duration(seconds: 4),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Append Header Settings Section
        Text(
          'display_settings.append_headers'.tr(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'display_settings.append_headers_description'.tr(),
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Show Mood in Append Headers
        CheckboxListTile(
          title: Text('display_settings.show_append_mood'.tr()),
          subtitle: Text('display_settings.show_append_mood_description'.tr()),
          value: settings.showAppendMoodInHeaders,
          onChanged: (value) {
            if (value != null) {
              settings.setShowAppendMoodInHeaders(value);
            }
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),

        const SizedBox(height: 8),

        // Show Location in Append Headers
        CheckboxListTile(
          title: Text('display_settings.show_append_location'.tr()),
          subtitle: Text('display_settings.show_append_location_description'.tr()),
          value: settings.showAppendLocationInHeaders,
          onChanged: (value) {
            if (value != null) {
              settings.setShowAppendLocationInHeaders(value);
            }
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),

        const SizedBox(height: 16),

        // Example card showing what append headers look like
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'display_settings.example_header'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '───── ${'home_screen.added_on'.tr()}: 27 Jun 2025, 1:00 PM ─────',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                if (settings.showAppendMoodInHeaders) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${'mood'.tr()}: 😊 ${'mood.happy'.tr()}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
                if (settings.showAppendLocationInHeaders) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${'location'.tr()}: ${'display_settings.coffee_shop'.tr()}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
