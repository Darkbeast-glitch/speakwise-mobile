import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/ambient_glow.dart';
import 'package:speakwise_mobile/features/talks/view/widgets/add_talk_modal.dart';
import 'package:speakwise_mobile/features/talks/view/widgets/feedback_tab_view.dart';
import 'package:speakwise_mobile/features/talks/view/widgets/speaking_sessions_tab_view.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_provider.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen 4: Talks & Feedback Hub (Tab 3)
/// Segmented Switcher: [Feedback] & [My Speaking Sessions]
/// Fully connected to Webapp Speaking Experiences & QR Generator
/// ═══════════════════════════════════════════════════════════════
class TalksScreen extends ConsumerStatefulWidget {
  const TalksScreen({super.key});

  @override
  ConsumerState<TalksScreen> createState() => _TalksScreenState();
}

class _TalksScreenState extends ConsumerState<TalksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(talksViewModelProvider.notifier).loadTalksData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final talksState = ref.watch(talksViewModelProvider);
    final selectedTab = talksState.selectedTab;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: AmbientGlow(
        glowOpacity: 0.16,
        glowAlignment: const Alignment(-0.6, -0.6),
        radius: 0.85,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Top Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Talks & Feedback',
                      style: AppTheme.font(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        AddTalkModal.show(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.black, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'New Talk',
                              style: AppTheme.font(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Segmented Mode Switcher: [Feedback] & [My Speaking Sessions]
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12140F),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Tab 0: Feedback (formerly Attended Talks)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(talksViewModelProvider.notifier).setSelectedTab(0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: selectedTab == 0
                                  ? AppTheme.primaryAccent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: selectedTab == 0 ? Colors.black : AppTheme.textMuted,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Feedback',
                                  style: AppTheme.font(
                                    color: selectedTab == 0
                                        ? Colors.black
                                        : AppTheme.textMuted,
                                    fontSize: 13,
                                    fontWeight: selectedTab == 0
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Tab 1: My Speaking Sessions
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(talksViewModelProvider.notifier).setSelectedTab(1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: selectedTab == 1
                                  ? AppTheme.primaryAccent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mic_rounded,
                                  color: selectedTab == 1 ? Colors.black : AppTheme.textMuted,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'My Speaking Sessions',
                                  style: AppTheme.font(
                                    color: selectedTab == 1
                                        ? Colors.black
                                        : AppTheme.textMuted,
                                    fontSize: 13,
                                    fontWeight: selectedTab == 1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Tab Body
              Expanded(
                child: selectedTab == 0
                    ? const FeedbackTabView()
                    : const SpeakingSessionsTabView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
