import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/features/onboarding/data/repository/onboarding_repository.dart';
import 'package:speakwise_mobile/features/onboarding/viewmodel/onboarding_state.dart';

/// ═══════════════════════════════════════════════════════════════
/// Onboarding ViewModel
/// ═══════════════════════════════════════════════════════════════
class OnboardingViewModel extends StateNotifier<OnboardingState> {
  final OnboardingRepository _repository;

  OnboardingViewModel(this._repository)
      : super(OnboardingState(
          items: _repository.getOnboardingItems(),
          isCompleted: _repository.hasCompletedOnboarding(),
        ));

  void onPageChanged(int index) {
    if (index >= 0 && index < state.items.length) {
      state = state.copyWith(currentPage: index);
    }
  }

  Future<void> completeOnboarding() async {
    await _repository.completeOnboarding();
    state = state.copyWith(isCompleted: true);
  }
}
