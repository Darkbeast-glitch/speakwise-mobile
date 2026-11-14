import 'package:speakwise_mobile/features/onboarding/data/models/onboarding_item.dart';

/// ═══════════════════════════════════════════════════════════════
/// Onboarding UI State
/// ═══════════════════════════════════════════════════════════════
class OnboardingState {
  final int currentPage;
  final List<OnboardingItem> items;
  final bool isCompleted;

  const OnboardingState({
    this.currentPage = 0,
    this.items = const [],
    this.isCompleted = false,
  });

  bool get isLastPage => items.isNotEmpty && currentPage == items.length - 1;
  OnboardingItem? get currentItem =>
      items.isNotEmpty && currentPage < items.length ? items[currentPage] : null;

  OnboardingState copyWith({
    int? currentPage,
    List<OnboardingItem>? items,
    bool? isCompleted,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      items: items ?? this.items,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
