import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'providers/diary_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/theme_controller.dart';
import 'constants/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set window size for desktop platforms only
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();
    
    // Set initial size
    await windowManager.setSize(const Size(1200, 790));
    
    // Center the window on screen
    await windowManager.center();
  }
  
  // Create and initialize providers BEFORE runApp
  // This prevents release mode crashes from async constructor calls
  final settingsProvider = SettingsProvider();
  await settingsProvider.initialize(); // Wait for settings to load
  
  final diaryProvider = DiaryProvider();
  diaryProvider.setSettingsProvider(settingsProvider);
  await diaryProvider.initialize(); // Wait for entries to load
  
  // Initialize theme controller and load saved theme
  final themeController = ThemeController();
  await themeController.initialize(); // Load saved theme preferences
  
  runApp(
    ChangeNotifierProvider.value(
      value: themeController,
      child: DiaryApp(
        settingsProvider: settingsProvider,
        diaryProvider: diaryProvider,
      ),
    ),
  );
}

class DiaryApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  final DiaryProvider diaryProvider;
  
  const DiaryApp({
    Key? key,
    required this.settingsProvider,
    required this.diaryProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: diaryProvider),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) => MaterialApp(
          title: AppConfig.appName,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
          ],
          locale: const Locale('en'),
          theme: ThemeData(
            colorScheme: themeController.scheme,
            useMaterial3: true,
            tabBarTheme: TabBarThemeData(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return Colors.grey.withOpacity(0.1);
                }
                return null;
              }),
            ),
            // Light shadows in dark mode for elevated buttons
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shadowColor: themeController.scheme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
              ),
            ),
            
            // Light shadows in dark mode for outlined buttons
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                shadowColor: themeController.scheme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}