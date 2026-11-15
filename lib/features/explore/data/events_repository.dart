import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/features/explore/data/events_remote_datasource.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

abstract class EventsRepository {
  Future<List<EventItem>> getEvents({
    String? search,
    String? country,
    String? region,
    String? timePeriod,
    bool? isFree,
    bool? cfpOpen,
    bool? isFeatured,
    int? page,
    int? limit,
  });
  Future<List<EventItem>> getFeaturedEvents();
  Future<EventItem?> getEventDetail(String idOrSlug);
  Future<List<EventSpeaker>> getTopSpeakers({
    bool top = true,
    String? ordering,
  });
  Future<List<EventSpeaker>> getSpeakers({
    bool? top,
    String? ordering,
    String? search,
    int? page,
    int? pageSize,
  });
  Future<List<EventItem>> getUpcomingEvents();
}

class DjangoEventsRepositoryImpl implements EventsRepository {
  final EventsRemoteDataSource remoteDataSource;

  DjangoEventsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<EventItem>> getEvents({
    String? search,
    String? country,
    String? region,
    String? timePeriod,
    bool? isFree,
    bool? cfpOpen,
    bool? isFeatured,
    int? page,
    int? limit,
  }) async {
    return await remoteDataSource.fetchEvents(
      search: search,
      country: country,
      region: region,
      timePeriod: timePeriod,
      isFree: isFree,
      cfpOpen: cfpOpen,
      isFeatured: isFeatured,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<EventItem>> getFeaturedEvents() async {
    try {
      return await remoteDataSource.fetchEvents(isFeatured: true);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<EventItem?> getEventDetail(String idOrSlug) async {
    return await remoteDataSource.fetchEventDetail(idOrSlug);
  }

  @override
  Future<List<EventSpeaker>> getTopSpeakers({
    bool top = true,
    String? ordering,
  }) async {
    return await remoteDataSource.fetchTopSpeakers(
      top: top,
      ordering: ordering,
    );
  }

  @override
  Future<List<EventSpeaker>> getSpeakers({
    bool? top,
    String? ordering,
    String? search,
    int? page,
    int? pageSize,
  }) async {
    return await remoteDataSource.fetchSpeakers(
      top: top,
      ordering: ordering,
      search: search,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<EventItem>> getUpcomingEvents() async {
    try {
      return await remoteDataSource.fetchEvents();
    } catch (_) {
      return [];
    }
  }
}

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final remote = ref.watch(eventsRemoteDataSourceProvider);
  return DjangoEventsRepositoryImpl(remoteDataSource: remote);
});
