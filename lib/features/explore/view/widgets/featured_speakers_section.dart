import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/user_avatar.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// Explore Section: Featured Keynote Speakers
/// Horizontal Cards of Verified Speakers with Reputation Badges
/// ═══════════════════════════════════════════════════════════════
class FeaturedSpeakersSection extends StatelessWidget {
  final List<EventSpeaker> speakers;
  final ValueChanged<EventSpeaker>? onSpeakerTap;
  final VoidCallback? onSeeAllTap;

  const FeaturedSpeakersSection({
    super.key,
    required this.speakers,
    this.onSpeakerTap,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Keynote Speakers',
                style: AppTheme.font(
                  color: AppTheme.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSeeAllTap?.call();
                },
                child: Text(
                  'See all',
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Horizontal Speakers Carousel
        SizedBox(
          height: 175,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: speakers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final speaker = speakers[index];

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSpeakerTap?.call(speaker);
                },
                child: Container(
                  width: 154,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with verified badge
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          UserAvatar(
                            name: speaker.name,
                            avatarUrl: speaker.avatarPath,
                            size: 54,
                            showBorder: true,
                            borderColor: AppTheme.primaryAccent,
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 10,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Speaker Name
                      Text(
                        speaker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          color: AppTheme.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),

                      const SizedBox(height: 3),

                      // Rating & Talks count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.starGold,
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${speaker.rating}',
                            style: AppTheme.font(
                              color: AppTheme.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              ' • ${speaker.talksGiven} talks',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.font(
                                color: AppTheme.textMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Topic Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          speaker.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.font(
                            color: AppTheme.textMuted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
