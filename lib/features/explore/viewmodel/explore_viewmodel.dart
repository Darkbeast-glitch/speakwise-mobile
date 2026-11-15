import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/features/explore/data/events_repository.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';
import 'package:speakwise_mobile/features/explore/viewmodel/explore_state.dart';

class ExploreViewModel extends StateNotifier<ExploreState> {
  final EventsRepository _repository;

  ExploreViewModel(this._repository) : super(const ExploreState()) {
    loadExploreFeed();
  }

  Future<void> loadExploreFeed() async {
    state = state.copyWith(status: ExploreStatus.loading);
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

      // 1. Fetch category/filtered events
      final events = await _repository.getEvents(
        region: region,
        timePeriod: timePeriod,
        isFree: isFree,
        cfpOpen: cfpOpen,
        country: country,
      );

      // 2. Fetch all available real events from backend
      List<EventItem> allAvailable = [];
      try {
        allAvailable = await _repository.getEvents();
      } catch (_) {}

      // 3. Query for events Happening This Month
      final now = DateTime.now();
      List<EventItem> monthly = [];
      try {
        final monthApiEvents = await _repository.getEvents(timePeriod: 'this_month');
        if (monthApiEvents.isNotEmpty) {
          monthly = monthApiEvents;
        }
      } catch (_) {}

      // Fallback/refine: look for events with matching month & year from real backend events
      if (monthly.isEmpty && allAvailable.isNotEmpty) {
        monthly = allAvailable.where((e) {
          if (e.startDateTime != null) {
            return e.startDateTime!.year == now.year && e.startDateTime!.month == now.month;
          }
          return false;
        }).toList();
      }

      // 4. Section Title & Selection:
      // If events happening this month are fewer than 5, dynamically switch
      // section title to "Cool to Attend" and display the first 5 events from backend API.
      String monthlySectionTitle = 'Happening This Month';
      List<EventItem> displayMonthlyEvents = monthly;

      if (monthly.length < 5) {
        monthlySectionTitle = 'Cool to Attend';

        // Query the first 5 events directly from Django backend API
        List<EventItem> top5BackendEvents = [];
        try {
          top5BackendEvents = await _repository.getEvents(limit: 5);
        } catch (_) {}

        if (top5BackendEvents.isEmpty && allAvailable.isNotEmpty) {
          top5BackendEvents = allAvailable.take(5).toList();
        }
        if (top5BackendEvents.isEmpty && events.isNotEmpty) {
          top5BackendEvents = events.take(5).toList();
        }

        displayMonthlyEvents = _pickCoolToAttendEvents(
          backendEvents: top5BackendEvents,
          now: now,
        );
      }

      // 5. Upcoming events
      List<EventItem> upcoming = [];
      try {
        final upApi = await _repository.getEvents(
          region: region,
          timePeriod: 'upcoming',
        );
        if (upApi.isNotEmpty) {
          upcoming = upApi;
        }
      } catch (_) {}

      if (upcoming.isEmpty && allAvailable.isNotEmpty) {
        upcoming = allAvailable;
      }
      if (upcoming.isEmpty && allAvailable.isNotEmpty) {
        upcoming = allAvailable;
      }
      if (upcoming.isEmpty && events.isNotEmpty) {
        upcoming = events;
      }

      // 6. Top speakers (Bayesian reputation ranking)
      final speakers = await _repository.getTopSpeakers(top: true);

      // 7. Featured events (queried via ?is_featured=true)
      List<EventItem> featuredList = [];
      try {
        final featApi = await _repository.getFeaturedEvents();
        if (featApi.isNotEmpty) {
          featuredList = featApi;
        }
      } catch (_) {}

      if (featuredList.isEmpty && allAvailable.isNotEmpty) {
        featuredList = allAvailable.where((e) => e.isFeatured).toList();
      }
      if (featuredList.isEmpty && events.isNotEmpty) {
        featuredList = events.where((e) => e.isFeatured).toList();
      }
      if (featuredList.isEmpty && allAvailable.isNotEmpty) {
        featuredList = [allAvailable.first];
      }

      final featured = featuredList.isNotEmpty ? featuredList.first : null;

      // 8. Available countries list for filter dropdown
      final countriesSet = <String>{};
      final sourceForCountries = allAvailable.isNotEmpty ? allAvailable : events;
      for (final ev in sourceForCountries) {
        if (ev.country != null && ev.country!.trim().isNotEmpty) {
          countriesSet.add(ev.country!.trim());
        }
      }
      final availableCountries = countriesSet.toList()..sort();

      state = state.copyWith(
        status: ExploreStatus.success,
        allEvents: allAvailable.isNotEmpty ? allAvailable : events,
        featuredEvents: featuredList,
        featuredEvent: featured,
        monthlyEvents: displayMonthlyEvents,
        monthlySectionTitle: monthlySectionTitle,
        upcomingEvents: upcoming,
        topSpeakers: speakers,
        availableCountries: availableCountries,
      );
    } catch (e) {
      state = state.copyWith(
        status: ExploreStatus.error,
        errorMessage: e.toString(),
        featuredEvents: const [],
        featuredEvent: null,
        monthlyEvents: const [],
        upcomingEvents: const [],
        topSpeakers: const [],
      );
    }
  }

  /// Selects the 5 events from real backend data (or fallback if offline)
  List<EventItem> _pickCoolToAttendEvents({
    required List<EventItem> backendEvents,
    required DateTime now,
  }) {
    if (backendEvents.isNotEmpty) {
      // Prioritize future/ongoing events first, followed by others, preserving backend ordering
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
    loadExploreFeed();
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
    loadExploreFeed();
  }

  void resetFilters() {
    state = state.copyWith(
      selectedTimePeriod: 'All',
      selectedAdmission: 'All',
      isCfpOpenOnly: false,
      selectedCountry: 'All',
    );
    loadExploreFeed();
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
