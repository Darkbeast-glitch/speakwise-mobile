import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/core/widgets/ambient_glow.dart';
import 'package:speakwise_mobile/core/widgets/app_button.dart';
import 'package:speakwise_mobile/core/widgets/skip_button.dart';
import 'package:speakwise_mobile/features/onboarding/view/widgets/onboarding_indicators.dart';
import 'package:speakwise_mobile/features/onboarding/view/widgets/stacked_cards_hero.dart';
import 'package:speakwise_mobile/features/onboarding/viewmodel/onboarding_provider.dart';

/// ═══════════════════════════════════════════════════════════════
/// Onboarding Screen (Pixel-Perfect Implementation of User Reference)
/// ═══════════════════════════════════════════════════════════════
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingViewModelProvider.notifier).onPageChanged(0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    final state = ref.read(onboardingViewModelProvider);
    if (!state.isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    await ref.read(onboardingViewModelProvider.notifier).completeOnboarding();
    if (mounted) {
      final isAuth = ref.read(storageServiceProvider).isAuthenticated;
      context.go(isAuth ? '/shell' : '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final items = state.items;

    if (items.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: AmbientGlow(
        glowOpacity: 0.26,
        glowAlignment: const Alignment(0.0, -0.65),
        radius: 0.95,
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Navigation Bar with "Skip" Pill
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (context.canPop()) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: AppTheme.textPrimary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: 10),
                        ],
                        // Subtle SpeakWise Wordmark / Logo Indicator
                        Text(
                          'SpeakWise',
                          style: AppTheme.font(
                            color: AppTheme.textPrimary.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    SkipButton(onTap: _finishOnboarding),
                  ],
                ),
              ),

              // 2. Swipable Carousel Area
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: items.length,
                  onPageChanged: (index) {
                    ref
                        .read(onboardingViewModelProvider.notifier)
                        .onPageChanged(index);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const SizedBox(height: 6),

                                  // Stacked 3D Cards Hero
                                  StackedCardsHero(
                                    centerImagePath: item.centerImagePath,
                                    leftImagePath: item.leftImagePath,
                                    rightImagePath: item.rightImagePath,
                                  ),

                                  const SizedBox(height: 20),

                                  // Main Headline
                                  Text(
                                    item.title,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.font(
                                      color: AppTheme.textPrimary,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.7,
                                      height: 1.16,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Subtitle with Highlighted Brand Span
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: AppTheme.font(
                                        color: AppTheme.textMuted,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                        height: 1.45,
                                      ),
                                      children: [
                                        TextSpan(text: item.subtitlePrefix),
                                        TextSpan(
                                          text: item.subtitleHighlight,
                                          style: AppTheme.font(
                                            color: AppTheme.primaryAccent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 3. Dot / Pill Page Indicators
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: OnboardingIndicators(
                  count: items.length,
                  currentIndex: state.currentPage,
                ),
              ),

              // 4. Primary High-Contrast Pill CTA
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ).copyWith(bottom: 20),
                child: AppButton.light(
                  text: state.currentItem?.ctaText ?? 'Continue',
                  onPressed: _onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
