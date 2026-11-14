import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/features/talks/data/models/talk_model.dart';
import 'package:speakwise_mobile/features/talks/view/widgets/add_talk_modal.dart';
import 'package:speakwise_mobile/features/talks/view/widgets/talk_qr_code_modal.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_provider.dart';

/// ═══════════════════════════════════════════════════════════════
/// My Speaking Sessions Tab View
/// Talk Directory with Live Status & Feedback QR Presenter
/// (Matches Webapp Speaking Experience Dashboard)
/// ═══════════════════════════════════════════════════════════════
class SpeakingSessionsTabView extends ConsumerWidget {
  const SpeakingSessionsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talksState = ref.watch(talksViewModelProvider);
    final talks = talksState.talks;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      children: [
        // 1. Webapp Prompt Banner: Feedback QR Codes for Your Talks
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F110B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryAccent.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_rounded,
                  color: AppTheme.primaryAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feedback QR Codes for Your Talks',
                      style: AppTheme.font(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Every talk you add generates a unique QR code. Add it to your slides and let attendees scan in seconds.',
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Section Header with "New Talk" Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Speaking Experiences',
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                AddTalkModal.show(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.black, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Add Talk',
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

        const SizedBox(height: 14),

        // 3. Speaking Sessions Cards
        ...talks.map((talk) => _buildTalkCard(context, ref, talk)),
      ],
    );
  }

  Widget _buildTalkCard(BuildContext context, WidgetRef ref, SpeakingTalk talk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F110B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: talk.isLive
              ? AppTheme.primaryAccent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          if (talk.isLive)
            BoxShadow(
              color: AppTheme.primaryAccent.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: -2,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Cover Banner (styled after Image 2 preview)
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: talk.coverGradient,
              ),
            ),
            child: Stack(
              children: [
                // Decorative concentric arcs
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            talk.eventName,
                            style: AppTheme.font(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (talk.isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                border: Border.all(color: AppTheme.successGreen),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.successGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'LIVE NOW',
                                    style: AppTheme.font(
                                      color: AppTheme.successGreen,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        talk.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details & Meta
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppTheme.textMuted,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      talk.eventDate,
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (talk.reviewsCount > 0) ...[
                      const Icon(Icons.star_rounded, color: AppTheme.starGold, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${talk.rating}/10',
                        style: AppTheme.font(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' (${talk.reviewsCount} reviews)',
                        style: AppTheme.font(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  talk.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons: Present QR Code & View Feedback
                Row(
                  children: [
                    // Present QR Code (Primary neon lime pill button)
                    Expanded(
                      flex: 6,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          TalkQrCodeModal.show(context, talk);
                        },
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent,
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.qr_code_2_rounded,
                                color: Colors.black,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Present QR Code',
                                style: AppTheme.font(
                                  color: Colors.black,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // View Feedbacks Button
                    Expanded(
                      flex: 5,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // Filter feedback by this talk and switch to Feedback tab
                          ref.read(talksViewModelProvider.notifier).setFilterTalkId(talk.id);
                          ref.read(talksViewModelProvider.notifier).setSelectedTab(0);
                        },
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF161811),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppTheme.textPrimary,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Feedbacks',
                                style: AppTheme.font(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
