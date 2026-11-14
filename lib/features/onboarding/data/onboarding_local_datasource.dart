import 'package:speakwise_mobile/core/services/storage_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// Onboarding Local Data Source
/// ═══════════════════════════════════════════════════════════════
class OnboardingLocalDataSource {
  final StorageService _storageService;

  OnboardingLocalDataSource(this._storageService);

  bool get hasSeenOnboarding => _storageService.hasSeenOnboarding;

  Future<void> markOnboardingComplete() async {
    await _storageService.setHasSeenOnboarding(true);
  }
}
