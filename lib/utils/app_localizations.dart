import 'dart:convert';
import 'package:flutter/services.dart';

// Simple localization service
class AppLocalizations {
  final String languageCode;
  Map<String, dynamic> _localizedStrings = {};

  AppLocalizations(this.languageCode);

  static AppLocalizations? of(context) {
    // This will be set up later with InheritedWidget
    return _instance;
  }

  static AppLocalizations? _instance;

  // Load translations from JSON file
  static Future<AppLocalizations> load(String languageCode) async {
    final localizations = AppLocalizations(languageCode);
    
    try {
      final jsonString = await rootBundle.loadString('assets/i18n/$languageCode.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      localizations._localizedStrings = jsonMap;
    } catch (e) {
      // Fallback to English if language file not found
      final jsonString = await rootBundle.loadString('assets/i18n/en.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      localizations._localizedStrings = jsonMap;
    }
    
    _instance = localizations;
    return localizations;
  }

  // Get translated string by key
  String translate(String key, [List<String>? args]) {
    String? value = _getNestedValue(key);
    
    if (value == null) {
      return key; // Return key if translation not found
    }
    
    // Replace placeholders {0}, {1}, etc. with arguments
    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        value = value!.replaceAll('{$i}', args[i]);
      }
    }
    
    return value!;
  }

  // Get nested value from dot notation (e.g., "moods.happy")
  String? _getNestedValue(String key) {
    final keys = key.split('.');
    dynamic value = _localizedStrings;
    
    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return null;
      }
    }
    
    return value is String ? value : null;
  }
}

// Extension for easy access
extension LocalizationExtension on String {
  String tr([List<String>? args]) {
    return AppLocalizations._instance?.translate(this, args) ?? this;
  }
}

// Available languages
class AppLanguages {
  static const Map<String, String> languages = {
    // Ensure languages are listed here!
    //'ar': 'العربية',
    //'de': 'Deutsch',
    'en': 'English',
    //'es': 'Español',
    //'fr': 'Français',
    //'hi': 'हिन्दी',
    //'it': 'Italiano',
    //'ja': '日本語',
    //'pt': 'Português',
    //'ru': 'Русский',
    //'zh': '中文',
  };

  static List<String> get codes => languages.keys.toList();
  static List<String> get names => languages.values.toList();
  
  static String getName(String code) => languages[code] ?? code;
}