import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/services/api_client.dart';
import 'package:speakwise_mobile/features/explore/data/events_data.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

const _africanCountries = [
  'ghana', 'nigeria', 'kenya', 'south africa', 'egypt', 'rwanda', 'uganda',
  'angola', 'namibia', 'ethiopia', 'morocco', 'senegal', 'tanzania', 'cameroon', 'africa'
];
const _europeanCountries = [
  'united kingdom', 'uk', 'germany', 'france', 'portugal', 'spain', 'italy',
  'netherlands', 'poland', 'ireland', 'sweden', 'switzerland', 'norway', 'europe'
];
const _americanCountries = [
  'united states', 'usa', 'us', 'canada', 'brazil', 'mexico', 'argentina', 'america'
];
const _asianCountries = [
  'india', 'japan', 'singapore', 'china', 'uae', 'united arab emirates', 'asia'
];

abstract class EventsRemoteDataSource {
  Future<List<EventItem>> fetchEvents({
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
  Future<EventItem?> fetchEventDetail(String idOrSlug);
  Future<List<EventSpeaker>> fetchTopSpeakers({
    bool top = true,
    String? ordering,
  });
  Future<List<EventSpeaker>> fetchSpeakers({
    bool? top,
    String? ordering,
    String? search,
    int? page,
    int? pageSize,
  });
}

class DjangoEventsRemoteDataSource implements EventsRemoteDataSource {
  final ApiClient apiClient;

  DjangoEventsRemoteDataSource({required this.apiClient});

  @override
  Future<List<EventItem>> fetchEvents({
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
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (country != null && country.isNotEmpty && country.toLowerCase() != 'all') {
      queryParams['country'] = country;
    }
    if (region != null && region.isNotEmpty && region.toLowerCase() != 'all') {
      queryParams['region'] = region;
    }
    if (timePeriod != null && timePeriod.isNotEmpty && timePeriod.toLowerCase() != 'all') {
      queryParams['time_period'] = timePeriod;
    }
    if (isFree != null) {
      queryParams['is_free'] = isFree;
    }
    if (cfpOpen != null) {
      queryParams['cfp_open'] = cfpOpen;
    }
    if (isFeatured != null) {
      queryParams['is_featured'] = isFeatured;
    }
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;

    try {
      final response = await apiClient.get(
        '/events/',
        queryParameters: queryParams,
        authenticated: false,
      );

      if (response is Map && response['results'] is List) {
        final list = response['results'] as List;
        return list.map((item) => _mapJsonToEventItem(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }

  @override
  Future<EventItem?> fetchEventDetail(String idOrSlug) async {
    try {
      final response = await apiClient.get(
        '/events/$idOrSlug/',
        authenticated: false,
      );

      if (response is Map<String, dynamic>) {
        return _mapJsonToEventItem(response);
      }
    } catch (_) {}

    return null;
  }

  EventItem _mapJsonToEventItem(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? 'evt-unknown';
    final slug = json['slug']?.toString() ?? id;
    final title = json['title']?.toString() ?? 'Conference Event';
    final location = json['location']?.toString() ?? 'Accra, Ghana';
    final country = json['country']?.toString() ?? '';
    final rawImage = (json['event_image'] ?? '').toString().trim();
    final isFree = json['is_free'] == true;
    final isFeatured = json['is_featured'] == true;
    final cfpOpen = json['cfp_open'] == true || json['is_cfp_currently_open'] == true;
    final cfpLink = json['cfp_link']?.toString() ?? json['cfp_url']?.toString();
    final description = json['description']?.toString() ?? '';
    final website = json['website']?.toString();

    // Date formatting helper
    DateTime? startDt;
    DateTime? endDt;
    String? dayStr;
    String? monthStr;

    if (json['start_date_time'] != null) {
      try {
        startDt = DateTime.parse(json['start_date_time'].toString());
        dayStr = startDt.day.toString();
        monthStr = _monthName(startDt.month);
      } catch (_) {}
    }
    if (json['end_date_time'] != null) {
      try {
        endDt = DateTime.parse(json['end_date_time'].toString());
      } catch (_) {}
    }
    if (startDt == null && json['date_range'] is Map) {
      final dr = json['date_range'] as Map;
      if (dr['start'] != null) {
        try {
          startDt = DateTime.parse(dr['start'].toString());
          dayStr = startDt.day.toString();
          monthStr = _monthName(startDt.month);
        } catch (_) {}
      }
      if (dr['end'] != null) {
        try {
          endDt = DateTime.parse(dr['end'].toString());
        } catch (_) {}
      }
    }
    if (startDt == null && json['date'] != null) {
      final dStr = json['date'].toString();
      if (dStr.contains(' to ')) {
        final parts = dStr.split(' to ');
        try {
          startDt = DateTime.parse(parts[0].trim());
          dayStr = startDt.day.toString();
          monthStr = _monthName(startDt.month);
        } catch (_) {}
        if (parts.length > 1) {
          try {
            endDt = DateTime.parse(parts[1].trim());
          } catch (_) {}
        }
      } else {
        try {
          startDt = DateTime.parse(dStr.trim());
          dayStr = startDt.day.toString();
          monthStr = _monthName(startDt.month);
        } catch (_) {}
      }
    }

    final rawDateStr = json['date']?.toString();
    final dateStr = _formatFullDateRange(startDt, endDt, rawDateStr);

    final subtitle = json['subtitle']?.toString() ?? json['topic']?.toString() ?? 'Featured Track';
    final timeStr = json['start_time']?.toString() ?? '08:00 AM';
    final attendeeStr = json['attendee_count']?.toString() ?? '3k+';

    // Determine category / region
    final combinedLocation = '$country $location'.toLowerCase();
    String categoryId = 'all';
    if (_africanCountries.any((c) => combinedLocation.contains(c))) {
      categoryId = 'africa';
    } else if (_europeanCountries.any((c) => combinedLocation.contains(c))) {
      categoryId = 'europe';
    } else if (_americanCountries.any((c) => combinedLocation.contains(c))) {
      categoryId = 'america';
    } else if (_asianCountries.any((c) => combinedLocation.contains(c))) {
      categoryId = 'asia';
    }

    String formattedImage = '';
    if (rawImage.isNotEmpty) {
      if (rawImage.startsWith('http://') || rawImage.startsWith('https://')) {
        formattedImage = rawImage;
        try {
          final baseUri = Uri.parse(apiClient.baseUrl);
          final baseHost = baseUri.host;
          final basePort = baseUri.hasPort ? ':${baseUri.port}' : '';
          final baseOrigin = '${baseUri.scheme}://$baseHost$basePort';
          if (formattedImage.contains('127.0.0.1') || formattedImage.contains('localhost')) {
            formattedImage = formattedImage
                .replaceAll(RegExp(r'https?://127\.0\.0\.1(:\d+)?'), baseOrigin)
                .replaceAll(RegExp(r'https?://localhost(:\d+)?'), baseOrigin);
          }
        } catch (_) {}
      } else if (rawImage.startsWith('/')) {
        try {
          final baseUri = Uri.parse(apiClient.baseUrl);
          final baseOrigin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
          formattedImage = '$baseOrigin$rawImage';
        } catch (_) {
          formattedImage = rawImage;
        }
      } else if (rawImage.startsWith('assets/')) {
        formattedImage = rawImage;
      } else {
        try {
          final baseUri = Uri.parse(apiClient.baseUrl);
          final baseOrigin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
          formattedImage = '$baseOrigin/media/$rawImage';
        } catch (_) {
          formattedImage = rawImage;
        }
      }
    }

    // Regional fallback when no image was uploaded to the backend
    if (formattedImage.isEmpty) {
      if (categoryId == 'europe') {
        formattedImage = 'assets/images/cat_europe.jpg';
      } else if (categoryId == 'asia') {
        formattedImage = 'assets/images/cat_asia.jpg';
      } else if (categoryId == 'america') {
        formattedImage = 'assets/images/cat_america.jpg';
      } else {
        formattedImage = 'assets/images/cortex_summit.jpg';
      }
    }

    return EventItem(
      id: id,
      slug: slug,
      title: title,
      subtitle: subtitle,
      time: timeStr,
      attendeeCount: attendeeStr,
      date: dateStr,
      dateBadgeDay: dayStr ?? '15',
      dateBadgeMonth: monthStr ?? 'Nov',
      location: location,
      country: country.isNotEmpty ? country : 'Ghana',
      imagePath: formattedImage,
      isTicketed: !isFree,
      isFree: isFree,
      isFeatured: isFeatured,
      cfpOpen: cfpOpen,
      cfpLink: cfpLink,
      startDateTime: startDt,
      endDateTime: endDt,
      website: website,
      bannerSubtitle: 'Annual flagship gathering of software engineers and founders',
      description: description.isNotEmpty
          ? description
          : 'SpeakWise brings together keynote speakers, engineering leads, and technology leaders across the continent for hands-on technical talks, workshops, and verified audience engagement.',
      categoryId: categoryId,
      speakers: EventsData.topSpeakers,
    );
  }

  @override
  Future<List<EventSpeaker>> fetchTopSpeakers({
    bool top = true,
    String? ordering,
  }) async {
    return await fetchSpeakers(top: top, ordering: ordering);
  }

  @override
  Future<List<EventSpeaker>> fetchSpeakers({
    bool? top,
    String? ordering,
    String? search,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (top == true) {
        queryParams['top'] = 'true';
      }
      if (ordering != null && ordering.isNotEmpty) {
        queryParams['ordering'] = ordering;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (page != null) {
        queryParams['page'] = page;
      }
      if (pageSize != null) {
        queryParams['page_size'] = pageSize;
      }

      final response = await apiClient.get(
        '/speakers/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        authenticated: false,
      );

      List list = [];
      if (response is Map && response['results'] is List) {
        list = response['results'] as List;
      } else if (response is List) {
        list = response;
      }

      final mapped = list.map((item) {
        final json = item as Map<String, dynamic>;
        final id = json['id']?.toString() ?? '';
        final name = json['speaker_name']?.toString() ?? json['name']?.toString() ?? 'Speaker';
        final slug = json['slug']?.toString() ?? json['username']?.toString() ?? 'speaker';
        final username = json['username']?.toString() ?? slug;
        final role = json['organization']?.toString() ?? json['headline']?.toString() ?? '';
        var avatar = json['avatar']?.toString() ?? '';
        if (avatar.contains('127.0.0.1:8000') || avatar.contains('localhost:8000')) {
          final host = Uri.parse(apiClient.baseUrl).host;
          avatar = avatar.replaceAll('127.0.0.1', host).replaceAll('localhost', host);
        }
        final totalTalks = json['total_talks'] is num
            ? (json['total_talks'] as num).toInt()
            : (json['events_spoken'] is List ? (json['events_spoken'] as List).length : 0);
        final totalReviews = json['total_reviews'] is num ? (json['total_reviews'] as num).toInt() : 0;
        final averageRating = json['average_rating'] is num ? (json['average_rating'] as num).toDouble() : null;
        final reputationScore = json['reputation_score'] is num ? (json['reputation_score'] as num).toDouble() : null;
        final rankTier = json['rank_tier']?.toString();
        final badgesCount = json['badges_count'] is num
            ? (json['badges_count'] as num).toInt()
            : (json['badges'] is List ? (json['badges'] as List).length : 0);

        return EventSpeaker(
          id: slug.isNotEmpty ? slug : id,
          name: name,
          role: role,
          avatarPath: avatar,
          rating: reputationScore ?? averageRating ?? 0.0,
          talksGiven: totalTalks,
          badge: rankTier ?? 'Top Speaker',
          topic: json['short_bio']?.toString() ?? '',
          reputationScore: reputationScore,
          totalReviews: totalReviews,
          rankTier: rankTier,
          username: username,
          slug: slug,
          badgesCount: badgesCount,
        );
      }).toList();
      if (mapped.isNotEmpty) return mapped;
    } catch (_) {}
    return [];
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  String _fullMonthName(int month) {
    const fullMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) return fullMonths[month - 1];
    return '';
  }

  String _formatFullDateRange(DateTime? start, DateTime? end, String? rawDate) {
    if (start == null && end == null) {
      return (rawDate != null && rawDate.isNotEmpty) ? rawDate : 'Upcoming';
    }
    if (start != null && end == null) {
      return '${_ordinal(start.day)} ${_fullMonthName(start.month)} ${start.year}';
    }
    if (start != null && end != null) {
      final startMonth = _fullMonthName(start.month);
      final endMonth = _fullMonthName(end.month);
      if (start.year == end.year) {
        if (start.month == end.month) {
          if (start.day == end.day) {
            return '${_ordinal(start.day)} $startMonth ${start.year}';
          }
          return '${_ordinal(start.day)} $startMonth - ${_ordinal(end.day)} $startMonth ${start.year}';
        } else {
          return '${_ordinal(start.day)} $startMonth - ${_ordinal(end.day)} $endMonth ${start.year}';
        }
      } else {
        return '${_ordinal(start.day)} $startMonth ${start.year} - ${_ordinal(end.day)} $endMonth ${end.year}';
      }
    }
    return (rawDate != null && rawDate.isNotEmpty) ? rawDate : 'Upcoming';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}

final eventsRemoteDataSourceProvider = Provider<EventsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DjangoEventsRemoteDataSource(apiClient: apiClient);
});
