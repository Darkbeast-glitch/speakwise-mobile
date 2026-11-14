import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/features/profile/data/models/user_profile_model.dart';
import 'package:speakwise_mobile/features/profile/data/profile_repository.dart';
import 'package:speakwise_mobile/features/profile/viewmodel/profile_state.dart';

class ProfileViewModel extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileViewModel(this._repository)
      : super(
          ProfileState(
            status: ProfileStatus.loading,
            profile: UserProfile(
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
              socialLinks: const {},
              skills: const [],
              badges: const [],
              talksGiven: 0,
              attendeesCount: 0,
              positivePercentage: 0,
              averageRating: 0,
            ),
          ),
        ) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final profile = await _repository.getUserProfile();
      state = state.copyWith(status: ProfileStatus.success, profile: profile);
    } catch (e) {
      state = state.copyWith(status: ProfileStatus.error, errorMessage: e.toString());
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
    );

    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final result = await _repository.updateProfile(updated);
      state = state.copyWith(status: ProfileStatus.success, profile: result);
    } catch (e) {
      state = state.copyWith(status: ProfileStatus.error, errorMessage: e.toString());
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
}
