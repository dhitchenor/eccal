import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_info.dart';
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
        final hasCredentials = settings.caldavUrl != null &&
            settings.caldavUrl!.isNotEmpty &&
            settings.caldavUsername != null &&
            settings.caldavUsername!.isNotEmpty &&
            passwordSnapshot.hasData &&
            passwordSnapshot.data != null &&
            passwordSnapshot.data!.isNotEmpty;

        // Check if calendar is selected
        final hasCalendar = settings.caldavCalendarName != null &&
            settings.caldavCalendarName!.isNotEmpty;

        if (!hasCredentials) {
          // NOT signed in - show login form
          assert(caldavUrlController != null, 'CalDAV requires url controller');
          assert(caldavUsernameController != null, 'CalDAV requires username controller');
          assert(caldavPasswordController != null, 'CalDAV requires password controller');
          assert(caldavCalendarNameController != null, 'CalDAV requires calendar name controller');

          return CalDAVServerForm(
            urlController: caldavUrlController!,
            usernameController: caldavUsernameController!,
            passwordController: caldavPasswordController!,
            calendarNameController: caldavCalendarNameController!,
            syncDisabled: syncDisabled,
            onSignInSuccess: onSignInSuccess, // Pass callback to trigger rebuild
          );
        }

        // HAS credentials - show calendar selection UI
        return CalendarSignInWidget(
          provider: CalendarProvider.caldav,
          syncDisabled: syncDisabled,
          caldavUrl: settings.caldavUrl,
          caldavUsername: settings.caldavUsername,
          caldavPassword: passwordSnapshot.data, // Pass the actual password value
          onSignOut: onSignOut,
          onCalendarSelected: onSignInSuccess, // Trigger when calendar is selected
        );
      },
    );
  }

  // Google Calendar

  Widget _buildGoogle(BuildContext context) {
    assert(googleService != null, 'Google requires googleService');
    assert(googleIsInitialized != null, 'Google requires googleIsInitialized flag');

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
            child: ElevatedButton.icon(
              onPressed: syncDisabled
                  ? null
                  : () async {
                      await _handleGoogleSignIn(context);
                    },
              icon: const Icon(Icons.g_mobiledata_rounded),
              label: Text('signin_google'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
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
          onCalendarSelected: onSignInSuccess, // Trigger when calendar is selected
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
    // TODO: Implement Apple Calendar
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.apple, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Apple Calendar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
