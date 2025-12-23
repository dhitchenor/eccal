import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/themes.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_localizations.dart';
import '../../utils/error_snackbar.dart';
import '../../utils/theme_controller.dart';
import 'settings_components.dart';

class DisplayTab extends StatelessWidget {
  const DisplayTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeController = context.watch<ThemeController>();

    return ResponsiveSettingsLayout(
      children: [
        SettingsSpacing.item(),

        // Theme Section
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            if (isMobile) {
              // Mobile: Dropdown beside title, switch below
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color family dropdown beside title
                  SettingsDropdownRow<AppColorFamily>(
                    title: 'display_settings.theme'.tr(),
                    value: themeController.family,
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

                  SettingsSpacing.micro(),

                  // Dark mode switch
                  Row(
                    children: [
                      Switch(
                        value: themeController.isDark,
                        onChanged: (value) {
                          context.read<ThemeController>().toggleDark(value);
                        },
                      ),
                      SettingsSpacing.horizontalTight(),
                      Text(
                        'display_settings.dark_mode'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Desktop
              return SettingsTitleWithAction<AppColorFamily>(
                title: 'display_settings.theme'.tr(),
                switchValue: themeController.isDark,
                onSwitchChanged: (value) {
                  context.read<ThemeController>().toggleDark(value);
                },
                switchLabel: 'display_settings.dark_mode'.tr(),
                dropdownLabel: '',
                dropdownValue: themeController.family,
                dropdownItems: AppColorFamily.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.name.toUpperCase()),
                  );
                }).toList(),
                onDropdownChanged: (value) {
                  if (value != null) {
                    context.read<ThemeController>().setFamily(value);
                  }
                },
              );
            }
          },
        ),

        SettingsSpacing.section(),

        // Time Format Section
        SettingsDropdownRow<bool>(
          title: 'display_settings.time_format'.tr(),
          value: settings.use24HourFormat,
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

        SettingsSpacing.section(),

        // Language Section
        SettingsDropdownRow<String>(
          title: 'display_settings.language'.tr(),
          value: settings.language,
          items: AppLanguages.codes.map((code) {
            return DropdownMenuItem(
              value: code,
              child: Text(AppLanguages.getName(code)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              settings.setLanguage(value);
              ErrorSnackbar.showInfo(
                context,
                'display_settings.language_changed'.tr(),
                duration: const Duration(seconds: 4),
              );
            }
          },
        ),

        SettingsSpacing.section(),

        // Append Header Settings Section
        SettingsTitleWithHelper(
          title: 'display_settings.append_headers'.tr(),
          helperText: 'display_settings.append_headers_description'.tr(),
        ),
        SettingsSpacing.item(),

        // Indented switches for append options
        IndentedContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show Mood in Append Headers
              SettingsSwitchRow(
                title: 'display_settings.show_append_mood'.tr(),
                description: 'display_settings.show_append_mood_description'
                    .tr(),
                value: settings.showAppendMoodInHeaders,
                onChanged: (value) {
                  settings.setShowAppendMoodInHeaders(value);
                },
                isSubtitle: true,
              ),

              SettingsSpacing.tight(),

              // Show Location in Append Headers
              SettingsSwitchRow(
                title: 'display_settings.show_append_location'.tr(),
                description: 'display_settings.show_append_location_description'
                    .tr(),
                value: settings.showAppendLocationInHeaders,
                onChanged: (value) {
                  settings.setShowAppendLocationInHeaders(value);
                },
                isSubtitle: true,
              ),
            ],
          ),
        ),

        SettingsSpacing.item(),

        // Example card showing what append headers look like
        SettingsInfoBox(
          title: 'display_settings.example_header'.tr(),
          content:
              '───── ${'home_screen.added_on'.tr()}: 27 Jun 2025, 1:00 PM ─────\n'
              '${settings.showAppendMoodInHeaders ? '${'mood'.tr()}: 😊 ${'mood.happy'.tr()}\n' : ''}'
              '${settings.showAppendLocationInHeaders ? '${'location'.tr()}: ${'display_settings.coffee_shop'.tr()}' : ''}',
        ),
      ],
    );
  }
}
