import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'screens/initialization_screen.dart';
import 'services/caldav_service.dart';
import 'services/file_storage_service.dart';
import 'services/initialization_manager.dart';
import 'services/logger_service.dart';
import 'providers/diary_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/theme_controller.dart';
import 'utils/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Window setup
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 790),
      minimumSize: Size(900, 600), // Minimum window size
      center: true,
      title: AppConfig.appName,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Create providers (not initialized yet)
  final settingsProvider = SettingsProvider();
  final diaryProvider = DiaryProvider();
  final themeController = ThemeController();

  // Show screen IMMEDIATELY
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: diaryProvider),
      ],
      child: DiaryApp(
        settingsProvider: settingsProvider,
        diaryProvider: diaryProvider,
        themeController: themeController,
      ),
    ),
  );
}

class DiaryApp extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final DiaryProvider diaryProvider;
  final ThemeController themeController;

  const DiaryApp({
    Key? key,
    required this.settingsProvider,
    required this.diaryProvider,
    required this.themeController,
  }) : super(key: key);

  @override
  State<DiaryApp> createState() => _DiaryAppState();
}

class _DiaryAppState extends State<DiaryApp> {
  bool _isInitialized = false;
  String _initMessage = '';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Start initialization AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performFullInitialization();
    });
  }

  /// Helper to show a step for at least 500ms
  Future<T> _timedStep<T>(String message, Future<T> Function() action) async {
    setState(() => _initMessage = message);

    final startTime = DateTime.now();
    final result = await action();

    // Ensure step is visible for at least 500ms
    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(milliseconds: 500) - elapsed;

    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    return result;
  }

  Future<void> _performFullInitialization() async {
    try {
      // Step 1: Initialize logger
      // await logger.initialize(LogLevel.none);
      await logger.initialize(LogLevel.debug);

      // Step 2: Load settings and translations
      await widget.settingsProvider.initialize();
      await AppLocalizations.load(widget.settingsProvider.language);

      // Step 3: Load theme
      await _timedStep('setup.loading_theme'.tr(), () async {
        await widget.themeController.initialize();
      });

      // Step 4: Connect providers
      await _timedStep('setup.connecting_services'.tr(), () async {
        widget.diaryProvider.setSettingsProvider(widget.settingsProvider);
      });

      // Step 5: Check and configure calendar provider
      final provider = widget.settingsProvider.calendarProvider;
      bool isProviderAuthenticated = false;

      await _timedStep('setup.checking_provider'.tr(), () async {
        logger.info('Provider type: $provider');

        if (provider == CalendarProvider.caldav) {
          // Get password from secure storage first
          String? password;
          try {
            password = await widget.settingsProvider.caldavPassword;
          } catch (e) {
            logger.error('Failed to retrieve CalDAV password: $e');
            password = null;
          }

          // Check if CalDAV is fully configured
          isProviderAuthenticated =
              widget.settingsProvider.caldavUrl != null &&
              widget.settingsProvider.caldavUrl!.isNotEmpty &&
              widget.settingsProvider.caldavUsername != null &&
              widget.settingsProvider.caldavUsername!.isNotEmpty &&
              password != null &&
              password.isNotEmpty &&
              widget.settingsProvider.caldavCalendarName != null &&
              widget.settingsProvider.caldavCalendarName!.isNotEmpty;

          if (isProviderAuthenticated) {
            widget.diaryProvider.configureCalDAV(
              url: widget.settingsProvider.caldavUrl!,
              username: widget.settingsProvider.caldavUsername!,
              password: password!,
              calendarName: widget.settingsProvider.caldavCalendarName!,
              eventDurationMinutes:
                  widget.settingsProvider.eventDurationMinutes,
            );
            logger.info('CalDAV configured and authenticated');

            // Preload calendar list for fast server tab loading
            try {
              final caldavService = CalDAVService(
                url: widget.settingsProvider.caldavUrl!,
                username: widget.settingsProvider.caldavUsername!,
                password: password,
              );
              final calendars = await caldavService.listCalendars();
              if (calendars.isNotEmpty) {
                await widget.settingsProvider.setCachedCalendarList(calendars);
                logger.info('Preloaded ${calendars.length} CalDAV calendars');
              }
            } catch (e) {
              logger.error('Failed to preload CalDAV calendars: $e');
              // Non-critical error - continue initialization
            }
          } else {
            logger.info('CalDAV not configured - skipping sync');
          }
        } else if (provider == CalendarProvider.google) {
          // Check if Google Calendar is configured (has calendar ID and email)
          isProviderAuthenticated =
              widget.settingsProvider.googleCalendarId != null &&
              widget.settingsProvider.googleCalendarId!.isNotEmpty &&
              widget.settingsProvider.googleUserEmail != null &&
              widget.settingsProvider.googleUserEmail!.isNotEmpty;

          if (isProviderAuthenticated) {
            // Initialize Google Calendar service HERE (only when using Google)
            await widget.diaryProvider.initializeGoogleCalendar();
            logger.info('Google Calendar configured');

            // Preload calendar list for fast server tab loading
            try {
              final calendars = await widget.diaryProvider.googleCalendarService
                  .listCalendars();
              if (calendars.isNotEmpty) {
                await widget.settingsProvider.setCachedCalendarList(calendars);
                logger.info('Preloaded ${calendars.length} Google calendars');
              }
            } catch (e) {
              logger.error('Failed to preload Google calendars: $e');
              // Non-critical error - continue initialization
            }
          } else {
            logger.info('Google Calendar not configured');
          }
        }
      });

      // Step 6: Check storage path
      await _timedStep('setup.checking_storage'.tr(), () async {
        final fileStorage = FileStorageService();
        await fileStorage.initialize();
      });

      // Step 7: Load entries from storage
      await _timedStep('setup.loading_local_entries'.tr(), () async {
        await widget.diaryProvider.initialize();
        logger.info('Loaded ${widget.diaryProvider.entries.length} entries');
      });

      // Step 8: Done!
      await _timedStep('ready'.tr(), () async {
        // Start background polling, then present UI
        widget.diaryProvider.startServerPolling();
        logger.info('Background polling enabled');
      });

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e, stackTrace) {
      logger.error('Initialization failed: $e');
      logger.error('Stack trace: $stackTrace');

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
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
      _initMessage = 'Retrying...';
    });
    _performFullInitialization();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settingsProvider),
        ChangeNotifierProvider.value(value: widget.diaryProvider),
      ],
      child: Consumer2<ThemeController, SettingsProvider>(
        builder: (context, themeController, settings, _) {
          final locale = Locale(settings.language);

          return MaterialApp(
            title: AppConfig.appName,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            locale: locale,
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
            home: !_isInitialized
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
          );
        },
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
      googleCalendarService: widget.diaryProvider.googleCalendarService,
    );

    await manager.setupPrompts();
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
