import 'package:speakwise_mobile/features/onboarding/data/models/onboarding_item.dart';
import 'package:speakwise_mobile/features/onboarding/data/onboarding_local_datasource.dart';
import 'package:speakwise_mobile/features/onboarding/data/repository/onboarding_repository.dart';

/// ═══════════════════════════════════════════════════════════════
/// Onboarding Repository Implementation
/// ═══════════════════════════════════════════════════════════════
class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource _localDataSource;

  OnboardingRepositoryImpl(this._localDataSource);

  @override
  List<OnboardingItem> getOnboardingItems() {
    return const [
      OnboardingItem(
        index: 0,
        title: 'Explore & Join\nExclusive Events',
        subtitlePrefix:
            'Build your speaker portfolio, elevate your stage presence, and discover upcoming tech events on ',
        subtitleHighlight: 'SpeakWise.',
        ctaText: 'Continue',
        centerImagePath: 'assets/images/Juliana.jpg',
        leftImagePath: 'assets/images/Julius.png',
        rightImagePath: 'assets/images/ezra.jpg',
      ),
      OnboardingItem(
        index: 1,
        title: 'Instant, Honest\nTalk Feedback',
        subtitlePrefix:
            'Scan the slide QR code and rate talk clarity, energy, and value in under 60 seconds on ',
        subtitleHighlight: 'SpeakWise.',
        ctaText: 'Continue',
        centerImagePath: 'assets/images/ezra.jpg',
        leftImagePath: 'assets/images/Juliana.jpg',
        rightImagePath: 'assets/images/Julius.png',
      ),
      OnboardingItem(
        index: 2,
        title: 'Build Reputation &\nSupport Speakers',
        subtitlePrefix:
            'Watch your speaker score compound with every talk, earn verifiable badges, and gift your favorite speakers on ',
        subtitleHighlight: 'SpeakWise.',
        ctaText: 'Get Started',
        centerImagePath: 'assets/images/Julius.png',
        leftImagePath: 'assets/images/ezra.jpg',
        rightImagePath: 'assets/images/Juliana.jpg',
      ),
    ];
  }

  @override
  bool hasCompletedOnboarding() {
    return _localDataSource.hasSeenOnboarding;
  }

  @override
  Future<void> completeOnboarding() async {
    await _localDataSource.markOnboardingComplete();
  }
}
