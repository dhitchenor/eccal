import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_localizations.dart';
import '../../utils/time_helper.dart';

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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),

        // Timezone Section
        Row(
          children: [
            Text(
              'general_settings.timezone'.tr(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Autocomplete<String>(
                initialValue: TextEditingValue(text: settings.timezone),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    // Show all including headers when empty
                    return commonTimezones;
                  }
                  // Filter but keep category headers for context
                  final filtered = <String>[];
                  String? lastHeader;

                  for (final tz in commonTimezones) {
                    if (tz.startsWith('---')) {
                      lastHeader = tz;
                    } else if (tz.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    )) {
                      // Add header before first match in category
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
                  // Only accept non-header selections
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
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          hintText: 'general_settings.type_search'.tr(),
                          suffixIcon: Icon(Icons.search),
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
                              // Render as centered, non-clickable header
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

                            // Render as clickable option
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
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
        const SizedBox(height: 32),

        // Default Entry Duration Section - Compact with inline input
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'general_settings.entry.default_duration'.tr(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    'general_settings.entry.duration'.tr(),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: durationController,
                decoration: InputDecoration(
                  suffix: Text('min'.tr()),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final minutes = int.tryParse(value);
                  if (minutes != null && minutes >= 1) {
                    settings.setEventDuration(minutes);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Default Entry Title Section
        Text(
          'general_settings.entry.default_title'.tr(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: titleTemplateController,
          decoration: InputDecoration(
            labelText: 'general_settings.entry.title_template'.tr(),
            hintText: 'general_settings.entry.default_text'.tr(),
            border: OutlineInputBorder(),
            helperText: 'general_settings.entry.title_helper'.tr(),
          ),
          onChanged: (value) {
            settings.setDefaultEntryTitle(value);
          },
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'general_settings.entry.placeholders'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• ${'general_settings.entry.weekday'.tr()}\n'
                  '• ${'general_settings.entry.wkd'.tr()}\n'
                  '• ${'general_settings.entry.dd'.tr()}\n'
                  '• ${'general_settings.entry.month'.tr()}\n'
                  '• ${'general_settings.entry.mmm'.tr()}\n'
                  '• ${'general_settings.entry.mm'.tr()}\n'
                  '• ${'general_settings.entry.yyyy'.tr()}\n',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  'general_settings.entry.title_example'.tr(),
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
