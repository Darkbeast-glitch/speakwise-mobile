/// ═══════════════════════════════════════════════════════════════
/// Onboarding Slide Model
/// ═══════════════════════════════════════════════════════════════
class OnboardingItem {
  final int index;
  final String title;
  final String subtitlePrefix;
  final String subtitleHighlight;
  final String ctaText;
  final String centerImagePath;
  final String leftImagePath;
  final String rightImagePath;

  const OnboardingItem({
    required this.index,
    required this.title,
    required this.subtitlePrefix,
    required this.subtitleHighlight,
    required this.ctaText,
    required this.centerImagePath,
    required this.leftImagePath,
    required this.rightImagePath,
  });
}
