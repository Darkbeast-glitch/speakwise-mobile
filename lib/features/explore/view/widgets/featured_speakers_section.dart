import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/app_network_image.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// Explore Section: Top Keynote Speakers
/// Horizontal Spotlights of Top Rated Keynote Speakers
/// Matches the card layout with speaker hero photo, Top Rated badge,
/// rating & talks & badges stats, and Neon Lime "View" button.
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
    if (speakers.isEmpty) {
      return const SizedBox.shrink();
    }

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
                'Top Speakers',
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
                  if (onSeeAllTap != null) {
                    onSeeAllTap!.call();
                  } else {
                    context.push('/speakers/all');
                  }
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
          height: 215,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: speakers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final speaker = speakers[index];
              final scoreText = speaker.reputationScore != null
                  ? speaker.reputationScore!.toStringAsFixed(1)
                  : speaker.rating.toStringAsFixed(1);
              final rankText =
                  (speaker.rankTier != null &&
                      speaker.rankTier!.trim().isNotEmpty)
                  ? speaker.rankTier!
                  : 'Top Rated';

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSpeakerTap?.call(speaker);
                },
                child: Container(
                  width: 160,
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
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Speaker Photo Background
                        _buildSpeakerPhoto(speaker),

                        // Dark Gradient Overlay for bottom text legibility
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.2, 0.55, 0.85, 1.0],
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.25),
                                  Colors.black.withValues(alpha: 0.75),
                                  Colors.black.withValues(alpha: 0.95),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Top-Right Pill Badge ("Top Rated")
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              rankText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.font(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Bottom Content Overlay
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Speaker Name
                              Text(
                                speaker.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.font(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),

                              // Star, Rating, Talks, Badges Row
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppTheme.starGold,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    scoreText,
                                    style: AppTheme.font(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${speaker.talksGiven} Talks',
                                    style: AppTheme.font(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${speaker.badgesCount} Badges',
                                    style: AppTheme.font(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),

                              // Spoke at X events
                              Text(
                                'Spoke at ${speaker.talksGiven} events',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.font(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Small Neon Lime "View" Pill Button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryAccent,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusPill,
                                  ),
                                ),
                                child: Text(
                                  'View',
                                  style: AppTheme.font(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakerPhoto(EventSpeaker speaker) {
    final avatar = speaker.avatarPath.trim();
    if (avatar.startsWith('assets/')) {
      return Image.asset(
        avatar,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallback(speaker.name),
      );
    }
    if (avatar.isNotEmpty) {
      return AppNetworkImage(
        imageUrl: avatar,
        fit: BoxFit.cover,
        placeholder: _buildFallback(speaker.name),
        errorWidget: _buildFallback(speaker.name),
      );
    }
    return _buildFallback(speaker.name);
  }

  Widget _buildFallback(String name) {
    String initials = '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials = parts[0]
          .substring(0, parts[0].length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return Container(
      color: const Color(0xFF1E1E22),
      child: Center(
        child: Text(
          initials,
          style: AppTheme.font(
            color: AppTheme.primaryAccent,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
