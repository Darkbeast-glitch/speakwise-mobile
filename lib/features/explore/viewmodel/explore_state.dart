import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

enum ExploreStatus { initial, loading, success, error }

class ExploreState {
  final ExploreStatus status;
  final String selectedCategoryId;
  final EventItem? featuredEvent;
  final List<EventItem> featuredEvents;
  final List<EventItem> monthlyEvents;
  final String monthlySectionTitle;
  final List<EventItem> upcomingEvents;
  final List<EventSpeaker> topSpeakers;
  final List<EventItem> allEvents;
  final String? errorMessage;
  final String searchQuery;
  final List<EventItem> searchResults;
  final bool isSearching;
  final String selectedTimePeriod;
  final String selectedAdmission;
  final bool isCfpOpenOnly;
  final String selectedCountry;
  final List<String> availableCountries;

  const ExploreState({
    this.status = ExploreStatus.initial,
    this.selectedCategoryId = 'all',
    this.featuredEvent,
    this.featuredEvents = const [],
    this.monthlyEvents = const [],
    this.monthlySectionTitle = 'Happening This Month',
    this.upcomingEvents = const [],
    this.topSpeakers = const [],
    this.allEvents = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.searchResults = const [],
    this.isSearching = false,
    this.selectedTimePeriod = 'All',
    this.selectedAdmission = 'All',
    this.isCfpOpenOnly = false,
    this.selectedCountry = 'All',
    this.availableCountries = const [],
  });

  ExploreState copyWith({
    ExploreStatus? status,
    String? selectedCategoryId,
    EventItem? featuredEvent,
    List<EventItem>? featuredEvents,
    List<EventItem>? monthlyEvents,
    String? monthlySectionTitle,
    List<EventItem>? upcomingEvents,
    List<EventSpeaker>? topSpeakers,
    List<EventItem>? allEvents,
    String? errorMessage,
    String? searchQuery,
    List<EventItem>? searchResults,
    bool? isSearching,
    String? selectedTimePeriod,
    String? selectedAdmission,
    bool? isCfpOpenOnly,
    String? selectedCountry,
    List<String>? availableCountries,
  }) {
    final newFeaturedEvents = featuredEvents ?? this.featuredEvents;
    final newFeatured = featuredEvent ??
        (featuredEvents != null && featuredEvents.isNotEmpty ? featuredEvents.first : this.featuredEvent);

    return ExploreState(
      status: status ?? this.status,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      featuredEvent: newFeatured,
      featuredEvents: newFeaturedEvents,
      monthlyEvents: monthlyEvents ?? this.monthlyEvents,
      monthlySectionTitle: monthlySectionTitle ?? this.monthlySectionTitle,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      topSpeakers: topSpeakers ?? this.topSpeakers,
      allEvents: allEvents ?? this.allEvents,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      selectedTimePeriod: selectedTimePeriod ?? this.selectedTimePeriod,
      selectedAdmission: selectedAdmission ?? this.selectedAdmission,
      isCfpOpenOnly: isCfpOpenOnly ?? this.isCfpOpenOnly,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      availableCountries: availableCountries ?? this.availableCountries,
    );
  }
}
