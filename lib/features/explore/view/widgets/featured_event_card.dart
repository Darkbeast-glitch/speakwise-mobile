import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/app_network_image.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// Top Featured Event Card & Auto-Swiping Carousel Component
/// Displays all events with is_featured=True in a sleek, swipeable
/// hero carousel with automatic timer transitions and dot indicator.
/// ═══════════════════════════════════════════════════════════════
class FeaturedEventCard extends StatefulWidget {
  final List<EventItem>? events;
  final EventItem? event;
  final void Function(EventItem event)? onBuyTicketTap;
  final void Function(EventItem event)? onViewEventTap;

  const FeaturedEventCard({
    super.key,
    this.events,
    this.event,
    this.onBuyTicketTap,
    this.onViewEventTap,
  });

  @override
  State<FeaturedEventCard> createState() => _FeaturedEventCardState();
}

class _FeaturedEventCardState extends State<FeaturedEventCard> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSwipeTimer;
  bool _isUserInteracting = false;

  List<EventItem> get _items {
    if (widget.events != null && widget.events!.isNotEmpty) {
      return widget.events!;
    }
    if (widget.event != null) {
      return [widget.event!];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSwipeTimer();
  }

  void _startAutoSwipeTimer() {
    _autoSwipeTimer?.cancel();
    if (_items.length <= 1) return;

    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _isUserInteracting || !_pageController.hasClients) return;
      final count = _items.length;
      if (count <= 1) return;
      final nextIndex = (_currentPage + 1) % count;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant FeaturedEventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLen =
        oldWidget.events?.length ?? (oldWidget.event != null ? 1 : 0);
    final newLen = _items.length;
    if (oldLen != newLen) {
      _startAutoSwipeTimer();
    }
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Section Title & Swipe Indicators
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Featured Event',
                style: AppTheme.font(
                  color: AppTheme.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),

              // Page Indicator Dots if multiple featured events exist
              if (items.length > 1)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(items.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primaryAccent
                            : Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),

        // 2. Carousel / Single Card
        if (items.length == 1)
          _buildCard(items[0])
        else
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isUserInteracting = true;
              } else if (notification is ScrollEndNotification) {
                _isUserInteracting = false;
              }
              return false;
            },
            child: SizedBox(
              height: 368,
              child: PageView.builder(
                controller: _pageController,
                itemCount: items.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: _buildCard(items[index]),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(EventItem event) {
    final isFree = event.isFree == true || !event.isTicketed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Image with Date and Ticketed Badges
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 168,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onViewEventTap?.call(event);
                    },
                    child: AppNetworkImage(
                      imageUrl: event.imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Top-Left Circular Date Badge (White circle)
                  if (event.dateBadgeMonth != null &&
                      event.dateBadgeDay != null)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              event.dateBadgeMonth!,
                              style: AppTheme.font(
                                color: Colors.black87,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              event.dateBadgeDay!,
                              style: AppTheme.font(
                                color: Colors.black,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Top-Right Badge ("Featured" or "Ticketed" / "Free")
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (event.isFeatured)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAccent,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusPill,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryAccent.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.black,
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Featured',
                                  style: AppTheme.font(
                                    color: Colors.black,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusPill,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isFree ? 'Free' : 'Ticketed',
                            style: AppTheme.font(
                              color: isFree
                                  ? AppTheme.primaryAccent
                                  : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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

          const SizedBox(height: 10),

          // Event Title
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onViewEventTap?.call(event);
            },
            child: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Full Date Row with Calendar Icon
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.primaryAccent,
                size: 13.5,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Full Location Row (City + Country) with Pin Icon
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppTheme.textMuted,
                size: 13.5,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.fullLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),

          // Short Bio / Description Preview (2 lines max with ellipsis)
          if (event.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              event.description.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.font(
                color: AppTheme.textMuted.withValues(alpha: 0.85),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Two Action Buttons: "Buy Ticket" & "View Event"
          Row(
            children: [
              // Buy Ticket (Dark with subtle border)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: Material(
                    color: const Color(0xFF181818),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onBuyTicketTap?.call(event);
                      },
                      child: Center(
                        child: Text(
                          isFree ? 'RSVP Free' : 'Buy Ticket',
                          style: AppTheme.font(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // View Event (Electric Neon Lime)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: Material(
                    color: AppTheme.primaryAccent,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onViewEventTap?.call(event);
                      },
                      child: Center(
                        child: Text(
                          'View Event',
                          style: AppTheme.font(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
