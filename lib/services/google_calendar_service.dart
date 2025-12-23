import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';
import '../models/calendar_info.dart';
import '../providers/settings_provider.dart';
import '../utils/app_localizations.dart';

// Service for handling Google Calendar OAuth authentication ONLY
class GoogleCalendarService extends ChangeNotifier {
  late final GoogleSignIn _googleSignIn;

  // Storage keys
  static const String _calendarIdKey = 'google_calendar_id';

  GoogleSignInCredentials? _credentials;
  bool _isInitialized = false;

  // Get current user's email
  String? get userEmail {
    if (_credentials?.idToken == null) return null;

    try {
      // Decode JWT ID token to get email
      // JWT format: header.payload.signature
      final parts = _credentials!.idToken!.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part)
      // Add padding if needed for base64 decoding
      var payload = parts[1];
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final json = jsonDecode(decoded) as Map<String, dynamic>;

      return json['email'] as String?;
    } catch (e) {
      logger.error('Failed to extract email from ID token: $e');
      return null;
    }
  }

  // Check if user is signed in with a valid token
  bool get isSignedIn {
    if (_credentials == null) return false;

    // Check if token is expired
    if (_credentials!.expiresIn != null) {
      final now = DateTime.now();
      final expiry = _credentials!.expiresIn!;

      if (now.isAfter(expiry)) {
        // Token is expired - clear credentials and notify
        logger.debug('Google Calendar: Token expired in isSignedIn check');
        _credentials = null;

        // Schedule notification for after current frame
        Future.microtask(() => notifyListeners());
        return false;
      }
    }

    return true;
  }

  // Stream of authentication state changes
  Stream<GoogleSignInCredentials?> get authenticationState =>
      _googleSignIn.authenticationState;

  // Initialize the service
  Future<void> initialize({
    required String clientId,
    required String clientSecret,
  }) async {
    if (_isInitialized) return;

    try {
      _googleSignIn = GoogleSignIn(
        params: GoogleSignInParams(
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: [
            'openid',
            'profile',
            'email',
            'https://www.googleapis.com/auth/calendar',
            'https://www.googleapis.com/auth/calendar.events',
          ],
          redirectPort: 8000, // For desktop
        ),
      );

      _isInitialized = true;
      logger.debug('Google Calendar: Initialized successfully');

      // Listen to authentication state changes
      _googleSignIn.authenticationState.listen((credentials) {
        _credentials = credentials;
        logger.info(
          'Google Calendar: Auth state changed - signed in: ${credentials != null}',
        );
        notifyListeners(); // Notify UI of auth state change
      });

      // Try silent sign-in to restore previous session
      _credentials = await _googleSignIn.silentSignIn();
      if (_credentials != null) {
        logger.debug('Google Calendar: Restored previous session');
      }
    } catch (e, stackTrace) {
      logger.error('Google Calendar: Failed to initialize: $e');
      logger.debug('Stack trace: $stackTrace');
    }
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    logger.debug('Google Calendar: signIn() called');

    if (!_isInitialized) {
      logger.error('Google Calendar: Not initialized!');
      return false;
    }

    try {
      // First, sign out to clear any cached credentials
      logger.debug('Google Calendar: Clearing any cached credentials...');
      await _googleSignIn.signOut();
      _credentials = null;

      // This automatically handles the right flow for each platform:
      // - Desktop: Opens browser for OAuth
      // - Mobile: Uses native sign-in
      // - Web: Must use signInButton() widget instead
      final credentials = await _googleSignIn.signIn();

      if (credentials != null) {
        _credentials = credentials;

        // Check if token is valid
        if (_credentials!.expiresIn != null) {
          final now = DateTime.now();
          final expiry = _credentials!.expiresIn!;

          logger.debug('Google Calendar: Token expires at: $expiry');
          logger.debug('Google Calendar: Current time: $now');

          if (now.isAfter(expiry)) {
            // Token is already expired - this shouldn't happen with a fresh sign-in
            logger.error('Google Calendar: Fresh sign-in returned expired token!');
            _credentials = null;
            notifyListeners();
            return false;
          }
        }

        logger.info('Google Calendar: Successfully signed in');
        logger.debug('Google Calendar: Access token obtained and valid');

        notifyListeners(); // Notify UI
        return true;
      } else {
        logger.error('Google Calendar: Sign-in returned null (user cancelled?)');
        return false;
      }
    } catch (e, stackTrace) {
      logger.error('Google Calendar: Sign-in error: $e');
      logger.error('Google Calendar: Error type: ${e.runtimeType}');
      logger.debug('Google Calendar: Stack trace: $stackTrace');
      return false;
    }
  }

  // Sign out from Google account
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _credentials = null;

      // Clear stored calendar ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_calendarIdKey);

      logger.info('Google Calendar: Signed out successfully');
      notifyListeners(); // Notify UI
    } catch (e) {
      logger.error('Google Calendar: Sign-out failed: $e');
    }
  }

  // Get access token
  Future<String?> _getAccessToken() async {
    if (_credentials == null) return null;

    // Check if token is expired
    if (_credentials!.expiresIn != null &&
        DateTime.now().isAfter(_credentials!.expiresIn!)) {
      logger.error('Google Calendar: Access token expired - clearing credentials');
      logger.error('Google Calendar: User must sign in again');

      // Don't try to refresh - it just returns expired tokens
      // Force the user to sign in again properly
      _credentials = null;
      notifyListeners();
      return null;
    }

    return _credentials!.accessToken;
  }

  // List all calendars accessible to the user
  Future<List<CalendarInfo>> listCalendars() async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('caldav.google_notauth'.tr());
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/users/me/calendarList',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Handle 401 - token is invalid
      if (response.statusCode == 401) {
        logger.error('Google Calendar: 401 Unauthorized - clearing credentials');
        _credentials = null;
        notifyListeners(); // Notify UI to update
        throw Exception('caldav.auth_expired'.tr());
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>;
        return items
            .map((item) => CalendarInfo(
                  id: item['id'] as String,
                  name: item['summary'] as String,
                  description: item['description'] as String?,
                  isPrimary: item['primary'] as bool? ?? false,
                  provider: CalendarProvider.google,
                  color: item['backgroundColor'] as String?,
                ))
            .toList();
      } else {
        throw Exception(
          '${'caldav.failed_list_calendars'.tr()}: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      logger.error('Google Calendar: Failed to list calendars: $e');
      rethrow;
    }
  }

  // Get the primary calendar ID
  Future<String> getPrimaryCalendarId() async {
    final calendars = await listCalendars();
    final primary = calendars.firstWhere(
      (cal) => cal.isPrimary,
      orElse: () => calendars.first,
    );
    return primary.id;
  }

  // Create a new calendar
  Future<String> createCalendar(String calendarName) async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('caldav.google_notauth'.tr());
    }

    try {
      final response = await http.post(
        Uri.parse('https://www.googleapis.com/calendar/v3/calendars'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'summary': calendarName,
          'timeZone': 'UTC',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final calendarId = data['id'] as String;
        logger.info('Google Calendar: Created calendar "$calendarName" with ID: $calendarId');
        return calendarId;
      } else {
        throw Exception(
          'Failed to create calendar: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      logger.error('Google Calendar: Failed to create calendar: $e');
      rethrow;
    }
  }

  // Set the calendar ID to use for synchronization
  Future<void> setCalendarId(String calendarId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calendarIdKey, calendarId);
  }

  // Get the stored calendar ID
  Future<String?> getCalendarId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_calendarIdKey);
  }

  /// Get CalDAV URL for Google Calendar
  Future<String?> getCalDAVUrl({String? calendarId}) async {
    calendarId ??= await getCalendarId();
    if (calendarId == null) return null;
    // Google Calendar CalDAV endpoint requires /events path
    return 'https://apidata.googleusercontent.com/caldav/v2/$calendarId/events';
  }

  // Get authentication headers for CalDAV requests
  Future<Map<String, String>?> getAuthHeaders() async {
    final token = await _getAccessToken();
    if (token == null) return null;

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'text/calendar; charset=utf-8',
    };
  }

  /// Test connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      if (!isSignedIn) {
        return {'success': false, 'error': 'Not signed in to Google Calendar'};
      }

      final token = await _getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Failed to get access token'};
      }

      await listCalendars();

      return {
        'success': true,
        'message': 'Connected to Google Calendar',
        'email': userEmail,
      };
    } catch (e) {
      return {'success': false, 'error': 'Connection test failed: $e'};
    }
  }
}
