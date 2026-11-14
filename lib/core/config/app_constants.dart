/// ═══════════════════════════════════════════════════════════════
/// SpeakWise App Constants & Storage Keys
/// ═══════════════════════════════════════════════════════════════
class AppConstants {
  static const String appName = 'SpeakWise';
  static const String appTagline = 'Elevate Your Voice. Measure Your Impact.';

  // Local Storage Keys
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keySpeakerId = 'speaker_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUsername = 'username';
  static const String keyFirstName = 'first_name';
  static const String keyLastName = 'last_name';
  static const String keyNationality = 'nationality';
  static const String keySpeakerSlug = 'speaker_slug';
  static const String keyIsGuest = 'is_guest';

  // API Config (Points to Django Backend running on development Mac over LAN)
  static const String defaultApiUrl = 'http://192.168.0.192:8000/api';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
