import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/services/cache_manager.dart';
import 'package:speakwise_mobile/features/explore/data/events_repository.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';
import 'package:speakwise_mobile/features/explore/viewmodel/explore_state.dart';

class ExploreViewModel extends StateNotifier<ExploreState> {
  final EventsRepository _repository;
  final CacheManager _cacheManager;

  bool _isFetching = false;
  Future<void>? _inFlightFetch;

  static const String _cacheKey = 'explore_feed_cache';

  ExploreViewModel(this._repository, this._cacheManager)
      : super(const ExploreState()) {
    // 1. Instant 0ms Screen Load from local cache
    _restoreFromCache();
    // 2. Revalidate in the background
    loadExploreFeed();
  }

  /// 0ms Instant Cache Restoration
  void _restoreFromCache() {
    try {
      final cached = _cacheManager.getJsonMap(_cacheKey);
      if (cached != null) {
        final allEventsRaw = (cached['allEvents'] as List?) ?? [];
        final featuredEventsRaw = (cached['featuredEvents'] as List?) ?? [];
        final monthlyEventsRaw = (cached['monthlyEvents'] as List?) ?? [];
        final upcomingEventsRaw = (cached['upcomingEvents'] as List?) ?? [];
        final topSpeakersRaw = (cached['topSpeakers'] as List?) ?? [];
        final countriesRaw = (cached['availableCountries'] as List?) ?? [];

        final allEvents = allEventsRaw
            .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final featuredEvents = featuredEventsRaw
            .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final monthlyEvents = monthlyEventsRaw
            .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final upcomingEvents = upcomingEventsRaw
            .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final topSpeakers = topSpeakersRaw
            .map((s) => EventSpeaker.fromJson(s as Map<String, dynamic>))
            .toList();
        final availableCountries = countriesRaw.map((c) => c.toString()).toList();

        final featuredEvent =
            featuredEvents.isNotEmpty ? featuredEvents.first : null;
        final monthlySectionTitle =
            cached['monthlySectionTitle']?.toString() ?? 'Happening This Month';

        if (allEvents.isNotEmpty || topSpeakers.isNotEmpty) {
          state = state.copyWith(
            status: ExploreStatus.success,
            allEvents: allEvents,
            featuredEvents: featuredEvents,
            featuredEvent: featuredEvent,
            monthlyEvents: monthlyEvents,
            monthlySectionTitle: monthlySectionTitle,
            upcomingEvents: upcomingEvents,
            topSpeakers: topSpeakers,
            availableCountries: availableCountries,
          );
          debugPrint('⚡ Explore feed restored instantly from disk (0ms)');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error restoring explore feed from cache: $e');
    }
  }

  /// Stale-While-Revalidate Feed Loader with Debounce & Request Coalescing
  Future<void> loadExploreFeed({bool force = false}) async {
    // 1. Debounce: If a network request is already running, coalesce into it
    if (_isFetching && _inFlightFetch != null) {
      debugPrint('🔄 Explore feed fetch already in flight. Joining existing request.');
      return _inFlightFetch!;
    }

    // 2. Throttling: Do not hit server if data was fetched < 25s ago unless forced
    final hasExistingData = state.allEvents.isNotEmpty;
    if (!force && hasExistingData && _cacheManager.isFresh(_cacheKey, maxAge: const Duration(seconds: 25))) {
      debugPrint('⚡ Explore feed data is fresh (< 25s). Skipping network hit.');
      return;
    }

    _isFetching = true;
    _inFlightFetch = _executeFetch(force: force);

    try {
      await _inFlightFetch;
    } finally {
      _isFetching = false;
      _inFlightFetch = null;
    }
  }

  Future<void> _executeFetch({bool force = false}) async {
    // Only show loading spinner if we have NO cached data to display
    if (state.allEvents.isEmpty) {
      state = state.copyWith(status: ExploreStatus.loading);
    }

    try {
      final region = state.selectedCategoryId == 'all' ? null : state.selectedCategoryId;
      final timePeriod = state.selectedTimePeriod == 'All'
          ? null
          : state.selectedTimePeriod.toLowerCase();
      final isFree = state.selectedAdmission == 'All'
          ? null
          : (state.selectedAdmission == 'Free');
      final cfpOpen = state.isCfpOpenOnly ? true : null;
      final country = state.selectedCountry == 'All' ? null : state.selectedCountry;

      // 3. Stop Multiple Sequential Screen Calls on Startup:
      // Execute required network calls in parallel using Future.wait
      final results = await Future.wait([
        _repository.getEvents(
          region: region,
          timePeriod: timePeriod,
          isFree: isFree,
          cfpOpen: cfpOpen,
          country: country,
        ),
        _repository.getTopSpeakers(top: true),
        _repository.getFeaturedEvents(),
      ]);

      final events = results[0] as List<EventItem>;
      final speakers = results[1] as List<EventSpeaker>;
      final featuredList = results[2] as List<EventItem>;

      final now = DateTime.now();

      // 4. In-Memory Derivation for Monthly Events (Zero extra network round-trips)
      List<EventItem> monthly = events.where((e) {
        if (e.startDateTime != null) {
          return e.startDateTime!.year == now.year && e.startDateTime!.month == now.month;
        }
        return false;
      }).toList();

      String monthlySectionTitle = 'Happening This Month';
      List<EventItem> displayMonthlyEvents = monthly;

      if (monthly.length < 5) {
        monthlySectionTitle = 'Cool to Attend';
        displayMonthlyEvents = _pickCoolToAttendEvents(
          backendEvents: events.take(5).toList(),
          now: now,
        );
      }

      // 5. In-Memory Derivation for Upcoming Events
      List<EventItem> upcoming = events.where((e) {
        if (e.startDateTime != null) {
          return e.startDateTime!.isAfter(now.subtract(const Duration(hours: 12)));
        }
        return true;
      }).toList();

      if (upcoming.isEmpty && events.isNotEmpty) {
        upcoming = events;
      }

      // 6. Featured Event
      final featured = featuredList.isNotEmpty
          ? featuredList.first
          : (events.where((e) => e.isFeatured).firstOrNull ?? (events.isNotEmpty ? events.first : null));

      // 7. Available Countries
      final countriesSet = <String>{};
      for (final ev in events) {
        if (ev.country != null && ev.country!.trim().isNotEmpty) {
          countriesSet.add(ev.country!.trim());
        }
      }
      final availableCountries = countriesSet.toList()..sort();

      // 8. Update UI State smoothly
      state = state.copyWith(
        status: ExploreStatus.success,
        allEvents: events,
        featuredEvents: featuredList.isNotEmpty ? featuredList : (featured != null ? [featured] : []),
        featuredEvent: featured,
        monthlyEvents: displayMonthlyEvents,
        monthlySectionTitle: monthlySectionTitle,
        upcomingEvents: upcoming,
        topSpeakers: speakers,
        availableCountries: availableCountries,
      );

      // 9. Persist to cache (if on main unfiltered feed)
      if (region == null && timePeriod == null && isFree == null && cfpOpen == null && country == null) {
        await _cacheManager.put(_cacheKey, {
          'allEvents': events.map((e) => e.toJson()).toList(),
          'featuredEvents': featuredList.map((e) => e.toJson()).toList(),
          'monthlyEvents': displayMonthlyEvents.map((e) => e.toJson()).toList(),
          'monthlySectionTitle': monthlySectionTitle,
          'upcomingEvents': upcoming.map((e) => e.toJson()).toList(),
          'topSpeakers': speakers.map((s) => s.toJson()).toList(),
          'availableCountries': availableCountries,
        });
      }
    } catch (e) {
      debugPrint('⚠️ Explore feed fetch error: $e');
      // If we already have cached content, do NOT destroy the UI with an error screen!
      if (state.allEvents.isEmpty) {
        state = state.copyWith(
          status: ExploreStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  /// Selects the 5 events from real backend data
  List<EventItem> _pickCoolToAttendEvents({
    required List<EventItem> backendEvents,
    required DateTime now,
  }) {
    if (backendEvents.isNotEmpty) {
      final upcoming = <EventItem>[];
      final others = <EventItem>[];

      for (final ev in backendEvents) {
        if (ev.startDateTime != null &&
            ev.startDateTime!.isAfter(now.subtract(const Duration(hours: 12)))) {
          upcoming.add(ev);
        } else {
          others.add(ev);
        }
      }

      upcoming.sort((a, b) => a.startDateTime!.compareTo(b.startDateTime!));

      final result = <EventItem>[...upcoming, ...others];
      return result.take(5).toList();
    }

    return [];
  }

  void selectCategory(String categoryId) {
    if (state.selectedCategoryId == categoryId) return;
    state = state.copyWith(selectedCategoryId: categoryId);
    loadExploreFeed(force: true);
  }

  Future<void> searchEvents(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        searchResults: const [],
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(
      searchQuery: cleanQuery,
      isSearching: true,
    );

    try {
      final results = await _repository.getEvents(search: cleanQuery);
      state = state.copyWith(
        searchResults: results,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        searchResults: const [],
        isSearching: false,
      );
    }
  }

  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      searchResults: const [],
      isSearching: false,
    );
  }

  void applyFilters({
    String? timePeriod,
    String? admission,
    bool? cfpOpenOnly,
    String? country,
  }) {
    state = state.copyWith(
      selectedTimePeriod: timePeriod ?? state.selectedTimePeriod,
      selectedAdmission: admission ?? state.selectedAdmission,
      isCfpOpenOnly: cfpOpenOnly ?? state.isCfpOpenOnly,
      selectedCountry: country ?? state.selectedCountry,
    );
    loadExploreFeed(force: true);
  }

  void resetFilters() {
    state = state.copyWith(
      selectedTimePeriod: 'All',
      selectedAdmission: 'All',
      isCfpOpenOnly: false,
      selectedCountry: 'All',
    );
    loadExploreFeed(force: true);
  }

  /// Sort and filter speakers using backend ordering and ranking parameters:
  /// - top: true (Bayesian compound reputation ranking, zero-activity filtered)
  /// - ordering: '-talks_count', '-reputation', '-rating', '-followers'
  Future<void> sortSpeakers({bool top = true, String? ordering}) async {
    try {
      final speakers = await _repository.getTopSpeakers(
        top: top,
        ordering: ordering,
      );
      if (speakers.isNotEmpty) {
        state = state.copyWith(topSpeakers: speakers);
      }
    } catch (_) {}
  }
}
