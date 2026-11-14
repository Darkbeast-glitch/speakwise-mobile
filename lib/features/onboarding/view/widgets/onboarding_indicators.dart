import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// Smooth Pill & Dot Page Indicator
/// ═══════════════════════════════════════════════════════════════
class OnboardingIndicators extends StatelessWidget {
  final int count;
  final int currentIndex;

  const OnboardingIndicators({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          height: 6.0,
          width: isActive ? 22.0 : 6.0,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(3.0),
          ),
        );
      }),
    );
  }
}
