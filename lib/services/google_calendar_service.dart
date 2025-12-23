import 'dart:convert';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

// Service for handling Google Calendar OAuth authentication ONLY
class GoogleCalendarService {
  late final GoogleSignIn _googleSignIn;

  // Storage keys
  static const String _calendarIdKey = 'google_calendar_id';

  GoogleSignInCredentials? _credentials;
  bool _isInitialized = false;

  // Get current user's email
  String? get userEmail => _credentials?.idToken != null
      ? 'user@example.com'
      : null; // Parse from idToken if needed

  // Check if user is signed in
  bool get isSignedIn => _credentials != null;

  // Stream of authentication state changes
  Stream<GoogleSignInCredentials?> get authenticationState =>
      _googleSignIn.authenticationState;

  // Initialize the service
  Future<void> initialize({
    required String clientId,
    required String clientSecret,
  }) async {
    if (_isInitialized) return;

    logger.info(
      'Google Calendar: Initializing with google_sign_in_all_platforms...',
    );

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
      logger.info('Google Calendar: Initialized successfully');

      // Listen to authentication state changes
      _googleSignIn.authenticationState.listen((credentials) {
        _credentials = credentials;
        logger.info(
          'Google Calendar: Auth state changed - signed in: ${credentials != null}',
        );
      });

      // Try silent sign-in to restore previous session
      logger.info('Google Calendar: Attempting silent sign-in...');
      _credentials = await _googleSignIn.silentSignIn();
      if (_credentials != null) {
        logger.info('Google Calendar: Restored previous session');
      }
    } catch (e, stackTrace) {
      logger.error('Google Calendar: Failed to initialize: $e');
      logger.debug('Stack trace: $stackTrace');
    }
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    logger.info('=== Google Calendar: signIn() called ===');

    if (!_isInitialized) {
      logger.error('Google Calendar: Not initialized!');
      return false;
    }

    try {
      logger.info('Google Calendar: Calling GoogleSignIn.signIn()...');

      // This automatically handles the right flow for each platform:
      // - Desktop: Opens browser for OAuth
      // - Mobile: Uses native sign-in
      // - Web: Must use signInButton() widget instead
      final credentials = await _googleSignIn.signIn();

      if (credentials != null) {
        _credentials = credentials;
        logger.info('Google Calendar: Successfully signed in');
        logger.debug('Google Calendar: Access token obtained');
        return true;
      } else {
        logger.info('Google Calendar: Sign-in returned null (user cancelled?)');
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
      logger.info('Google Calendar: Access token expired, need to refresh');
      // The package handles refresh automatically when you use authenticatedClient
    }

    return _credentials!.accessToken;
  }

  // List all calendars accessible to the user
  Future<List<Map<String, dynamic>>> listCalendars() async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated with Google Calendar');
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>;
        return items
            .map(
              (item) => {
                'id': item['id'] as String,
                'summary': item['summary'] as String,
                'description': item['description'] as String?,
                'primary': item['primary'] as bool? ?? false,
              },
            )
            .toList();
      } else {
        throw Exception(
          'Failed to list calendars: ${response.statusCode} ${response.body}',
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
      (cal) => cal['primary'] == true,
      orElse: () => calendars.first,
    );
    return primary['id'] as String;
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
    return 'https://apidata.googleusercontent.com/caldav/v2/$calendarId';
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
