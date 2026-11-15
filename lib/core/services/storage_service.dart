import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakwise_mobile/core/config/app_constants.dart';

/// ═══════════════════════════════════════════════════════════════
/// Local Storage Service (SharedPreferences)
/// ═══════════════════════════════════════════════════════════════
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  bool get hasSeenOnboarding =>
      _prefs.getBool(AppConstants.keyHasSeenOnboarding) ?? false;

  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(AppConstants.keyHasSeenOnboarding, value);
  }

  String? get authToken => _prefs.getString(AppConstants.keyAuthToken);

  Future<void> setAuthToken(String token) async {
    await _prefs.setString(AppConstants.keyAuthToken, token);
  }

  String? get refreshToken => _prefs.getString(AppConstants.keyRefreshToken);

  Future<void> setRefreshToken(String token) async {
    await _prefs.setString(AppConstants.keyRefreshToken, token);
  }

  String? get userId => _prefs.getString(AppConstants.keyUserId);

  Future<void> setUserId(String id) async {
    await _prefs.setString(AppConstants.keyUserId, id);
  }

  String? get speakerId => _prefs.getString(AppConstants.keySpeakerId);

  Future<void> setSpeakerId(String id) async {
    await _prefs.setString(AppConstants.keySpeakerId, id);
  }

  String? get userEmail => _prefs.getString(AppConstants.keyUserEmail);

  Future<void> setUserEmail(String email) async {
    await _prefs.setString(AppConstants.keyUserEmail, email);
  }

  String? get username => _prefs.getString(AppConstants.keyUsername);

  Future<void> setUsername(String username) async {
    await _prefs.setString(AppConstants.keyUsername, username);
  }

  String? get firstName => _prefs.getString(AppConstants.keyFirstName);

  Future<void> setFirstName(String firstName) async {
    await _prefs.setString(AppConstants.keyFirstName, firstName);
  }

  String? get lastName => _prefs.getString(AppConstants.keyLastName);

  Future<void> setLastName(String lastName) async {
    await _prefs.setString(AppConstants.keyLastName, lastName);
  }

  String? get nationality => _prefs.getString(AppConstants.keyNationality);

  Future<void> setNationality(String nationality) async {
    await _prefs.setString(AppConstants.keyNationality, nationality);
  }

  String? get speakerSlug => _prefs.getString(AppConstants.keySpeakerSlug);

  Future<void> setSpeakerSlug(String speakerSlug) async {
    await _prefs.setString(AppConstants.keySpeakerSlug, speakerSlug);
  }

  bool get isGuest => _prefs.getBool(AppConstants.keyIsGuest) ?? false;

  bool get isAuthenticated {
    final token = authToken?.trim();
    return (token != null && token.isNotEmpty && token != 'null') || isGuest;
  }

  Future<void> setIsGuest(bool value) async {
    await _prefs.setBool(AppConstants.keyIsGuest, value);
  }

  Future<void> clearAuth() async {
    await _prefs.remove(AppConstants.keyAuthToken);
    await _prefs.remove(AppConstants.keyRefreshToken);
    await _prefs.remove(AppConstants.keyUserId);
    await _prefs.remove(AppConstants.keySpeakerId);
    await _prefs.remove(AppConstants.keyUserEmail);
    await _prefs.remove(AppConstants.keyUsername);
    await _prefs.remove(AppConstants.keyFirstName);
    await _prefs.remove(AppConstants.keyLastName);
    await _prefs.remove(AppConstants.keyNationality);
    await _prefs.remove(AppConstants.keySpeakerSlug);
    await _prefs.setBool(AppConstants.keyIsGuest, false);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in bootstrap');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(sharedPreferencesProvider));
});
