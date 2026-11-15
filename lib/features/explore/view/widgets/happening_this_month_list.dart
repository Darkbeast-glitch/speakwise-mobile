import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/app_network_image.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// Dynamic Event Spotlight List Component
/// "Happening This Month" or "Cool to Attend" + Horizontal Cards
/// ═══════════════════════════════════════════════════════════════
class HappeningThisMonthList extends StatelessWidget {
  final String title;
  final List<EventItem> events;
  final ValueChanged<EventItem>? onEventTap;
  final VoidCallback? onSeeAllTap;

  const HappeningThisMonthList({
    super.key,
    this.title = 'Happening This Month',
    required this.events,
    this.onEventTap,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
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

        // 2. Horizontal Cards List
        SizedBox(
          height: 205,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final event = events[index];

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onEventTap?.call(event);
                },
                child: Container(
                  width: 155,
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
                        // Background Photo
                        AppNetworkImage(
                          imageUrl: event.imagePath,
                          fit: BoxFit.cover,
                        ),

                        // Bottom Dark Gradient Overlay for legibility
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.35, 0.75, 1.0],
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.75),
                                  Colors.black.withValues(alpha: 0.95),
                                ],
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
                              Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.font(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event.date,
                                style: AppTheme.font(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Small Neon Lime "View" Pill
                              Container(
                                height: 24,
                                width: 58,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryAccent,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusPill),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'View',
                                  style: AppTheme.font(
                                    color: Colors.black,
                                    fontSize: 10.5,
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
}
