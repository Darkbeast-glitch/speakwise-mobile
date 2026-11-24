import 'package:flutter/foundation.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/features/profile/data/models/user_profile_model.dart';
import 'package:speakwise_mobile/features/profile/data/profile_remote_datasource.dart';

abstract class ProfileRepository {
  Future<UserProfile> getUserProfile();
  Future<UserProfile> getSpeakerProfile(String slugOrId);
  Future<UserProfile> updateProfile(UserProfile updated);
  Future<bool> sendSpeakerEmailRequest({
    required String speakerId,
    required String eventName,
    required String location,
    required String message,
  });
  Future<bool> toggleFollowSpeaker(String slugOrId);
}

class DjangoProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final StorageService storageService;

  late UserProfile _currentProfile;

  DjangoProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  }) {
    _currentProfile = _buildLocalProfile();
  }

  UserProfile _buildLocalProfile() {
    return UserProfile(
      id: storageService.userId ?? '',
      slug: storageService.speakerSlug ?? storageService.username ?? '',
      userAccountId: storageService.userId ?? '',
      firstName: storageService.firstName ?? '',
      lastName: storageService.lastName ?? '',
      email: storageService.userEmail ?? '',
      username: storageService.username ?? '',
      nationality: storageService.nationality ?? '',
      avatarPath: storageService.userAvatar ?? '',
      organization: '',
      country: storageService.nationality ?? '',
      shortBio: '',
      biography: '',
      socialLinks: const {},
      skills: const [],
      badges: const [],
      eventsSpoken: const [],
      talks: const [],
      talksGiven: 0,
      attendeesCount: 0,
      positivePercentage: 0,
      averageRating: 0,
    );
  }

  @override
  Future<UserProfile> getUserProfile() async {
    // 1. If guest account, return clean guest profile
    if (storageService.isGuest) {
      return const UserProfile(
        id: 'guest',
        slug: 'guest',
        firstName: 'Guest',
        lastName: 'Account',
        email: 'guest@speakwise.live',
        username: 'guest',
        nationality: '',
        avatarPath: '',
        organization: 'Community Guest',
        country: '',
        shortBio: 'Exploring conferences and speaker insights on SpeakWise.',
        biography: '',
        socialLinks: {},
        skills: [],
        badges: [],
        eventsSpoken: [],
        talks: [],
        talksGiven: 0,
        attendeesCount: 0,
        positivePercentage: 0,
        averageRating: 0,
      );
    }

    // 2. Fetch authenticated user details from /users/me/
    Map<String, dynamic>? currentUserData;
    if (storageService.authToken != null && storageService.authToken!.isNotEmpty) {
      try {
        currentUserData = await remoteDataSource.fetchCurrentUser();
        if (currentUserData != null) {
          if (currentUserData['id'] != null) {
            await storageService.setUserId(currentUserData['id'].toString());
          }
          if (currentUserData['email'] != null) {
            await storageService.setUserEmail(currentUserData['email'].toString());
          }
          if (currentUserData['username'] != null) {
            await storageService.setUsername(currentUserData['username'].toString());
          }
          if (currentUserData['first_name'] != null) {
            await storageService.setFirstName(currentUserData['first_name'].toString());
          }
          if (currentUserData['last_name'] != null) {
            await storageService.setLastName(currentUserData['last_name'].toString());
          }
          if (currentUserData['nationality'] != null) {
            await storageService.setNationality(currentUserData['nationality'].toString());
          }
          if (currentUserData['speaker_id'] != null) {
            await storageService.setSpeakerId(currentUserData['speaker_id'].toString());
          }
        }
      } catch (e) {
        debugPrint('Django /users/me/ fetch note: $e');
      }
    }

    final slugOrId = currentUserData?['speaker_slug']?.toString() ??
        currentUserData?['speaker_id']?.toString() ??
        storageService.speakerSlug ??
        storageService.speakerId ??
        storageService.username;

    if (slugOrId != null && slugOrId.isNotEmpty) {
      try {
        final remoteProfile = await remoteDataSource.fetchSpeakerProfile(slugOrId);
        await storageService.setUserAvatar(remoteProfile.avatarPath);
        if (remoteProfile.slug.isNotEmpty) {
          await storageService.setSpeakerSlug(remoteProfile.slug);
        }
        // Ensure authenticated user first/last name, email and username take precedence
        final resolvedProfile = remoteProfile.copyWith(
          avatarPath: remoteProfile.avatarPath,
          firstName: storageService.firstName?.isNotEmpty == true
              ? storageService.firstName
              : remoteProfile.firstName,
          lastName: storageService.lastName?.isNotEmpty == true
              ? storageService.lastName
              : remoteProfile.lastName,
          email: storageService.userEmail?.isNotEmpty == true
              ? storageService.userEmail
              : remoteProfile.email,
          username: storageService.username?.isNotEmpty == true
              ? storageService.username
              : remoteProfile.username,
          nationality: storageService.nationality?.isNotEmpty == true
              ? storageService.nationality
              : remoteProfile.nationality,
        );
        _currentProfile = resolvedProfile;
        return resolvedProfile;
      } catch (e) {
        debugPrint('Django speaker profile fetch note: $e. Using local user profile.');
      }
    }

    _currentProfile = _buildLocalProfile();
    return _currentProfile;
  }

  @override
  Future<UserProfile> getSpeakerProfile(String slugOrId) async {
    try {
      return await remoteDataSource.fetchSpeakerProfile(slugOrId);
    } catch (e) {
      debugPrint('Django speaker profile fetch note: $e');
      rethrow;
    }
  }

  @override
  Future<UserProfile> updateProfile(UserProfile updated) async {
    try {
      final saved = await remoteDataSource.updateSpeakerProfile(updated);
      _currentProfile = saved;
      if (saved.avatarPath.isNotEmpty) {
        await storageService.setUserAvatar(saved.avatarPath);
      }
      if (saved.firstName.isNotEmpty) await storageService.setFirstName(saved.firstName);
      if (saved.lastName.isNotEmpty) await storageService.setLastName(saved.lastName);
      if (saved.username.isNotEmpty) await storageService.setUsername(saved.username);
      if (saved.nationality.isNotEmpty) await storageService.setNationality(saved.nationality);
      if (saved.slug.isNotEmpty) await storageService.setSpeakerSlug(saved.slug);
      return saved;
    } catch (e) {
      debugPrint('Django update profile note: $e');
      _currentProfile = updated;
      return _currentProfile;
    }
  }

  @override
  Future<bool> sendSpeakerEmailRequest({
    required String speakerId,
    required String eventName,
    required String location,
    required String message,
  }) async {
    try {
      await remoteDataSource.sendSpeakerEmailRequest(
        speakerId: speakerId,
        eventName: eventName,
        location: location,
        message: message,
      );
      return true;
    } catch (e) {
      debugPrint('Django speaker email request note: $e');
      rethrow;
    }
  }

  @override
  Future<bool> toggleFollowSpeaker(String slugOrId) async {
    return await remoteDataSource.toggleFollowSpeaker(slugOrId);
  }
}
