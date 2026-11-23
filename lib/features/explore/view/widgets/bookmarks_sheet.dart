import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/core/widgets/user_avatar.dart';
import 'package:speakwise_mobile/features/explore/data/events_repository.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';
import 'package:speakwise_mobile/features/explore/viewmodel/explore_viewmodel.dart';

/// ═══════════════════════════════════════════════════════════════
/// Bookmarks & Saved Shortlist Bottom Sheet
/// Dual tabs: "Saved Events" & "Favorite Speakers"
/// ═══════════════════════════════════════════════════════════════
class BookmarksSheet extends ConsumerStatefulWidget {
  const BookmarksSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BookmarksSheet(),
    );
  }

  @override
  ConsumerState<BookmarksSheet> createState() => _BookmarksSheetState();
}

class _BookmarksSheetState extends ConsumerState<BookmarksSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EventItem> _allLoadedEvents = [];
  List<EventSpeaker> _allLoadedSpeakers = [];
  bool _isLoadingExtra = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final exploreState = ref.read(exploreViewModelProvider);
    _allLoadedEvents = List.from(exploreState.allEvents);
    _allLoadedSpeakers = List.from(exploreState.topSpeakers);

    // If lists are sparse, fetch all from repository in background
    if (_allLoadedEvents.isEmpty || _allLoadedSpeakers.isEmpty) {
      setState(() => _isLoadingExtra = true);
      try {
        final repo = ref.read(eventsRepositoryProvider);
        final results = await Future.wait([
          if (_allLoadedEvents.isEmpty) repo.getEvents(limit: 60) else Future.value(<EventItem>[]),
          if (_allLoadedSpeakers.isEmpty) repo.getSpeakers(pageSize: 40) else Future.value(<EventSpeaker>[]),
        ]);

        if (mounted) {
          setState(() {
            if (results[0].isNotEmpty) {
              final newEvents = results[0] as List<EventItem>;
              final existingIds = _allLoadedEvents.map((e) => e.id).toSet();
              _allLoadedEvents.addAll(newEvents.where((e) => !existingIds.contains(e.id)));
            }
            if (results.length > 1 && results[1].isNotEmpty) {
              final newSpeakers = results[1] as List<EventSpeaker>;
              final existingIds = _allLoadedSpeakers.map((s) => s.id).toSet();
              _allLoadedSpeakers.addAll(newSpeakers.where((s) => !existingIds.contains(s.id)));
            }
            _isLoadingExtra = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingExtra = false);
      }
    }
  }

  void _removeEventBookmark(String eventId) async {
    HapticFeedback.lightImpact();
    final storage = ref.read(storageServiceProvider);
    await storage.toggleEventBookmark(eventId);
    setState(() {});
  }

  void _removeSpeakerFavorite(String speakerKey) async {
    HapticFeedback.lightImpact();
    final storage = ref.read(storageServiceProvider);
    await storage.toggleFavoriteSpeaker(speakerKey);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final bookmarkedIds = storage.bookmarkedEventIds;
    final favoriteSpeakerKeys = storage.favoriteSpeakerIds;

    // Filter matching events
    final savedEvents = _allLoadedEvents.where((e) {
      return bookmarkedIds.contains(e.id) ||
          bookmarkedIds.contains(e.slug) ||
          bookmarkedIds.contains(e.title.toLowerCase().trim());
    }).toList();

    // Filter matching speakers
    final savedSpeakers = _allLoadedSpeakers.where((s) {
      return favoriteSpeakerKeys.contains(s.id) ||
          (s.slug != null && favoriteSpeakerKeys.contains(s.slug)) ||
          favoriteSpeakerKeys.contains(s.name.toLowerCase().trim());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F110B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        0,
        14,
        0,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Header: Title + Close Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.bookmark_rounded,
                          color: AppTheme.primaryAccent,
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bookmarks & Saved',
                      style: AppTheme.font(
                        color: Colors.white,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E211A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Tab Bar: Events vs Speakers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF161814),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryAccent,
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: AppTheme.font(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTheme.font(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Events'),
                        if (savedEvents.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${savedEvents.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Favorite Speakers'),
                        if (savedSpeakers.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${savedSpeakers.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 4. Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Bookmarked Events
                _buildEventsTab(savedEvents, bookmarkedIds),

                // TAB 2: Favorite Speakers
                _buildSpeakersTab(savedSpeakers, favoriteSpeakerKeys),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(List<EventItem> events, Set<String> bookmarkedIds) {
    if (events.isEmpty && !_isLoadingExtra) {
      return _buildEmptyState(
        icon: Icons.event_note_rounded,
        title: 'No Bookmarked Events',
        description:
            'Tap the heart icon on any event to save it here for quick access later.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(EventItem event) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        context.push('/event-details', extra: event);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141612),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: event.bannerImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: event.bannerImage,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFF1F221A),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFF1F221A),
                          child: const Icon(
                            Icons.event_rounded,
                            color: Colors.white38,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF1F221A),
                        child: const Icon(
                          Icons.event_rounded,
                          color: Colors.white38,
                          size: 28,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 14),

            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Organizer / Location
                  Text(
                    event.organizer.isNotEmpty
                        ? event.organizer
                        : (event.city.isNotEmpty ? '${event.city}, ${event.country}' : 'Global Event'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Pills: Date & CFP
                  Row(
                    children: [
                      // Date pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F221A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: AppTheme.primaryAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.formattedDateRange.isNotEmpty
                                  ? event.formattedDateRange
                                  : 'Upcoming',
                              style: AppTheme.font(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (event.isCfpOpen) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.primaryAccent.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'CFP OPEN',
                            style: AppTheme.font(
                              color: AppTheme.primaryAccent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Remove Bookmark Heart Button
            GestureDetector(
              onTap: () => _removeEventBookmark(event.id),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3366).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF3366),
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakersTab(List<EventSpeaker> speakers, Set<String> favoriteKeys) {
    if (speakers.isEmpty && !_isLoadingExtra) {
      return _buildEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No Favorite Speakers',
        description:
            'Tap the heart icon on any speaker’s profile to save them to your speaker shortlist.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: speakers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final speaker = speakers[index];
        return _buildSpeakerCard(speaker);
      },
    );
  }

  Widget _buildSpeakerCard(EventSpeaker speaker) {
    final speakerKey = speaker.slug?.isNotEmpty == true
        ? speaker.slug!
        : (speaker.id.isNotEmpty ? speaker.id : speaker.name);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        context.push('/speaker-details/$speakerKey');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141612),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            // Speaker Avatar
            UserAvatar(
              name: speaker.name,
              avatarUrl: speaker.avatarPath,
              size: 52,
              showBorder: true,
              borderColor: AppTheme.primaryAccent.withValues(alpha: 0.4),
            ),

            const SizedBox(width: 14),

            // Speaker Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          speaker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.font(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (speaker.rankTier != null && speaker.rankTier!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            speaker.rankTier!.toUpperCase(),
                            style: AppTheme.font(
                              color: AppTheme.primaryAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),

                  Text(
                    speaker.role.isNotEmpty
                        ? speaker.role
                        : (speaker.topic.isNotEmpty ? speaker.topic : 'Keynote Speaker'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Rating and Talks row
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB800),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        speaker.rating.toStringAsFixed(1),
                        style: AppTheme.font(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${speaker.talksGiven} Talks Given',
                        style: AppTheme.font(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Shortlist Heart Button
            GestureDetector(
              onTap: () => _removeSpeakerFavorite(speakerKey),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4B6E).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF4B6E),
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF161814),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryAccent,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.font(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTheme.font(
                color: AppTheme.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
