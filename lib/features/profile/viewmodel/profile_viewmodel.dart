import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/services/cache_manager.dart';
import 'package:speakwise_mobile/features/profile/data/models/user_profile_model.dart';
import 'package:speakwise_mobile/features/profile/data/profile_repository.dart';
import 'package:speakwise_mobile/features/profile/viewmodel/profile_state.dart';

class ProfileViewModel extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final CacheManager _cacheManager;

  bool _isFetching = false;
  Future<void>? _inFlightFetch;

  static const String _cacheKey = 'user_profile_cache';

  ProfileViewModel(this._repository, this._cacheManager)
      : super(
          ProfileState(
            status: ProfileStatus.loading,
            profile: const UserProfile(
              firstName: '',
              lastName: '',
              email: '',
              username: '',
              nationality: '',
              avatarPath: '',
              organization: '',
              country: '',
              shortBio: '',
              biography: '',
              socialLinks: {},
              skills: [],
              badges: [],
              talksGiven: 0,
              attendeesCount: 0,
              positivePercentage: 0,
              averageRating: 0,
            ),
          ),
        ) {
    // 1. Instant 0ms Screen Load from local cache
    _restoreFromCache();
    // 2. Revalidate in the background
    loadProfile();
  }

  /// 0ms Instant Cache Restoration
  void _restoreFromCache() {
    try {
      final cached = _cacheManager.getJsonMap(_cacheKey);
      if (cached != null) {
        final profile = UserProfile.fromJson(cached);
        if (profile.email.isNotEmpty || profile.username.isNotEmpty) {
          state = state.copyWith(
            status: ProfileStatus.success,
            profile: profile,
          );
          debugPrint('⚡ User profile restored instantly from disk (0ms)');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error restoring profile from cache: $e');
    }
  }

  /// Stale-While-Revalidate Loader with Debounce & Request Coalescing
  Future<void> loadProfile({bool force = false}) async {
    // 1. Debounce: If a fetch is already in flight, join it
    if (_isFetching && _inFlightFetch != null) {
      debugPrint('🔄 Profile fetch already in flight. Joining existing request.');
      return _inFlightFetch!;
    }

    // 2. Throttling: Do not hit server if data was fetched < 25s ago unless forced
    final hasData = state.profile.email.isNotEmpty || state.profile.username.isNotEmpty;
    if (!force && hasData && _cacheManager.isFresh(_cacheKey, maxAge: const Duration(seconds: 25))) {
      debugPrint('⚡ Profile data is fresh (< 25s). Skipping network hit.');
      return;
    }

    _isFetching = true;
    _inFlightFetch = _executeFetch(force: force);

    try {
      await _inFlightFetch;
    } finally {
      _isFetching = false;
      _inFlightFetch = null;
    }
  }

  Future<void> _executeFetch({bool force = false}) async {
    // Only show loading spinner/shimmer if we have NO cached profile
    if (state.profile.email.isEmpty && state.profile.username.isEmpty) {
      state = state.copyWith(status: ProfileStatus.loading);
    }

    try {
      final profile = await _repository.getUserProfile();
      state = state.copyWith(status: ProfileStatus.success, profile: profile);

      // Persist to cache
      await _cacheManager.put(_cacheKey, profile.toJson());
    } catch (e) {
      debugPrint('⚠️ Profile fetch error: $e');
      if (state.profile.email.isEmpty && state.profile.username.isEmpty) {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? username,
    String? nationality,
    String? organization,
    String? country,
    String? shortBio,
    String? biography,
    Map<String, String>? socialLinks,
    List<String>? skills,
    String? avatarPath,
  }) async {
    final updated = state.profile.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      username: username,
      nationality: nationality,
      organization: organization,
      country: country,
      shortBio: shortBio,
      biography: biography,
      socialLinks: socialLinks,
      skills: skills,
      avatarPath: avatarPath,
    );

    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final result = await _repository.updateProfile(updated);
      state = state.copyWith(status: ProfileStatus.success, profile: result);

      // Update cache
      await _cacheManager.put(_cacheKey, result.toJson());
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void addSkill(String skill) {
    if (skill.trim().isEmpty) return;
    final trimmed = skill.trim();
    if (!state.profile.skills.contains(trimmed)) {
      final updatedSkills = [...state.profile.skills, trimmed];
      updateProfile(skills: updatedSkills);
    }
  }

  void removeSkill(String skill) {
    final updatedSkills = state.profile.skills.where((s) => s != skill).toList();
    updateProfile(skills: updatedSkills);
  }

  /// Clears in-memory profile and cached profile on disk
  Future<void> reset() async {
    await _cacheManager.remove(_cacheKey);
    state = ProfileState(
      status: ProfileStatus.loading,
      profile: const UserProfile(
        firstName: '',
        lastName: '',
        email: '',
        username: '',
        nationality: '',
        avatarPath: '',
        organization: '',
        country: '',
        shortBio: '',
        biography: '',
        socialLinks: {},
        skills: [],
        badges: [],
        talksGiven: 0,
        attendeesCount: 0,
        positivePercentage: 0,
        averageRating: 0,
      ),
    );
  }
}
