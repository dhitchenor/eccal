import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../services/logger_service.dart';
import '../../utils/app_localizations.dart';
import 'settings_components.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({Key? key}) : super(key: key);

  Future<String> _loadReadme() async {
    try {
      return await rootBundle.loadString('README.md');
    } catch (e) {
      logger.error('Error loading README.md: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadReadme(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: getResponsivePadding(context),
              child: Text(
                'about_settings.error_loading_readme'.tr([
                  snapshot.error.toString(),
                ]),
              ),
            ),
          );
        }

        final content = snapshot.data ?? 'about_settings.readme_not_found'.tr();

        return Padding(
          padding: getResponsivePadding(context),
          child: Column(
            children: [
              SettingsSpacing.item(),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Markdown(
                    data: content,
                    selectable: true,
                    shrinkWrap: false,
                    styleSheet:
                        MarkdownStyleSheet.fromTheme(
                          Theme.of(context).copyWith(
                            textTheme: Theme.of(context).textTheme.apply(
                              bodyColor: Colors.black,
                              displayColor: Colors.black,
                            ),
                          ),
                        ).copyWith(
                          // Code block styling (multi-line code)
                          codeblockDecoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          codeblockPadding: const EdgeInsets.all(12),
                          // Inline code styling (single backticks)
                          code: TextStyle(
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.black87,
                            fontFamily: 'monospace',
                          ),
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
}
