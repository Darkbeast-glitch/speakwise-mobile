import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/services/cache_manager.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/features/profile/data/models/user_profile_model.dart';
import 'package:speakwise_mobile/features/profile/data/profile_remote_datasource.dart';
import 'package:speakwise_mobile/features/profile/data/profile_repository.dart';
import 'package:speakwise_mobile/features/profile/viewmodel/profile_state.dart';
import 'package:speakwise_mobile/features/profile/viewmodel/profile_viewmodel.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remote = ref.watch(profileRemoteDataSourceProvider);
  final storage = ref.watch(storageServiceProvider);
  return DjangoProfileRepositoryImpl(
    remoteDataSource: remote,
    storageService: storage,
  );
});

final profileViewModelProvider =
    StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return ProfileViewModel(repository, cacheManager);
});

final speakerProfileProvider =
    FutureProvider.family<UserProfile, String>((ref, slugOrId) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getSpeakerProfile(slugOrId);
});

