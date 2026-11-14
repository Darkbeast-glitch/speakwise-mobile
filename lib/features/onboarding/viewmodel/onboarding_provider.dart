import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/features/onboarding/data/onboarding_local_datasource.dart';
import 'package:speakwise_mobile/features/onboarding/data/onboarding_repository_impl.dart';
import 'package:speakwise_mobile/features/onboarding/data/repository/onboarding_repository.dart';
import 'package:speakwise_mobile/features/onboarding/viewmodel/onboarding_state.dart';
import 'package:speakwise_mobile/features/onboarding/viewmodel/onboarding_viewmodel.dart';

/// ═══════════════════════════════════════════════════════════════
/// Onboarding Riverpod Dependency Graph
/// ═══════════════════════════════════════════════════════════════

// 1. Data Source
final onboardingLocalDataSourceProvider =
    Provider<OnboardingLocalDataSource>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return OnboardingLocalDataSource(storage);
});

// 2. Repository
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final localDataSource = ref.watch(onboardingLocalDataSourceProvider);
  return OnboardingRepositoryImpl(localDataSource);
});

// 3. ViewModel StateNotifier
final onboardingViewModelProvider =
    StateNotifierProvider<OnboardingViewModel, OnboardingState>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return OnboardingViewModel(repository);
});
