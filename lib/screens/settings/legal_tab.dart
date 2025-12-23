import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../constants/third_party_licenses.dart';
import '../../services/logger_service.dart';
import '../../utils/app_localizations.dart';
import 'settings_components.dart';

class LegalTab extends StatefulWidget {
  const LegalTab({Key? key}) : super(key: key);

  @override
  State<LegalTab> createState() => _LegalTabState();
}

class _LegalTabState extends State<LegalTab> {
  late Future<Map<String, dynamic>> _legalDataFuture;

  @override
  void initState() {
    super.initState();
    // Cache the legal data future so it only loads once
    _legalDataFuture = _loadLegalData();
  }

  Future<Map<String, dynamic>> _loadLegalData() async {
    final result = <String, dynamic>{};

    // Load LICENSE file
    try {
      result['license'] = await rootBundle.loadString('LICENSE');
    } catch (e) {
      logger.info('LICENSE file not found: $e');
    }

    // Load files from legal/ directory
    final legalFiles = <String, String>{};
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final filesList = manifestMap.keys
          .where((key) => key.startsWith('legal/') && (key.endsWith('.txt') || key.endsWith('.md')))
          .toList()
          ..sort(); // Sort alphabetically

      for (final filePath in filesList) {
        try {
          final content = await rootBundle.loadString(filePath);
          final fileName = filePath.split('/').last;
          legalFiles[fileName] = content;
        } catch (e) {
          logger.error('Error loading $filePath: $e');
        }
      }
    } catch (e) {
      // AssetManifest.json not found - this is normal if no legal files are bundled
      // Silently continue with empty legal files
    }

    result['legalFiles'] = legalFiles;
    return result;
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: show URL in dialog if can't launch
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('legal_settings.cannot_open_link'.tr()),
            content: SelectableText(
              url,
              style: const TextStyle(color: Colors.blue),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('close'.tr()),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Error launching URL, show in dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('legal_settings.error_opening_link'.tr()),
          content: SelectableText(
            '${'legal_settings.could_not_open'.tr([url.toString()])}\n\n${'error_'.tr([e.toString()])}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('close'.tr()),
            ),
          ],
        ),
      );
    }
  }

  void _showDocumentModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'close'.tr(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  content,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _legalDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final licenseContent = snapshot.data?['license'] as String?;
        final legalFiles = snapshot.data?['legalFiles'] as Map<String, String>? ?? {};

        return ResponsiveSettingsLayout(
          children: [
            SettingsSpacing.item(),

            // EcCal LICENSE section
            if (licenseContent != null) ...[
              SettingsSectionTitle(
                text: 'legal_settings.license_'.tr([AppConfig.appName]),
              ),
              SettingsSpacing.item(),
              Card(
                child: ListTile(
                  title: Text(
                    'license'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('legal_settings.gpl_v3'.tr()),
                  trailing: ElevatedButton(
                    onPressed: () => _showDocumentModal(context, 'license'.tr(), licenseContent),
                    child: Text('view'.tr()),
                  ),
                ),
              ),
              SettingsSpacing.section(),
            ],

            // Legal folder files (if any)
            if (legalFiles.isNotEmpty) ...[
              SettingsSectionTitle(
                text: 'legal_settings.legal_documents'.tr(),
              ),
              SettingsSpacing.item(),
              ...legalFiles.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _showDocumentModal(context, entry.key, entry.value),
                      child: Text('view'.tr()),
                    ),
                  ),
                );
              }),
              SettingsSpacing.section(),
            ],

            // Third-party licenses section
            SettingsSectionTitle(
              text: 'legal_settings.third_party_licenses'.tr(),
            ),
            SettingsSpacing.item(),

            // List all third-party licenses
            ...thirdPartyLicenses.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    item['title']!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item['website'] != null && item['website']!.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _openUrl(item['website']!),
                          icon: const Icon(Icons.language, size: 16),
                          label: Text('website'.tr()),
                        ),
                      const SizedBox(width: 8),
                      if (item['license'] != null && item['license']!.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _openUrl(item['license']!),
                          icon: const Icon(Icons.description, size: 16),
                          label: Text('license'.tr()),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
