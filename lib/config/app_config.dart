class AppConfig {
  // App environment variables
  static const String appName = 'EcCal';
  static const String appVersion = '1.0.0-rc1';
  
  static const int maxTitleLength = 100;
}

class BuildConfig {
  // Build environment versions
  static const String dartVersion = '3.9.2';
  static const String flutterVersion = '3.38.0';
  
  // Dependencies - Map format for easy parsing
  // Key = package name (must match pubspec.yaml)
  // Value = version
  static const Map<String, String> dependencies = {
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
  };
  
  static const Map<String, String> devDependencies = {
    'flutter_lints': '6.0.0',
    'flutter_launcher_icons': '0.14.4',
  };
}