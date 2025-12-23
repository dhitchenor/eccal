import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/diary_provider.dart';
import '../services/google_calendar_service.dart';
import '../utils/app_localizations.dart';
import '../utils/error_snackbar.dart';
import '../widgets/build_calendar_signin.dart';
import '../widgets/caldav_server_form.dart';

// Universal calendar provider widget that handles ALL calendar providers
// (CalDAV, Google Calendar, Apple Calendar)
//
// Handles both states for each provider:
// - Not signed in: Shows appropriate sign-in UI (form/button)
// - Signed in: Shows calendar selection UI
class CalendarProviderWidget extends StatelessWidget {
  final CalendarProvider provider;
  final bool syncDisabled;

  // CalDAV-specific
  final TextEditingController? caldavUrlController;
  final TextEditingController? caldavUsernameController;
  final TextEditingController? caldavPasswordController;
  final TextEditingController? caldavCalendarNameController;

  // Google-specific
  final GoogleCalendarService? googleService;
  final bool? googleIsInitialized;

  // Apple-specific (future)
  // final AppleCalendarService? appleService;

  // Callbacks
  final VoidCallback? onSignInSuccess;
  final VoidCallback onSignOut;

  // For server setup save flow
  final Future<void> Function({
    required BuildContext context,
    required String url,
    required String username,
    required String password,
    required String calendarName,
  })?
  onServerSetupSave;

  const CalendarProviderWidget({
    Key? key,
    required this.provider,
    required this.syncDisabled,
    required this.onSignOut,
    this.caldavUrlController,
    this.caldavUsernameController,
    this.caldavPasswordController,
    this.caldavCalendarNameController,
    this.googleService,
    this.googleIsInitialized,
    this.onSignInSuccess,
    this.onServerSetupSave, // Optional
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (provider) {
      case CalendarProvider.caldav:
        return _buildCalDAV(context);
      case CalendarProvider.google:
        return _buildGoogle(context);
      case CalendarProvider.apple:
        return _buildApple(context);
    }
  }

  // CalDAV

  Widget _buildCalDAV(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // Check if signed in
    return FutureBuilder<String?>(
      future: settings.caldavPassword,
      builder: (context, passwordSnapshot) {
        // Check if we have credentials (signed in)
        final hasCredentials =
            settings.caldavUrl != null &&
            settings.caldavUrl!.isNotEmpty &&
            settings.caldavUsername != null &&
            settings.caldavUsername!.isNotEmpty &&
            passwordSnapshot.hasData &&
            passwordSnapshot.data != null &&
            passwordSnapshot.data!.isNotEmpty;

        if (!hasCredentials) {
          // NOT signed in - show login form
          assert(caldavUrlController != null, 'CalDAV requires url controller');
          assert(
            caldavUsernameController != null,
            'CalDAV requires username controller',
          );
          assert(
            caldavPasswordController != null,
            'CalDAV requires password controller',
          );
          assert(
            caldavCalendarNameController != null,
            'CalDAV requires calendar name controller',
          );

          // Clear iCloud URL if it's still there from switching from Apple
          if (caldavUrlController!.text == 'https://caldav.icloud.com' ||
              caldavUrlController!.text.contains('caldav.icloud.com')) {
            caldavUrlController!.clear();
          }

          return CalDAVServerForm(
            urlController: caldavUrlController!,
            usernameController: caldavUsernameController!,
            passwordController: caldavPasswordController!,
            calendarNameController: caldavCalendarNameController!,
            syncDisabled: syncDisabled,
            onSignInSuccess:
                onSignInSuccess, // Pass callback to trigger rebuild
            onServerSetupSave: onServerSetupSave, // Pass for server setup flow
          );
        }

        // HAS credentials - show calendar selection UI
        return CalendarSignInWidget(
          provider: CalendarProvider.caldav,
          syncDisabled: syncDisabled,
          caldavUrl: settings.caldavUrl,
          caldavUsername: settings.caldavUsername,
          caldavPassword:
              passwordSnapshot.data, // Pass the actual password value
          onSignOut: onSignOut,
          onCalendarSelected:
              onSignInSuccess, // Trigger when calendar is selected
        );
      },
    );
  }

  // Google Calendar

  Widget _buildGoogle(BuildContext context) {
    assert(googleService != null, 'Google requires googleService');
    assert(
      googleIsInitialized != null,
      'Google requires googleIsInitialized flag',
    );

    if (googleIsInitialized != true) {
      return const Center(child: CircularProgressIndicator());
    }

    // Wrap in ListenableBuilder to react to auth state changes
    return ListenableBuilder(
      listenable: googleService!,
      builder: (context, child) {
        final isSignedIn = googleService!.isSignedIn;

        if (!isSignedIn) {
          // NOT signed in - show sign-in button
          return Center(
            child: ElevatedButton(
              onPressed: syncDisabled
                  ? null
                  : () async {
                      await _handleGoogleSignIn(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icon/google.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.black87,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('signin_google'.tr()),
                ],
              ),
            ),
          );
        }

        // IS signed in - show calendar selection UI
        return CalendarSignInWidget(
          provider: CalendarProvider.google,
          syncDisabled: syncDisabled,
          googleService: googleService,
          onSignOut: onSignOut,
          onCalendarSelected:
              onSignInSuccess, // Trigger when calendar is selected
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final success = await googleService!.signIn();
    if (success) {
      final settings = context.read<SettingsProvider>();

      // Get primary calendar
      final calendarId = await googleService!.getPrimaryCalendarId();
      await googleService!.setCalendarId(calendarId);

      await settings.setGoogleCalendar(
        calendarId: calendarId,
        userEmail: googleService!.userEmail,
      );

      await settings.setCalendarProvider(CalendarProvider.google);

      // Refresh the calendar adapter
      final diaryProvider = context.read<DiaryProvider>();
      diaryProvider.refreshCalendarAdapter();

      // Notify parent to update state
      if (onSignInSuccess != null) {
        onSignInSuccess!();
      }

      if (context.mounted) {
        ErrorSnackbar.showSuccess(
          context,
          'server_settings.signed_in_as'.tr([
            googleService!.userEmail ?? 'unknown'.tr(),
          ]),
        );
      }
    } else {
      if (context.mounted) {
        ErrorSnackbar.showWarning(
          context,
          'server_settings.sign_in_cancelled'.tr(),
        );
      }
    }
  }

  // Apple Calendar

  Widget _buildApple(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // Check if signed in (Apple uses CalDAV with iCloud URL)
    return FutureBuilder<String?>(
      future: settings.caldavPassword,
      builder: (context, passwordSnapshot) {
        // Check if we have iCloud credentials (signed in)
        // MUST have the exact iCloud URL to be considered signed in to Apple
        final hasCredentials =
            settings.caldavUrl != null &&
            settings.caldavUrl!.isNotEmpty &&
            (settings.caldavUrl!.contains('caldav.icloud.com') ||
                settings.caldavUrl!.contains('.icloud.com')) &&
            settings.caldavUsername != null &&
            settings.caldavUsername!.isNotEmpty &&
            passwordSnapshot.hasData &&
            passwordSnapshot.data != null &&
            passwordSnapshot.data!.isNotEmpty;

        if (!hasCredentials) {
          // NOT signed in - show Apple/iCloud login form
          assert(caldavUrlController != null, 'Apple requires url controller');
          assert(
            caldavUsernameController != null,
            'Apple requires username controller',
          );
          assert(
            caldavPasswordController != null,
            'Apple requires password controller',
          );
          assert(
            caldavCalendarNameController != null,
            'Apple requires calendar name controller',
          );

          return CalDAVServerForm(
            urlController: caldavUrlController!,
            usernameController: caldavUsernameController!,
            passwordController: caldavPasswordController!,
            calendarNameController: caldavCalendarNameController!,
            syncDisabled: syncDisabled,
            isAppleMode: true, // Enable Apple mode
            onSignInSuccess: onSignInSuccess,
            onServerSetupSave: onServerSetupSave, // Pass for server setup flow
          );
        }

        // HAS credentials - show calendar selection UI
        return CalendarSignInWidget(
          provider: CalendarProvider.apple,
          syncDisabled: syncDisabled,
          caldavUrl: settings.caldavUrl,
          caldavUsername: settings.caldavUsername,
          caldavPassword: passwordSnapshot.data,
          onSignOut: onSignOut,
          onCalendarSelected: onSignInSuccess,
        );
      },
    );
  }
}
