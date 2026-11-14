import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// Explore Section: Trending Keynotes & Talks
/// Real-time incoming feedback & stage presentation cards
/// ═══════════════════════════════════════════════════════════════
class TrendingSessionsSection extends StatelessWidget {
  final List<TrendingSession> sessions;
  final ValueChanged<TrendingSession>? onSessionTap;
  final VoidCallback? onLiveFeedTap;

  const TrendingSessionsSection({
    super.key,
    required this.sessions,
    this.onSessionTap,
    this.onLiveFeedTap,
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
                'Trending Speaking Sessions',
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
                  onLiveFeedTap?.call();
                },
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live Feed',
                      style: AppTheme.font(
                        color: AppTheme.primaryAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Vertical Cards List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: sessions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final session = sessions[index];

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onSessionTap?.call(session);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Time & Event
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent.withValues(alpha: 0.14),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            session.time,
                            style: AppTheme.font(
                              color: AppTheme.primaryAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.eventTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.font(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.bookmark_border_rounded,
                          color: AppTheme.textMuted,
                          size: 18,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Session Title
                    Text(
                      session.title,
                      style: AppTheme.font(
                        color: AppTheme.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Speaker Row & Tags
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.surfaceDark,
                          backgroundImage: AssetImage(session.speakerAvatar),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          session.speakerName,
                          style: AppTheme.font(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          color: AppTheme.starGold,
                          size: 13,
                        ),
                        Text(
                          '${session.rating}',
                          style: AppTheme.font(
                            color: AppTheme.starGold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Scan QR',
                            style: AppTheme.font(
                              color: AppTheme.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
