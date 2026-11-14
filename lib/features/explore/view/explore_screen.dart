import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/widgets.dart';
import 'package:speakwise_mobile/features/explore/explore.dart';
import 'package:speakwise_mobile/features/profile/profile.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen 2: Explore & Events Screen
/// Fully Dynamic Feed with Live Backend Data via Riverpod:
/// - Real-time "Discover" Search
/// - Filter Sheet (Time Period, Admission, CFP, Country)
/// - Interactive Category Chips (Africa, Europe, America, Asia)
/// - Happening This Month (Date-aware from API)
/// - Top Keynote Speakers
/// - More Upcoming Events (Tappable with detail navigation)
/// ═══════════════════════════════════════════════════════════════
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet(dynamic exploreState) {
    HapticFeedback.lightImpact();
    EventFilterSheet.show(
      context: context,
      initialTimePeriod: exploreState.selectedTimePeriod,
      initialAdmission: exploreState.selectedAdmission,
      initialCfpOpenOnly: exploreState.isCfpOpenOnly,
      initialCountry: exploreState.selectedCountry,
      availableCountries: exploreState.availableCountries,
      onApply:
          ({
            required String timePeriod,
            required String admission,
            required bool cfpOpenOnly,
            required String country,
          }) {
            ref
                .read(exploreViewModelProvider.notifier)
                .applyFilters(
                  timePeriod: timePeriod,
                  admission: admission,
                  cfpOpenOnly: cfpOpenOnly,
                  country: country,
                );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreViewModelProvider);
    final userProfile = ref.watch(profileViewModelProvider).profile;

    final isFeedLoading =
        (exploreState.status == ExploreStatus.loading ||
            exploreState.status == ExploreStatus.initial) &&
        exploreState.allEvents.isEmpty;

    final featuredEvents = exploreState.featuredEvents;
    final featuredEvent = exploreState.featuredEvent;
    final monthlyEvents = exploreState.monthlyEvents;
    final monthlySectionTitle = exploreState.monthlySectionTitle;
    final topSpeakers = exploreState.topSpeakers;
    final upcomingEvents = exploreState.upcomingEvents;

    final userName = userProfile.firstName.isNotEmpty
        ? '${userProfile.firstName} ${userProfile.lastName}'.trim()
        : (userProfile.username.isNotEmpty ? userProfile.username : 'Speaker');
    final userAvatar = userProfile.avatarPath.isNotEmpty
        ? userProfile.avatarPath
        : null;

    final hasActiveFilters =
        exploreState.selectedTimePeriod != 'All' ||
        exploreState.selectedAdmission != 'All' ||
        exploreState.isCfpOpenOnly ||
        exploreState.selectedCountry != 'All';

    final isSearching = exploreState.searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppTheme.primaryAccent,
          backgroundColor: AppTheme.surfaceDark,
          onRefresh: () async {
            await ref.read(exploreViewModelProvider.notifier).loadExploreFeed();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Real User Avatar • "Welcome Back / [UserName]" • Bell
                ExploreHeader(
                  userName: userName,
                  avatarPath: userAvatar,
                  onNotificationTap: () {},
                  onAvatarTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/shell?tab=3');
                  },
                ),

                // 2. Stadium "Discover" Search Field + Filter Button
                SearchFilterBar(
                  controller: _searchController,
                  hasActiveFilters: hasActiveFilters,
                  onChanged: (val) {
                    ref
                        .read(exploreViewModelProvider.notifier)
                        .searchEvents(val);
                  },
                  onClear: () {
                    ref.read(exploreViewModelProvider.notifier).clearSearch();
                  },
                  onFilterTap: () => _openFilterSheet(exploreState),
                ),

                // Active Filters Chip Indicator
                if (hasActiveFilters) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Filtered by: ',
                          style: AppTheme.font(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (exploreState.selectedTimePeriod != 'All')
                          _buildFilterBadge(exploreState.selectedTimePeriod),
                        if (exploreState.selectedAdmission != 'All')
                          _buildFilterBadge(exploreState.selectedAdmission),
                        if (exploreState.isCfpOpenOnly)
                          _buildFilterBadge('CFP Open'),
                        if (exploreState.selectedCountry != 'All')
                          _buildFilterBadge(exploreState.selectedCountry),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(exploreViewModelProvider.notifier)
                                .resetFilters();
                          },
                          child: Text(
                            'Clear',
                            style: AppTheme.font(
                              color: AppTheme.primaryAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 3. Search Results Mode (When user is searching)
                if (isSearching) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search Results',
                          style: AppTheme.font(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '${exploreState.searchResults.length} found',
                          style: AppTheme.font(
                            color: AppTheme.primaryAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (exploreState.isSearching) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryAccent,
                        ),
                      ),
                    ),
                  ] else if (exploreState.searchResults.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 40,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              color: AppTheme.textMuted,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No events found for "${exploreState.searchQuery}"',
                              textAlign: TextAlign.center,
                              style: AppTheme.font(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try checking spelling or adjusting your search filters.',
                              textAlign: TextAlign.center,
                              style: AppTheme.font(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: exploreState.searchResults.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemBuilder: (context, index) {
                        final event = exploreState.searchResults[index];
                        return _buildSearchResultCard(context, event);
                      },
                    ),
                  ],
                ] else if (isFeedLoading) ...[
                  // Shimmer loading skeleton while fetching real data from API (no dummy data flashing!)
                  const ExploreFeedShimmer(),
                ] else ...[
                  // 4. Normal Feed: Categories horizontal chips
                  CategoryChipsList(
                    categories: EventsData.categories,
                    selectedCategoryId: exploreState.selectedCategoryId,
                    onCategorySelected: (id) {
                      ref
                          .read(exploreViewModelProvider.notifier)
                          .selectCategory(id);
                    },
                    onSeeAllTap: () {
                      HapticFeedback.lightImpact();
                      context.push(
                        '/events/all?category=${exploreState.selectedCategoryId}',
                      );
                    },
                  ),

                  // 5. "Top Featured Event" Section Card / Carousel (only when featured events exist from API)
                  if (featuredEvents.isNotEmpty || featuredEvent != null)
                    FeaturedEventCard(
                      events: featuredEvents,
                      event: featuredEvent,
                      onBuyTicketTap: (event) {
                        HapticFeedback.lightImpact();
                        context.push('/event/${event.id}', extra: event);
                      },
                      onViewEventTap: (event) {
                        HapticFeedback.lightImpact();
                        context.push('/event/${event.id}', extra: event);
                      },
                    ),

                  // 6. "Happening This Month" or "Cool to Attend" (only when real events exist from API)
                  if (monthlyEvents.isNotEmpty)
                    HappeningThisMonthList(
                      title: monthlySectionTitle,
                      events: monthlyEvents,
                      onEventTap: (event) {
                        HapticFeedback.lightImpact();
                        context.push('/event/${event.id}', extra: event);
                      },
                      onSeeAllTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/events/all');
                      },
                    ),

                  // 7. "Top Keynote Speakers" (only when real speakers exist from API)
                  if (topSpeakers.isNotEmpty)
                    FeaturedSpeakersSection(
                      speakers: topSpeakers,
                      onSpeakerTap: (speaker) {
                        HapticFeedback.lightImpact();
                        context.push('/speaker/${speaker.id}');
                      },
                      onSeeAllTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/events/all');
                      },
                    ),

                  // 8. "More Upcoming Events" (only when upcoming events exist from API)
                  if (upcomingEvents.isNotEmpty)
                    MoreUpcomingEventsSection(
                      events: upcomingEvents,
                      onEventTap: (event) {
                        HapticFeedback.lightImpact();
                        context.push('/event/${event.id}', extra: event);
                      },
                      onSeeAllTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/events/all');
                      },
                    ),

                  // Empty State if no events were returned at all from API
                  if (featuredEvents.isEmpty &&
                      featuredEvent == null &&
                      monthlyEvents.isEmpty &&
                      upcomingEvents.isEmpty &&
                      topSpeakers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 48,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.event_busy_rounded,
                              color: AppTheme.textMuted,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No events available yet',
                              style: AppTheme.font(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Check back soon or pull down to refresh.',
                              style: AppTheme.font(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],

                // 9. Clearance padding for Floating Bottom Nav Bar
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBadge(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2418),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.primaryAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: AppTheme.font(
          color: AppTheme.primaryAccent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(BuildContext context, EventItem event) {
    final isFree = event.isFree == true || !event.isTicketed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/event/${event.id}', extra: event);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: AppNetworkImage(
                      imageUrl: event.imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.font(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isFree
                                  ? const Color(0xFF1B2813)
                                  : const Color(0xFF281E13),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isFree ? 'Free' : 'Ticketed',
                              style: AppTheme.font(
                                color: isFree
                                    ? AppTheme.primaryAccent
                                    : const Color(0xFFFFB74D),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.textMuted,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.font(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppTheme.textMuted,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.date,
                            style: AppTheme.font(
                              color: AppTheme.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textMuted,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
