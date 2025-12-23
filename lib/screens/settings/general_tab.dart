import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_localizations.dart';
import '../../utils/time_helper.dart';
import 'settings_components.dart';

class GeneralTab extends StatelessWidget {
  final TextEditingController durationController;
  final TextEditingController titleTemplateController;

  const GeneralTab({
    Key? key,
    required this.durationController,
    required this.titleTemplateController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final rightPadding = screenWidth < 1000 ? 40.0 : 80.0;

    return ResponsiveSettingsLayout(
      children: [
        SettingsSpacing.item(),

        // Timezone Section
        Padding(
          padding: EdgeInsets.only(right: rightPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionTitle(text: 'timezone'.tr()),
              const Spacer(),
              Expanded(
                flex: 2,
                child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: settings.timezone),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return commonTimezones;
                    }
                    final filtered = <String>[];
                    String? lastHeader;

                    for (final tz in commonTimezones) {
                      if (tz.startsWith('---')) {
                        lastHeader = tz;
                      } else if (tz.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      )) {
                        if (lastHeader != null &&
                            !filtered.contains(lastHeader)) {
                          filtered.add(lastHeader);
                        }
                        filtered.add(tz);
                      }
                    }
                    return filtered;
                  },
                  onSelected: (String selection) {
                    if (!selection.startsWith('---')) {
                      settings.setTimezone(selection);
                    }
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            hintText: 'general_settings.type_search'.tr(),
                            suffixIcon: const Icon(Icons.search),
                          ),
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 300,
                            maxWidth: 350,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              final isHeader = option.startsWith('---');

                              if (isHeader) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: Text(
                                    option.replaceAll('---', '').trim(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              }

                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    option,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        SettingsSpacing.section(),

        // Default Entry Duration Section
        SettingsTextFieldRow(
          title: 'general_settings.entry.default_duration'.tr(),
          helperText: 'general_settings.entry.duration'.tr(),
          controller: durationController,
          suffix: 'min'.tr(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final minutes = int.tryParse(value);
            if (minutes != null && minutes >= 1) {
              settings.setEventDuration(minutes);
            }
          },
        ),

        SettingsSpacing.section(),

        // Default Entry Title Section
        SettingsTextFieldRow(
          title: 'general_settings.entry.default_title'.tr(),
          helperText: 'general_settings.entry.title_helper'.tr(),
          controller: titleTemplateController,
          labelText: 'general_settings.entry.title_template'.tr(),
          hintText: 'general_settings.entry.default_text'.tr(),
          onChanged: (value) => settings.setDefaultEntryTitle(value),
        ),

        SettingsSpacing.item(),

        // Placeholders info box
        SettingsInfoBox(
          title: 'general_settings.entry.placeholders'.tr(),
          content:
              '• {WEEKDAY} - ${'general_settings.entry.weekday'.tr()}\n'
              '• {WKD} - ${'general_settings.entry.wkd'.tr()}\n'
              '• {DD} - ${'general_settings.entry.dd'.tr()}\n'
              '• {MONTH} - ${'general_settings.entry.month'.tr()}\n'
              '• {MMM} - ${'general_settings.entry.mmm'.tr()}\n'
              '• {MM} - ${'general_settings.entry.mm'.tr()}\n'
              '• {YYYY} - ${'general_settings.entry.yyyy'.tr()}\n'
              '\n'
              '${'general_settings.entry.title_example'.tr()}',
        ),
      ],
    );
  }
}
