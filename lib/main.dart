import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'screens/initialization_screen.dart';
import 'services/initialization_manager.dart';
import 'services/logger_service.dart';
import 'providers/diary_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/theme_controller.dart';

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

  // Initialize logger with user's preferred log level (or OFF by default)
  final logLevel = settingsProvider.logLevel;
  await logger.initialize(logLevel);
  logger.info('=== App Starting ===');

  // Create and initialize diary provider
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

class DiaryApp extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final DiaryProvider diaryProvider;

  const DiaryApp({
    Key? key,
    required this.settingsProvider,
    required this.diaryProvider,
  }) : super(key: key);

  @override
  State<DiaryApp> createState() => _DiaryAppState();
}

class _DiaryAppState extends State<DiaryApp> {
  bool _isInitializing = true;
  String _initMessage = 'Initializing...';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performInitialization();
  }

  Future<void> _performInitialization() async {
    // Record start time to ensure minimum display time
    final startTime = DateTime.now();
    const minDisplayDuration = Duration(seconds: 2);

    try {
      // Check storage
      setState(() => _initMessage = 'Checking storage...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Load entries from local storage
      setState(() => _initMessage = 'Loading entries...');
      await widget.diaryProvider.loadEntriesFromStorage();
      await Future.delayed(const Duration(milliseconds: 500));

      // Check server (CalDAV sync will happen in InitializationManager)
      setState(() => _initMessage = 'Checking server...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Calculate remaining time to meet minimum display duration
      final elapsed = DateTime.now().difference(startTime);
      final remaining = minDisplayDuration - elapsed;

      if (remaining > Duration.zero) {
        setState(() => _initMessage = 'Ready!');
        await Future.delayed(remaining);
      }

      // Initialization complete - InitializationManager will handle setup dialogs
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      // Handle initialization errors
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _isInitializing = true;
      _hasError = false;
      _errorMessage = null;
      _initMessage = 'Initializing...';
    });
    _performInitialization();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settingsProvider),
        ChangeNotifierProvider.value(value: widget.diaryProvider),
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
          supportedLocales: const [Locale('en')],
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
                shadowColor:
                    themeController.scheme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
              ),
            ),

            // Light shadows in dark mode for outlined buttons
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                shadowColor:
                    themeController.scheme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          home: _isInitializing
              ? InitializationScreen(
                  message: _initMessage,
                  showError: _hasError,
                  errorMessage: _errorMessage,
                  onRetry: _hasError ? _retry : null,
                )
              : InitializationWrapper(
                  settingsProvider: widget.settingsProvider,
                  diaryProvider: widget.diaryProvider,
                ),
        ),
      ),
    );
  }
}

// Wrapper that runs InitializationManager then shows HomeScreen
class InitializationWrapper extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final DiaryProvider diaryProvider;

  const InitializationWrapper({
    Key? key,
    required this.settingsProvider,
    required this.diaryProvider,
  }) : super(key: key);

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSetup();
    });
  }

  Future<void> _runSetup() async {
    final manager = InitializationManager(
      context: context,
      settingsProvider: widget.settingsProvider,
      diaryProvider: widget.diaryProvider,
    );

    await manager.performSetup();
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
