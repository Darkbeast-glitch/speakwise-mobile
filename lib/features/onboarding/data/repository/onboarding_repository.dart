import 'package:speakwise_mobile/features/onboarding/data/models/onboarding_item.dart';

/// ═══════════════════════════════════════════════════════════════
/// Onboarding Repository Contract
/// ═══════════════════════════════════════════════════════════════
abstract class OnboardingRepository {
  List<OnboardingItem> getOnboardingItems();
  bool hasCompletedOnboarding();
  Future<void> completeOnboarding();
}
