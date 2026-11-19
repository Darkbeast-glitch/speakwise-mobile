/// ═══════════════════════════════════════════════════════════════
/// SpeakWise Event, Category, Speaker & Talk Models
/// ═══════════════════════════════════════════════════════════════
class EventCategory {
  final String id;
  final String name;
  final String imagePath;

  const EventCategory({
    required this.id,
    required this.name,
    required this.imagePath,
  });
}

class EventItem {
  final String id;
  final String title;
  final String location;
  final String date;
  final String imagePath;
  final String? dateBadgeMonth;
  final String? dateBadgeDay;
  final bool isTicketed;
  final String description;
  final String bannerSubtitle;
  final String categoryId;
  final String ticketPrice;
  final List<EventSpeaker> speakers;
  final String time;
  final String attendeeCount;
  final String subtitle;
  final String? slug;
  final String? country;
  final bool? isFree;
  final bool isFeatured;
  final bool cfpOpen;
  final String? cfpLink;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? website;

  const EventItem({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imagePath,
    this.dateBadgeMonth,
    this.dateBadgeDay,
    this.isTicketed = false,
    this.description =
        "Join the vibrant community for an immersive gathering of engineers, innovators, and leaders. Experience hands-on technical sessions, keynote presentations from world-class architects, and network with creators from across Africa and beyond.",
    this.bannerSubtitle = "Planning your next tech event? Add this to your calendar.",
    this.categoryId = 'africa',
    this.ticketPrice = '',
    this.speakers = const [],
    this.time = '08:00 AM',
    this.attendeeCount = '3k+',
    this.subtitle = '',
    this.slug,
    this.country,
    this.isFree,
    this.isFeatured = false,
    this.cfpOpen = false,
    this.cfpLink,
    this.startDateTime,
    this.endDateTime,
    this.website,
  });

  /// Location with country included (avoids duplicates if country is already in location)
  String get fullLocation {
    final loc = location.trim();
    final c = (country ?? '').trim();
    if (c.isEmpty) return loc;
    if (loc.isEmpty) return c;
    final locLower = loc.toLowerCase();
    final cLower = c.toLowerCase();
    if (locLower.contains(cLower) ||
        (cLower == 'uk' && (locLower.contains('united kingdom') || locLower.contains(', uk'))) ||
        (cLower == 'united kingdom' && (locLower.contains('uk') || locLower.contains('united kingdom'))) ||
        (cLower == 'usa' && (locLower.contains('united states') || locLower.contains(', usa') || locLower.contains(', us'))) ||
        (cLower == 'united states' && (locLower.contains('usa') || locLower.contains('united states')))) {
      return loc;
    }
    return '$loc, $c';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date,
      'imagePath': imagePath,
      'dateBadgeMonth': dateBadgeMonth,
      'dateBadgeDay': dateBadgeDay,
      'isTicketed': isTicketed,
      'description': description,
      'bannerSubtitle': bannerSubtitle,
      'categoryId': categoryId,
      'ticketPrice': ticketPrice,
      'speakers': speakers.map((s) => s.toJson()).toList(),
      'time': time,
      'attendeeCount': attendeeCount,
      'subtitle': subtitle,
      'slug': slug,
      'country': country,
      'isFree': isFree,
      'isFeatured': isFeatured,
      'cfpOpen': cfpOpen,
      'cfpLink': cfpLink,
      'startDateTime': startDateTime?.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'website': website,
    };
  }

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      dateBadgeMonth: json['dateBadgeMonth']?.toString(),
      dateBadgeDay: json['dateBadgeDay']?.toString(),
      isTicketed: json['isTicketed'] == true,
      description: json['description']?.toString() ?? '',
      bannerSubtitle: json['bannerSubtitle']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? 'all',
      ticketPrice: json['ticketPrice']?.toString() ?? '',
      speakers: (json['speakers'] as List?)
              ?.map((s) => EventSpeaker.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      time: json['time']?.toString() ?? '',
      attendeeCount: json['attendeeCount']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      slug: json['slug']?.toString(),
      country: json['country']?.toString(),
      isFree: json['isFree'] as bool?,
      isFeatured: json['isFeatured'] == true,
      cfpOpen: json['cfpOpen'] == true,
      cfpLink: json['cfpLink']?.toString() ??
          json['cfp_link']?.toString() ??
          json['cfp_url']?.toString(),
      startDateTime: json['startDateTime'] != null
          ? DateTime.tryParse(json['startDateTime'].toString())
          : null,
      endDateTime: json['endDateTime'] != null
          ? DateTime.tryParse(json['endDateTime'].toString())
          : null,
      website: json['website']?.toString(),
    );
  }
}

class EventSpeaker {
  final String id;
  final String name;
  final String role;
  final String avatarPath;
  final double rating;
  final int talksGiven;
  final String badge;
  final String topic;
  final double? reputationScore;
  final int? totalReviews;
  final String? rankTier;
  final String? username;
  final String? slug;
  final int badgesCount;

  const EventSpeaker({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarPath,
    this.rating = 4.9,
    this.talksGiven = 12,
    this.badge = 'Top Speaker',
    this.topic = '',
    this.reputationScore,
    this.totalReviews,
    this.rankTier,
    this.username,
    this.slug,
    this.badgesCount = 5,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'avatarPath': avatarPath,
      'rating': rating,
      'talksGiven': talksGiven,
      'badge': badge,
      'topic': topic,
      'reputationScore': reputationScore,
      'totalReviews': totalReviews,
      'rankTier': rankTier,
      'username': username,
      'slug': slug,
      'badgesCount': badgesCount,
    };
  }

  factory EventSpeaker.fromJson(Map<String, dynamic> json) {
    return EventSpeaker(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      avatarPath: json['avatarPath']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      talksGiven: (json['talksGiven'] as num?)?.toInt() ?? 0,
      badge: json['badge']?.toString() ?? 'Top Speaker',
      topic: json['topic']?.toString() ?? '',
      reputationScore: (json['reputationScore'] as num?)?.toDouble(),
      totalReviews: (json['totalReviews'] as num?)?.toInt(),
      rankTier: json['rankTier']?.toString(),
      username: json['username']?.toString(),
      slug: json['slug']?.toString(),
      badgesCount: (json['badgesCount'] as num?)?.toInt() ?? 5,
    );
  }
}

class TrendingSession {
  final String id;
  final String title;
  final String speakerName;
  final String speakerAvatar;
  final String time;
  final String eventTitle;
  final double rating;
  final List<String> tags;

  const TrendingSession({
    required this.id,
    required this.title,
    required this.speakerName,
    required this.speakerAvatar,
    required this.time,
    required this.eventTitle,
    this.rating = 4.95,
    this.tags = const [],
  });
}
