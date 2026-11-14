import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/app_network_image.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// More Upcoming Events Section
/// Pixel-Perfect match to Figma reference design (uploaded_media_0)
/// Featuring a vibrant top card in lime/yellow and sleek dark cards below.
/// ═══════════════════════════════════════════════════════════════
class MoreUpcomingEventsSection extends StatelessWidget {
  final List<EventItem> events;
  final ValueChanged<EventItem> onEventTap;
  final VoidCallback onSeeAllTap;
  final int maxItems;

  const MoreUpcomingEventsSection({
    super.key,
    required this.events,
    required this.onEventTap,
    required this.onSeeAllTap,
    this.maxItems = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    // Show top preview events (8 by default) so the feed stays clean and "See all" is purposeful
    final displayEvents = events.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'More Upcoming Events',
                style: AppTheme.font(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSeeAllTap();
                },
                child: Text(
                  'See all',
                  style: AppTheme.font(
                    color: AppTheme.primaryAccent,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // List of Upcoming Cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayEvents.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final event = displayEvents[index];
            final isHighlighted = index == 0;

            return _UpcomingEventCard(
              event: event,
              isHighlighted: isHighlighted,
              onTap: () {
                HapticFeedback.lightImpact();
                onEventTap(event);
              },
            );
          },
        ),
      ],
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  final EventItem event;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _UpcomingEventCard({
    required this.event,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Theme colors according to Figma reference
    const highlightedBg = Color(0xFFE2F835); // Radiant neon lime/yellow
    const darkBg = Color(0xFF161618); // Dark charcoal container
    const darkBorder = Color(0x1FFFFFFF);

    final bgColor = isHighlighted ? highlightedBg : darkBg;
    final primaryTextColor = isHighlighted ? const Color(0xFF0D0D0D) : Colors.white;
    final secondaryTextColor = isHighlighted ? const Color(0xCC0D0D0D) : const Color(0xFFA1A1AA);
    final metaColor = isHighlighted ? const Color(0xFF0D0D0D) : const Color(0xFF8E8E93);
    final dividerColor = isHighlighted ? const Color(0x330D0D0D) : const Color(0xFF333336);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: isHighlighted
            ? null
            : Border.all(color: darkBorder, width: 1),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFFE2F835).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top Row: Thumbnail + Titles + Arrow Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Square Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 52,
                        height: 52,
                        color: isHighlighted ? Colors.black12 : const Color(0xFF242426),
                        child: _buildThumbnail(event.imagePath),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.font(
                              color: primaryTextColor,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            event.subtitle.isNotEmpty
                                ? event.subtitle
                                : (event.description.isNotEmpty
                                    ? event.description
                                    : 'Live Sessions & Masterclasses'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.font(
                              color: secondaryTextColor,
                              fontSize: 13,
                              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Top-right Diagonal Arrow Icon Button
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? Colors.black.withValues(alpha: 0.08)
                            : const Color(0xFF26262A),
                        shape: BoxShape.circle,
                        border: isHighlighted
                            ? null
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                                width: 1,
                              ),
                      ),
                      child: Icon(
                        Icons.north_east_rounded,
                        color: primaryTextColor,
                        size: 17,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom Row: Time | Location
                Row(
                  children: [
                    // Clock + Time
                    Icon(
                      Icons.access_time_rounded,
                      size: 14.5,
                      color: metaColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      event.time.isNotEmpty ? event.time : '08:00 AM',
                      style: AppTheme.font(
                        color: metaColor,
                        fontSize: 12,
                        fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),

                    const SizedBox(width: 8),
                    Text(
                      '|',
                      style: AppTheme.font(
                        color: dividerColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Pin + Location
                    Icon(
                      Icons.location_on_outlined,
                      size: 14.5,
                      color: metaColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          color: metaColor,
                          fontSize: 12,
                          fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String path) {
    return AppNetworkImage(
      imageUrl: path,
      fit: BoxFit.cover,
      errorWidget: const Center(
        child: Icon(
          Icons.event_seat_rounded,
          color: Colors.white54,
          size: 24,
        ),
      ),
    );
  }
}
