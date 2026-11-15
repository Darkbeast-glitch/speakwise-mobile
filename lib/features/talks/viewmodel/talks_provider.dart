import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/services/cache_manager.dart';
import 'package:speakwise_mobile/features/talks/data/talks_remote_datasource.dart';
import 'package:speakwise_mobile/features/talks/data/talks_repository.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_state.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_viewmodel.dart';

export 'package:speakwise_mobile/features/talks/viewmodel/talks_state.dart';
export 'package:speakwise_mobile/features/talks/viewmodel/talks_viewmodel.dart';

final talksRepositoryProvider = Provider<TalksRepository>((ref) {
  final remote = ref.watch(talksRemoteDataSourceProvider);
  return DjangoTalksRepositoryImpl(remoteDataSource: remote);
});

final talksViewModelProvider =
    StateNotifierProvider<TalksViewModel, TalksState>((ref) {
  final repository = ref.watch(talksRepositoryProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return TalksViewModel(repository, cacheManager);
});
