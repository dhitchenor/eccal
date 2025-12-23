class AppConfig {
  // App environment variables
  static const String appName = 'EcCal';
  static const String appVersion = '1.0.0-rc1';

  static const int maxTitleLength = 100;

  static const String googleCalendarClientID_Android =
      '188241739306-8c74iaqcu1q96bcb0oc7qqirp5ig55mo.apps.googleusercontent.com';
  static const String googleCalendarClientID_iOS =
      '188241739306-1l015fgn5031s1q09knhbca2218lsijg.apps.googleusercontent.com';
  static const String googleCalendarClientID_Desktop =
      '188241739306-hico00lmk2gortrnd4agqo092puemmgp.apps.googleusercontent.com';
  static const String googleCalendarClientSecret_Desktop =
      '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';
}

class BuildConfig {
  // Build environment versions
  static const String dartVersion = '3.10.4';
  static const String flutterVersion = '3.38.5';

  // Dependencies - Map format for easy parsing
  // Key = package name (must match pubspec.yaml)
  // Value = version
  static const Map<String, String> dependencies = {
    'path': '1.9.1',
    'provider': '6.1.1',
    'permission_handler': '12.0.1',
    'shared_preferences': '2.5.3',
    'window_manager': '0.5.1',
    'file_picker': '10.3.7',
    'path_provider': '2.1.5',
    'geolocator': '14.0.2',
    'archive': '4.0.7',
    'http': '1.1.2',
    'url_launcher': '6.3.2',
    'sqflite': '2.3.0',
    'intl': '0.20.2',
    'flutter_quill': '11.5.0',
    'flutter_markdown_plus': '1.0.5',
    'cupertino_icons': '1.0.8',
  };

  static const Map<String, String> devDependencies = {
    'flutter_lints': '6.0.0',
    'flutter_launcher_icons': '0.14.4',
  };
}
